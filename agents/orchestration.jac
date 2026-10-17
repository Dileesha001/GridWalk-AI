"""Bounded recovery coordination and factual run result projection."""

import from time { perf_counter }
import from uuid { uuid4 }
import from agents.auditor { audit_incident, factual_incident_summary }
import from agents.events { record_agent_run }
import from agents.monitor { MonitorFacts, inspect_grid }
import from agents.planner { propose_plan, propose_backup_plan, REQUEST_TIMEOUT_SECONDS }
import from jaclang.byllm.lib { ByLLMError }
import from grid.fallback { deterministic_fallback_plan }
import from grid.graph { Grid }
import from grid.simulation { get_grid_state, inject_fault, apply_approved_plan }
import from grid.validation { validate_plan }
import from shared.contracts {
    AgentActor, AgentEvent, AgentEventKind, AgentEventOutcome,
    ExecutionMode, GraphState, RecoveryAction, RecoveryActionType, RecoveryOutcome, RecoveryPlan,
    RecoveryResult, ValidationResult
}

glob MAX_PLAN_PROPOSALS: int = 2;
glob MAX_RECOVERY_SECONDS: float = 65.0;

enum TriageStatus: str {
    APPLIED = "applied",
    ALREADY_APPLIED = "already_applied",
    EXHAUSTED = "exhausted",
    STALE = "stale",
    PROVIDER_FAILED = "provider_failed",
    FALLBACK_FAILED = "fallback_failed",
    BUDGET_EXHAUSTED = "budget_exhausted"
}

obj TriageAttempt {
    has plan: RecoveryPlan;
    has validation: ValidationResult | None;
    has rejection_reasons: list[str];
}

obj TriageResult {
    has fault_id: str;
    has status: TriageStatus;
    has before_state: GraphState;
    has after_state: GraphState;
    has proposal_count: int;
    has rejection_reasons: list[str];
    has attempts: list[TriageAttempt];
    has last_plan: RecoveryPlan | None = None;
    has last_validation: ValidationResult | None = None;
    has failure_reason: str | None = None;
    has run_id: str = "";
    has recovery_result: RecoveryResult | None = None;
    has attempt_modes: list[ExecutionMode] = [];
    has backup_after_attempt: int | None = None;
    has backup_reason: str | None = None;
    has deterministic_after_attempt: int | None = None;
    has deterministic_reason: str | None = None;
}

def _result(fault_id: str, status: TriageStatus, before_state: GraphState,
            proposal_count: int, rejection_reasons: list[str],
            last_plan: RecoveryPlan | None = None,
            last_validation: ValidationResult | None = None,
            failure_reason: str | None = None,
            after_state: GraphState | None = None,
            attempts: list[TriageAttempt] | None = None) -> TriageResult {
    return TriageResult(
        fault_id=fault_id, status=status, before_state=before_state,
        after_state=after_state if after_state is not None else get_grid_state(),
        proposal_count=proposal_count, rejection_reasons=rejection_reasons.copy(),
        attempts=attempts.copy() if attempts is not None else [],
        last_plan=last_plan, last_validation=last_validation,
        failure_reason=failure_reason
    );
}

def _same_snapshot(observed: GraphState) -> bool {
    current = get_grid_state();
    return (
        current.generation_id == observed.generation_id and
        current.revision == observed.revision and
        current.active_fault_ids == observed.active_fault_ids
    );
}

def _already_applied(observed: GraphState, fault_id: str) -> bool {
    for grid in [root -->[?:Grid]] {
        if (
            grid.active_fault_id == fault_id and
            grid.generation_id == observed.generation_id and
            grid.revision == observed.revision and
            grid.allocation_committed
        ) {
            return True;
        }
    }
    return False;
}

def _revision_feedback(plan: RecoveryPlan, reasons: list[str]) -> str {
    actions: list[str] = [];
    for action in plan.actions {
        actions.append(f"{action.action_type}({action.target_id})");
    }
    return (
        "Deterministic validation rejected the previous proposal: " +
        "; ".join(reasons) + ". Previous actions: " +
        (", ".join(actions) if len(actions) > 0 else "none") + "."
    );
}

def _run_triage_with_planner(
    fault_id: str,
    planner: Callable[[MonitorFacts, str], RecoveryPlan],
    deadline: float | None = None,
    before_state: GraphState | None = None
) -> TriageResult {
    before = before_state if before_state is not None else inject_fault(fault_id);
    if before_state is not None and not _same_snapshot(before_state) {
        return _result(fault_id, TriageStatus.STALE, before, 0,
                       ["Grid changed before backup planning began"]);
    }
    if _already_applied(before, fault_id) {
        return _result(fault_id, TriageStatus.ALREADY_APPLIED, before, 0, []);
    }

    facts: MonitorFacts = inspect_grid();
    if not _same_snapshot(facts.graph_state) or facts.graph_state.active_fault_ids != [fault_id] {
        return _result(fault_id, TriageStatus.STALE, before, 0,
                       ["Grid changed before planning began"]);
    }

    feedback = "";
    reasons: list[str] = [];
    last_plan: RecoveryPlan | None = None;
    last_validation: ValidationResult | None = None;
    proposal_count = 0;
    attempts: list[TriageAttempt] = [];

    for _attempt in range(MAX_PLAN_PROPOSALS) {
        if not _same_snapshot(facts.graph_state) {
            return _result(fault_id, TriageStatus.STALE, before, proposal_count,
                           ["Grid changed during planning"], last_plan, last_validation,
                           attempts=attempts);
        }
        if deadline is not None and perf_counter() + REQUEST_TIMEOUT_SECONDS > deadline {
            return _result(fault_id, TriageStatus.BUDGET_EXHAUSTED, before,
                           proposal_count, reasons, last_plan, last_validation,
                           "Recovery deadline left no time for another provider request",
                           attempts=attempts);
        }
        try {
            plan = planner(facts, feedback);
        } except ByLLMError {
            return _result(fault_id, TriageStatus.PROVIDER_FAILED, before, proposal_count,
                           reasons, last_plan, last_validation,
                           "Planner provider failed before a valid proposal was available",
                           attempts=attempts);
        } except ValueError {
            return _result(fault_id, TriageStatus.PROVIDER_FAILED, before, proposal_count,
                           reasons, last_plan, last_validation,
                           "Planner returned a malformed proposal", attempts=attempts);
        } except TimeoutError {
            return _result(fault_id, TriageStatus.PROVIDER_FAILED, before, proposal_count,
                           reasons, last_plan, last_validation,
                           "Planner request timed out", attempts=attempts);
        } except Exception {
            return _result(fault_id, TriageStatus.PROVIDER_FAILED, before, proposal_count,
                           reasons, last_plan, last_validation,
                           "Planner request failed before a valid proposal was available",
                           attempts=attempts);
        }
        proposal_count += 1;
        last_plan = plan;

        if deadline is not None and perf_counter() >= deadline {
            reasons = ["Recovery deadline expired before validation"];
            attempts.append(TriageAttempt(
                plan=plan, validation=None, rejection_reasons=reasons.copy()
            ));
            return _result(fault_id, TriageStatus.BUDGET_EXHAUSTED, before,
                           proposal_count, reasons, plan, last_validation,
                           "Recovery deadline expired before validation", attempts=attempts);
        }

        if len(plan.actions) == 0 {
            reasons = ["Planner proposed no supported recovery action"];
            attempts.append(TriageAttempt(
                plan=plan, validation=None, rejection_reasons=reasons.copy()
            ));
            feedback = _revision_feedback(plan, reasons);
            continue;
        }

        validation = validate_plan(plan);
        last_validation = validation;
        if not _same_snapshot(facts.graph_state) or validation.checked_generation_id != facts.graph_state.generation_id or validation.checked_revision != facts.graph_state.revision {
            attempts.append(TriageAttempt(
                plan=plan, validation=validation,
                rejection_reasons=["Grid changed before application"]
            ));
            return _result(fault_id, TriageStatus.STALE, before, proposal_count,
                           ["Grid changed before application"], plan, validation,
                           attempts=attempts);
        }

        if validation.accepted {
            if validation.candidate is None {
                attempts.append(TriageAttempt(
                    plan=plan, validation=validation,
                    rejection_reasons=["Validator accepted without a candidate allocation"]
                ));
                return _result(fault_id, TriageStatus.EXHAUSTED, before, proposal_count,
                               ["Validator accepted without a candidate allocation"],
                               plan, validation, attempts=attempts);
            }
            if deadline is not None and perf_counter() >= deadline {
                attempts.append(TriageAttempt(
                    plan=plan, validation=validation,
                    rejection_reasons=["Recovery deadline expired before application"]
                ));
                return _result(fault_id, TriageStatus.BUDGET_EXHAUSTED, before,
                               proposal_count, ["Recovery deadline expired before application"],
                               plan, validation, "Recovery deadline expired before application",
                               attempts=attempts);
            }
            try {
                applied = apply_approved_plan(plan);
                attempts.append(TriageAttempt(
                    plan=plan, validation=validation, rejection_reasons=[]
                ));
                return _result(fault_id, TriageStatus.APPLIED, before, proposal_count,
                               reasons, plan, validation, after_state=applied,
                               attempts=attempts);
            } except ValueError as error {
                failed_reasons = [str(error)];
                attempts.append(TriageAttempt(
                    plan=plan, validation=validation,
                    rejection_reasons=failed_reasons.copy()
                ));
                status = TriageStatus.STALE if not _same_snapshot(facts.graph_state) else TriageStatus.EXHAUSTED;
                return _result(fault_id, status, before, proposal_count,
                               failed_reasons, plan, validation, attempts=attempts);
            }
        }

        reasons = validation.reasons.copy();
        if len(reasons) == 0 {
            reasons = ["Validator rejected the proposal without a reason"];
        }
        attempts.append(TriageAttempt(
            plan=plan, validation=validation, rejection_reasons=reasons.copy()
        ));
        feedback = _revision_feedback(plan, reasons);
    }

    return _result(fault_id, TriageStatus.EXHAUSTED, before, proposal_count,
                   reasons, last_plan, last_validation, attempts=attempts);
}


def _combine_provider_runs(primary: TriageResult, backup: TriageResult) -> TriageResult {
    combined = _result(
        primary.fault_id, backup.status, primary.before_state,
        primary.proposal_count + backup.proposal_count,
        primary.rejection_reasons + backup.rejection_reasons,
        backup.last_plan if backup.last_plan is not None else primary.last_plan,
        backup.last_validation if backup.last_validation is not None else primary.last_validation,
        backup.failure_reason, backup.after_state,
        primary.attempts + backup.attempts
    );
    combined.attempt_modes = (
        [ExecutionMode.PRIMARY_AI for _ in primary.attempts] +
        [ExecutionMode.BACKUP_AI for _ in backup.attempts]
    );
    combined.backup_after_attempt = len(primary.attempts);
    combined.backup_reason = (
        "Primary provider failed or returned malformed output"
        if primary.status == TriageStatus.PROVIDER_FAILED
        else "Primary proposals were rejected or exhausted"
    );
    return combined;
}


def _run_deterministic_fallback(before: GraphState, deadline: float) -> TriageResult {
    fault_id = before.active_fault_ids[0];
    if not _same_snapshot(before) {
        return _result(fault_id, TriageStatus.STALE, before, 0,
                       ["Grid changed before deterministic planning began"]);
    }
    if perf_counter() >= deadline {
        return _result(fault_id, TriageStatus.BUDGET_EXHAUSTED, before, 0, [],
                       failure_reason="Recovery deadline expired before deterministic planning");
    }
    try {
        plan = deterministic_fallback_plan(before);
    } except Exception {
        return _result(fault_id, TriageStatus.FALLBACK_FAILED, before, 0, [],
                       failure_reason="Deterministic candidate generation failed");
    }
    if not _same_snapshot(before) {
        return _result(fault_id, TriageStatus.STALE, before, 0,
                       ["Grid changed during deterministic planning"]);
    }
    if perf_counter() >= deadline {
        return _result(fault_id, TriageStatus.BUDGET_EXHAUSTED, before, 0, [],
                       failure_reason="Recovery deadline expired before deterministic validation");
    }
    if plan is None {
        return _result(fault_id, TriageStatus.EXHAUSTED, before, 0,
                       ["No feasible deterministic candidate for the current fault"]);
    }
    validation = validate_plan(plan);
    if (
        not _same_snapshot(before) or
        validation.checked_generation_id != before.generation_id or
        validation.checked_revision != before.revision
    ) {
        return _result(fault_id, TriageStatus.STALE, before, 1,
                       ["Grid changed before deterministic application"], plan,
                       validation, attempts=[TriageAttempt(
                           plan=plan, validation=validation,
                           rejection_reasons=["Grid changed before deterministic application"]
                       )]);
    }
    if not validation.accepted or validation.candidate is None {
        reasons = validation.reasons.copy() if len(validation.reasons) > 0 else [
            "Deterministic candidate was not accepted by the validator"
        ];
        return _result(fault_id, TriageStatus.EXHAUSTED, before, 1,
                       reasons, plan, validation, attempts=[TriageAttempt(
                           plan=plan, validation=validation, rejection_reasons=reasons.copy()
                       )]);
    }
    if perf_counter() >= deadline {
        return _result(fault_id, TriageStatus.BUDGET_EXHAUSTED, before, 1,
                       ["Recovery deadline expired before deterministic application"],
                       plan, validation,
                       "Recovery deadline expired before deterministic application",
                       attempts=[TriageAttempt(
                           plan=plan, validation=validation,
                           rejection_reasons=["Recovery deadline expired before deterministic application"]
                       )]);
    }
    try {
        applied = apply_approved_plan(plan);
    } except ValueError {
        status = TriageStatus.STALE if not _same_snapshot(before) else TriageStatus.EXHAUSTED;
        reasons = ["Deterministic candidate could not be applied to the current grid"];
        return _result(fault_id, status, before, 1, reasons, plan, validation,
                       attempts=[TriageAttempt(
                           plan=plan, validation=validation, rejection_reasons=reasons.copy()
                       )]);
    }
    return _result(fault_id, TriageStatus.APPLIED, before, 1, [], plan,
                   validation, after_state=applied,
                   attempts=[TriageAttempt(
                       plan=plan, validation=validation, rejection_reasons=[]
                   )]);
}


def _combine_deterministic_run(previous: TriageResult, fallback: TriageResult) -> TriageResult {
    combined = _result(
        previous.fault_id, fallback.status, previous.before_state,
        previous.proposal_count + fallback.proposal_count,
        previous.rejection_reasons + fallback.rejection_reasons,
        fallback.last_plan if fallback.last_plan is not None else previous.last_plan,
        fallback.last_validation if fallback.last_validation is not None else previous.last_validation,
        fallback.failure_reason, fallback.after_state,
        previous.attempts + fallback.attempts
    );
    combined.attempt_modes = previous.attempt_modes + [
        ExecutionMode.DETERMINISTIC for _ in fallback.attempts
    ];
    combined.backup_after_attempt = previous.backup_after_attempt;
    combined.backup_reason = previous.backup_reason;
    if not (
        fallback.status == TriageStatus.BUDGET_EXHAUSTED and
        fallback.failure_reason == "Recovery deadline expired before deterministic planning"
    ) {
        combined.deterministic_after_attempt = len(previous.attempts);
        combined.deterministic_reason = "AI planning did not apply a recovery plan";
    }
    return combined;
}


def _action_labels(actions: list[RecoveryAction]) -> str {
    labels: list[str] = [];
    for action in actions {
        labels.append(f"{action.action_type} {action.target_id}");
    }
    return ", ".join(labels) if len(labels) > 0 else "none";
}


def _committed_actions(
    plan: RecoveryPlan, before: GraphState, after: GraphState
) -> list[RecoveryAction] {
    committed: list[RecoveryAction] = [];
    for action in plan.actions {
        if action.action_type == RecoveryActionType.CLOSE_SWITCH {
            for line in after.lines {
                if line.switch_id == action.target_id and line.switch_closed {
                    for prior in before.lines {
                        if prior.switch_id == action.target_id and not prior.switch_closed {
                            committed.append(action);
                        }
                    }
                }
            }
        } elif action.action_type == RecoveryActionType.SHED_LOAD {
            for load in after.loads {
                if load.bus_id == action.target_id and load.deliberately_shed {
                    for prior in before.loads {
                        if prior.bus_id == action.target_id and not prior.deliberately_shed {
                            committed.append(action);
                        }
                    }
                }
            }
        }
    }
    return committed;
}


def _append_event(
    events: list[AgentEvent], run_id: str, actor: AgentActor,
    kind: AgentEventKind, outcome: AgentEventOutcome,
    summary: str, evidence: str = ""
) {
    events.append(AgentEvent(
        run_id=run_id, sequence=len(events) + 1, actor=actor,
        kind=kind, outcome=outcome, summary=summary, evidence=evidence
    ));
}


def _classify_outcome(triage: TriageResult) -> RecoveryOutcome {
    if triage.status == TriageStatus.ALREADY_APPLIED {
        return RecoveryOutcome.NO_ACTION;
    }
    critical = triage.after_state.metrics.critical_preserved_pct;
    if triage.status == TriageStatus.APPLIED {
        if critical is not None and critical < 99.999999 {
            return RecoveryOutcome.INFEASIBLE;
        }
        if triage.after_state.metrics.unmet_kw <= 0.000001 {
            return RecoveryOutcome.RECOVERED;
        }
        return RecoveryOutcome.PARTIAL;
    }
    if triage.status == TriageStatus.EXHAUSTED and critical is not None and critical < 99.999999 {
        return RecoveryOutcome.INFEASIBLE;
    }
    return RecoveryOutcome.FAILED;
}


def _finalize_triage(
    triage: TriageResult, run_id: str, started: float,
    proposed_mode: ExecutionMode,
    auditor: Callable[[str, GraphState, GraphState, list[RecoveryAction], ValidationResult], str] = audit_incident
) -> TriageResult {
    applied_actions: list[RecoveryAction] = [];
    mode: ExecutionMode = ExecutionMode.NONE;
    audit_fallback = False;
    if triage.status == TriageStatus.APPLIED and triage.last_plan is not None {
        applied_actions = _committed_actions(
            triage.last_plan, triage.before_state, triage.after_state
        );
        mode = proposed_mode;
    }

    if triage.status == TriageStatus.APPLIED and triage.last_validation is not None {
        try {
            summary = auditor(
                triage.fault_id, triage.before_state, triage.after_state,
                applied_actions, triage.last_validation
            );
        } except Exception {
            audit_fallback = True;
            summary = factual_incident_summary(
                triage.fault_id, triage.before_state, triage.after_state,
                applied_actions
            );
        }
    } elif triage.status == TriageStatus.ALREADY_APPLIED {
        summary = f"Recovery for simulated fault {triage.fault_id} was already applied. This run committed no actions.";
    } else {
        summary = f"No recovery action was committed for simulated fault {triage.fault_id}.";
    }

    events: list[AgentEvent] = [];
    _append_event(
        events, run_id, AgentActor.MONITOR, AgentEventKind.OBSERVATION,
        AgentEventOutcome.INFO, f"Observed simulated fault {triage.fault_id}",
        f"generation={triage.before_state.generation_id}; revision={triage.before_state.revision}; " +
        f"served_kw={triage.before_state.metrics.served_kw:.1f}"
    );
    for index in range(len(triage.attempts)) {
        if triage.backup_after_attempt == index {
            _append_event(
                events, run_id, AgentActor.SYSTEM, AgentEventKind.FALLBACK,
                AgentEventOutcome.INFO, "Switched to independent Groq backup",
                triage.backup_reason or "Primary planning did not apply a plan"
            );
        }
        if triage.deterministic_after_attempt == index {
            _append_event(
                events, run_id, AgentActor.SYSTEM, AgentEventKind.FALLBACK,
                AgentEventOutcome.INFO, "Switched to deterministic recovery planning",
                triage.deterministic_reason or "AI planning did not apply a plan"
            );
        }
        attempt = triage.attempts[index];
        attempt_mode = (
            triage.attempt_modes[index]
            if index < len(triage.attempt_modes) else ExecutionMode.PRIMARY_AI
        );
        _append_event(
            events, run_id, AgentActor.PLANNER, AgentEventKind.PROPOSAL,
            AgentEventOutcome.INFO, f"Proposal {index + 1} submitted for validation",
            f"mode={attempt_mode}; proposed actions (not applied): " +
            _action_labels(attempt.plan.actions)
        );
        if attempt.validation is not None {
            accepted = attempt.validation.accepted;
            _append_event(
                events, run_id, AgentActor.VALIDATOR, AgentEventKind.VALIDATION,
                AgentEventOutcome.ACCEPTED if accepted else AgentEventOutcome.REJECTED,
                (
                    "Validator accepted the candidate" if attempt.validation.candidate is not None
                    else "Validator accepted without candidate evidence"
                ) if accepted else "Validator rejected the proposal",
                (
                    f"checked_revision={attempt.validation.checked_revision}; " +
                    ("candidate present" if attempt.validation.candidate is not None else "no candidate")
                ) if accepted else "; ".join(attempt.rejection_reasons)
            );
        } else {
            _append_event(
                events, run_id, AgentActor.SYSTEM, AgentEventKind.VALIDATION,
                AgentEventOutcome.REJECTED, "Proposal did not reach validation",
                "; ".join(attempt.rejection_reasons)
            );
        }
        if (
            index + 1 < len(triage.attempts) and
            (index + 1 >= len(triage.attempt_modes) or
             triage.attempt_modes[index + 1] == attempt_mode)
        ) {
            _append_event(
                events, run_id, AgentActor.PLANNER, AgentEventKind.REVISION,
                AgentEventOutcome.INFO, "Revision requested after rejection",
                "; ".join(attempt.rejection_reasons)
            );
        }
    }
    if triage.backup_after_attempt == len(triage.attempts) {
        _append_event(
            events, run_id, AgentActor.SYSTEM, AgentEventKind.FALLBACK,
            AgentEventOutcome.INFO, "Switched to independent Groq backup",
            triage.backup_reason or "Primary planning did not apply a plan"
        );
    }
    if triage.deterministic_after_attempt == len(triage.attempts) {
        _append_event(
            events, run_id, AgentActor.SYSTEM, AgentEventKind.FALLBACK,
            AgentEventOutcome.INFO, "Switched to deterministic recovery planning",
            triage.deterministic_reason or "AI planning did not apply a plan"
        );
    }
    if triage.status == TriageStatus.APPLIED {
        _append_event(
            events, run_id, AgentActor.SIMULATION, AgentEventKind.APPLICATION,
            AgentEventOutcome.APPLIED, "Validated actions committed to the simulation",
            f"Applied actions: {_action_labels(applied_actions)}; " +
            f"revision={triage.before_state.revision}->{triage.after_state.revision}"
        );
        _append_event(
            events, run_id, AgentActor.AUDITOR, AgentEventKind.AUDIT,
            AgentEventOutcome.INFO if not audit_fallback else AgentEventOutcome.ERROR,
            "Incident account based on committed state" if not audit_fallback else
            "Auditor unavailable; factual summary used", summary
        );
    } elif triage.status == TriageStatus.ALREADY_APPLIED {
        _append_event(
            events, run_id, AgentActor.SYSTEM, AgentEventKind.AUDIT,
            AgentEventOutcome.INFO, "No new recovery action was needed", summary
        );
    } else {
        _append_event(
            events, run_id, AgentActor.SYSTEM, AgentEventKind.FAILURE,
            AgentEventOutcome.ERROR if triage.status in [
                TriageStatus.STALE, TriageStatus.PROVIDER_FAILED,
                TriageStatus.BUDGET_EXHAUSTED, TriageStatus.FALLBACK_FAILED
            ]
            else AgentEventOutcome.REJECTED,
            "Recovery run ended without an applied plan",
            triage.failure_reason or "; ".join(triage.rejection_reasons)
        );
    }

    recovery = RecoveryResult(
        run_id=run_id, fault_id=triage.fault_id,
        outcome=_classify_outcome(triage), execution_mode=mode,
        applied_actions=applied_actions,
        before_metrics=triage.before_state.metrics,
        after_metrics=triage.after_state.metrics,
        incident_summary=summary, proposal_count=triage.proposal_count,
        revision_count=sum([
            1 for event in events if event.kind == AgentEventKind.REVISION
        ]),
        elapsed_ms=max(0, int((perf_counter() - started) * 1000)),
        failure_reason=triage.failure_reason or (
            "; ".join(triage.rejection_reasons)
            if triage.status not in [TriageStatus.APPLIED, TriageStatus.ALREADY_APPLIED]
            else None
        )
    );
    record_agent_run(run_id, triage.before_state.generation_id, events, recovery);
    triage.run_id = run_id;
    triage.recovery_result = recovery;
    return triage;
}


def _run_triage_with_providers(
    fault_id: str,
    primary_planner: Callable[[MonitorFacts, str], RecoveryPlan],
    backup_planner: Callable[[MonitorFacts, str], RecoveryPlan]
) -> TriageResult {
    started = perf_counter();
    run_id = str(uuid4());
    deadline = started + MAX_RECOVERY_SECONDS;
    primary = _run_triage_with_planner(fault_id, primary_planner, deadline);
    primary.attempt_modes = [ExecutionMode.PRIMARY_AI for _ in primary.attempts];
    if primary.status not in [TriageStatus.PROVIDER_FAILED, TriageStatus.EXHAUSTED] {
        return _finalize_triage(primary, run_id, started, ExecutionMode.PRIMARY_AI);
    }
    if not _same_snapshot(primary.before_state) {
        primary.status = TriageStatus.STALE;
        primary.after_state = get_grid_state();
        primary.rejection_reasons = ["Grid changed before backup planning began"];
        primary.failure_reason = "Grid changed before backup planning began";
        return _finalize_triage(primary, run_id, started, ExecutionMode.NONE);
    }
    previous = primary;
    if perf_counter() + REQUEST_TIMEOUT_SECONDS <= deadline {
        backup = _run_triage_with_planner(
            fault_id, backup_planner, deadline, primary.before_state
        );
        if backup.status == TriageStatus.STALE and backup.proposal_count == 0 {
            primary.status = TriageStatus.STALE;
            primary.after_state = backup.after_state;
            primary.rejection_reasons = backup.rejection_reasons;
            primary.failure_reason = "Grid changed before backup planning began";
            return _finalize_triage(primary, run_id, started, ExecutionMode.NONE);
        }
        previous = _combine_provider_runs(primary, backup);
        if backup.status in [TriageStatus.APPLIED, TriageStatus.STALE] {
            return _finalize_triage(previous, run_id, started, ExecutionMode.BACKUP_AI);
        }
    }
    if not _same_snapshot(primary.before_state) {
        previous.status = TriageStatus.STALE;
        previous.after_state = get_grid_state();
        previous.rejection_reasons = ["Grid changed before deterministic planning began"];
        previous.failure_reason = "Grid changed before deterministic planning began";
        return _finalize_triage(previous, run_id, started, ExecutionMode.NONE);
    }
    fallback = _run_deterministic_fallback(primary.before_state, deadline);
    combined = _combine_deterministic_run(previous, fallback);
    return _finalize_triage(combined, run_id, started, ExecutionMode.DETERMINISTIC);
}


def:pub run_triage(
    fault_id: str, generation_id: str = "", expected_revision: int = -1
) -> TriageResult {
    if generation_id {
        current = get_grid_state();
        if (
            current.generation_id != generation_id or
            current.revision != expected_revision or
            current.active_fault_ids != [fault_id]
        ) {
            started = perf_counter();
            stale = _result(
                fault_id, TriageStatus.STALE, current, 0,
                ["Recovery request used an outdated grid generation or revision"],
                failure_reason="Grid changed before recovery started"
            );
            return _finalize_triage(stale, str(uuid4()), started, ExecutionMode.NONE);
        }
    }
    return _run_triage_with_providers(fault_id, propose_plan, propose_backup_plan);
}
