"""Member 2 Step 7: fixed provider failures exercise the public run contract."""

import from time { perf_counter }
import from uuid { uuid4 }
import from agents.events { get_agent_events, get_recovery_result }
import from agents.monitor { MonitorFacts }
import from agents.orchestration {
    _finalize_triage, _run_deterministic_fallback, _run_triage_with_planner,
    _run_triage_with_providers, TriageStatus
}
import from grid.fixture {
    FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP, fixture_lines
}
import from grid.graph { Grid }
import from grid.simulation { get_grid_state, inject_fault, reset_simulation }
import from shared.contracts {
    AgentEventKind, AgentEventOutcome, ExecutionMode, GraphState,
    RecoveryAction, RecoveryActionType, RecoveryOutcome, RecoveryPlan, ValidationResult
}


def _failed_provider(_facts: MonitorFacts, _feedback: str) -> RecoveryPlan {
    raise ValueError("Labeled fixed provider failure");
}


def _unexpected_provider(_facts: MonitorFacts, _feedback: str) -> RecoveryPlan {
    raise AssertionError("No provider call expected");
}


def _switch_plan(facts: MonitorFacts, switch_id: str) -> RecoveryPlan {
    return RecoveryPlan(
        fault_id=FAULT_LINE_A_H,
        grid_generation_id=facts.graph_state.generation_id,
        grid_revision=facts.graph_state.revision,
        actions=[RecoveryAction(
            action_type=RecoveryActionType.CLOSE_SWITCH, target_id=switch_id
        )],
        explanation="Labeled fixed proposal"
    );
}


def _valid(facts: MonitorFacts, _feedback: str) -> RecoveryPlan {
    return _switch_plan(facts, "SW-TIE-B-H");
}


def _revise(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    if feedback == "" { return _switch_plan(facts, "SW-A-H"); }
    assert "physically faulted" in feedback;
    return _valid(facts, feedback);
}


def _reset_during_primary(facts: MonitorFacts, _feedback: str) -> RecoveryPlan {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    return _valid(facts, "");
}


def _failed_auditor(
    _fault_id: str, _before: GraphState, _after: GraphState,
    _actions: list[RecoveryAction], _validation: ValidationResult
) -> str {
    raise ValueError("Labeled fixed auditor failure");
}


test "deterministic route applies validated proposals for all three faults" {
    faults = [FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP];
    served = [180.0, 180.0, 155.0];
    for index in range(len(faults)) {
        reset_simulation();
        result = _run_triage_with_providers(
            faults[index], _failed_provider, _failed_provider
        );
        assert result.status == TriageStatus.APPLIED;
        assert result.recovery_result is not None;
        assert result.recovery_result.execution_mode == ExecutionMode.DETERMINISTIC;
        assert result.recovery_result.outcome == RecoveryOutcome.PARTIAL;
        assert result.recovery_result.proposal_count == 1;
        assert result.after_state.metrics.served_kw == served[index];
        assert result.after_state.metrics.critical_preserved_pct == 100.0;
        assert result.after_state.active_fault_ids == [faults[index]];
        assert result.after_state.revision == result.before_state.revision + 1;
        assert result.last_validation is not None and result.last_validation.accepted;
        events = get_agent_events(result.run_id);
        assert [event.sequence for event in events] == list(range(1, len(events) + 1));
        assert len([event for event in events if event.kind == AgentEventKind.FALLBACK]) == 2;
        assert len([event for event in events if event.kind == AgentEventKind.APPLICATION]) == 1;
        assert "mode=deterministic" in [
            event.evidence for event in events if event.kind == AgentEventKind.PROPOSAL
        ][0];
        stored = get_recovery_result(result.run_id);
        assert stored is not None and stored.execution_mode == ExecutionMode.DETERMINISTIC;
        assert get_agent_events() == events;
    }
}


test "specific rejection produces one revision and primary application" {
    reset_simulation();
    result = _run_triage_with_providers(FAULT_LINE_A_H, _revise, _unexpected_provider);
    assert result.status == TriageStatus.APPLIED;
    assert result.recovery_result is not None;
    assert result.recovery_result.execution_mode == ExecutionMode.PRIMARY_AI;
    assert result.recovery_result.revision_count == 1;
    assert result.proposal_count == 2;
    assert "physically faulted" in "; ".join(result.attempts[0].rejection_reasons);
    events = get_agent_events(result.run_id);
    assert len([event for event in events if event.kind == AgentEventKind.REVISION]) == 1;
    assert len([event for event in events if event.kind == AgentEventKind.FALLBACK]) == 0;
    assert len([event for event in events if event.kind == AgentEventKind.APPLICATION]) == 1;
}


test "no feasible deterministic candidate leaves fault and unmet demand visible" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = [root -->[?:Grid]][0];
    for line in fixture_lines(grid) {
        if line.line_id == "TIE-B-H" { line.physically_faulted = True; }
    }
    before = get_grid_state();
    result = _run_triage_with_providers(
        FAULT_LINE_A_H, _failed_provider, _failed_provider
    );
    assert result.status == TriageStatus.EXHAUSTED;
    assert result.recovery_result is not None;
    assert result.recovery_result.execution_mode == ExecutionMode.NONE;
    assert result.recovery_result.outcome == RecoveryOutcome.INFEASIBLE;
    assert result.after_state.revision == before.revision;
    assert result.after_state.metrics.unmet_kw == before.metrics.unmet_kw;
    assert result.after_state.active_fault_ids == [FAULT_LINE_A_H];
    assert len([event for event in get_agent_events(result.run_id)
                if event.kind == AgentEventKind.APPLICATION]) == 0;
}


test "reset during primary planning blocks every fallback route" {
    reset_simulation();
    result = _run_triage_with_providers(
        FAULT_LINE_A_H, _reset_during_primary, _unexpected_provider
    );
    assert result.status == TriageStatus.STALE;
    assert result.before_state.generation_id != result.after_state.generation_id;
    assert result.recovery_result is not None;
    assert result.recovery_result.execution_mode == ExecutionMode.NONE;
    assert get_agent_events() == [];
    assert len(get_agent_events(result.run_id)) > 0;
}


test "another fault requires reset and does not replace active incident" {
    reset_simulation();
    before = inject_fault(FAULT_SOURCE_A);
    try {
        _run_triage_with_providers(
            FAULT_LINE_A_H, _unexpected_provider, _unexpected_provider
        );
        assert False, "another fault must require reset";
    } except ValueError as error {
        assert "Reset simulation before injecting another fault" in str(error);
    }
    after = get_grid_state();
    assert after.generation_id == before.generation_id;
    assert after.revision == before.revision;
    assert after.active_fault_ids == [FAULT_SOURCE_A];
}


test "duplicate recovery request does not plan or commit again" {
    reset_simulation();
    first = _run_triage_with_providers(
        FAULT_LINE_A_H, _failed_provider, _failed_provider
    );
    assert first.status == TriageStatus.APPLIED;
    second = _run_triage_with_providers(
        FAULT_LINE_A_H, _unexpected_provider, _unexpected_provider
    );
    assert second.status == TriageStatus.ALREADY_APPLIED;
    assert second.proposal_count == 0;
    assert second.after_state.revision == first.after_state.revision;
    assert second.recovery_result is not None;
    assert second.recovery_result.outcome == RecoveryOutcome.NO_ACTION;
    assert second.recovery_result.execution_mode == ExecutionMode.NONE;
}


test "auditor error retains committed result and supplies factual summary" {
    reset_simulation();
    triage = _run_triage_with_planner(FAULT_LINE_A_H, _valid);
    assert triage.status == TriageStatus.APPLIED;
    result = _finalize_triage(
        triage, str(uuid4()), perf_counter(), ExecutionMode.PRIMARY_AI,
        _failed_auditor
    );
    assert result.recovery_result is not None;
    assert result.recovery_result.execution_mode == ExecutionMode.PRIMARY_AI;
    assert "fault remains active" in result.recovery_result.incident_summary;
    assert result.after_state.revision == 2;
    events = get_agent_events(result.run_id);
    assert len([event for event in events if event.kind == AgentEventKind.AUDIT
                and event.outcome == AgentEventOutcome.ERROR]) == 1;
    assert len([event for event in events if event.kind == AgentEventKind.APPLICATION]) == 1;
}


test "expired deadline prevents deterministic generation and application" {
    reset_simulation();
    before = inject_fault(FAULT_LINE_A_H);
    result = _run_deterministic_fallback(before, perf_counter() - 1.0);
    assert result.status == TriageStatus.BUDGET_EXHAUSTED;
    assert result.proposal_count == 0;
    assert get_grid_state().revision == before.revision;
}
