"""Bounded proposal, validation, and approved application coordination.

Auditor events, provider fallback, and total request budgets follow in later
Member 2 tasks. This module never writes graph entities directly.
"""

import from agents.monitor { MonitorFacts, inspect_grid }
import from agents.planner { propose_plan }
import from byllm.lib { ByLLMError }
import from grid.graph { Grid }
import from grid.simulation { get_grid_state, inject_fault, apply_approved_plan }
import from grid.validation { validate_plan }
import from shared.contracts { GraphState, RecoveryAction, RecoveryPlan, ValidationResult }

glob MAX_PLAN_PROPOSALS: int = 2;

enum TriageStatus: str {
    APPLIED = "applied",
    ALREADY_APPLIED = "already_applied",
    EXHAUSTED = "exhausted",
    STALE = "stale",
    PROVIDER_FAILED = "provider_failed"
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

def run_triage(fault_id: str) -> TriageResult {
    before = inject_fault(fault_id);
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
        try {
            plan = propose_plan(facts, feedback);
        } except ByLLMError {
            return _result(fault_id, TriageStatus.PROVIDER_FAILED, before, proposal_count,
                           reasons, last_plan, last_validation,
                           "Planner provider failed before a valid proposal was available",
                           attempts=attempts);
        } except ValueError {
            return _result(fault_id, TriageStatus.PROVIDER_FAILED, before, proposal_count,
                           reasons, last_plan, last_validation,
                           "Planner returned a malformed proposal", attempts=attempts);
        }
        proposal_count += 1;
        last_plan = plan;

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
