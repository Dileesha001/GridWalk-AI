"""Member 2 Step 4: fixed proposals exercise triage without provider calls."""

import from agents.monitor { MonitorFacts }
import from agents.orchestration { _run_triage_with_planner, _run_triage_with_providers, TriageStatus }
import from agents.events { get_agent_events }
import from jaclang.byllm.lib { ByLLMError }
import from grid.fixture { FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP, fixture_lines }
import from grid.graph { Grid }
import from grid.simulation { get_grid_state, inject_fault, reset_simulation }
import from shared.contracts { AgentEventKind, ExecutionMode, RecoveryAction, RecoveryActionType, RecoveryPlan, RecoveryOutcome }
import from time { perf_counter }

def _provider_failure(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    raise ByLLMError("Provider unavailable");
}


def _provider_timeout(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    raise TimeoutError("Provider request timed out");
}


def _plan(facts: MonitorFacts, switch_id: str) -> RecoveryPlan {
    return RecoveryPlan(
        fault_id=FAULT_LINE_A_H,
        grid_generation_id=facts.graph_state.generation_id,
        grid_revision=facts.graph_state.revision,
        actions=[RecoveryAction(
            action_type=RecoveryActionType.CLOSE_SWITCH, target_id=switch_id
        )],
        explanation="Fixed test proposal"
    );
}


def _valid(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    return _plan(facts, "SW-TIE-B-H");
}


def _invalid(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    return _plan(facts, "SW-A-H");
}


def _revise(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    if feedback == "" { return _invalid(facts, feedback); }
    assert "physically faulted" in feedback;
    assert "SW-A-H" in feedback;
    assert get_grid_state().revision == facts.graph_state.revision;
    return _valid(facts, feedback);
}


def _empty(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    plan = _plan(facts, "SW-TIE-B-H");
    plan.actions = [];
    return plan;
}


def _reset_during_planning(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    return _valid(facts, feedback);
}


def _malformed(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    raise ValueError("Bad provider output");
}


def _provider_error(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    raise ByLLMError("Provider unavailable");
}


def _unexpected_call(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    raise AssertionError("duplicate triage must not call the planner");
}


test "accepted fixed proposal applies one current plan" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _valid);
    assert result.status == TriageStatus.APPLIED;
    assert result.proposal_count == 1 and len(result.attempts) == 1;
    assert result.attempts[0].validation is not None;
    assert result.attempts[0].validation.accepted;
    assert result.before_state.revision == 1;
    assert result.after_state.revision == 2;
    assert result.after_state.generation_id == result.before_state.generation_id;
    assert result.after_state.metrics.critical_preserved_pct == 100.0;
    assert result.after_state.active_fault_ids == [FAULT_LINE_A_H];
    assert get_grid_state().revision == 2;
}


test "specific rejection reaches revision before application" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _revise);
    assert result.status == TriageStatus.APPLIED;
    assert result.proposal_count == 2 and len(result.attempts) == 2;
    assert result.attempts[0].validation is not None;
    assert not result.attempts[0].validation.accepted;
    assert "physically faulted" in "; ".join(result.attempts[0].rejection_reasons);
    assert result.attempts[1].validation is not None;
    assert result.attempts[1].validation.accepted;
    assert result.after_state.revision == 2;
}


test "exhausted invalid proposals leave the faulted state unchanged" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _invalid);
    assert result.status == TriageStatus.EXHAUSTED;
    assert result.proposal_count == 2 and len(result.attempts) == 2;
    assert result.after_state.revision == result.before_state.revision == 1;
    assert result.after_state.metrics.served_kw == result.before_state.metrics.served_kw;
    assert get_grid_state().revision == 1;
}


test "empty proposals exhaust without a validator approval" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _empty);
    assert result.status == TriageStatus.EXHAUSTED;
    assert result.proposal_count == 2 and len(result.attempts) == 2;
    assert result.attempts[0].validation is None;
    assert result.attempts[1].validation is None;
    assert result.after_state.revision == 1;
}


test "reset during planning stops a stale proposal" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _reset_during_planning);
    assert result.status == TriageStatus.STALE;
    assert result.proposal_count == 1;
    assert result.before_state.generation_id != result.after_state.generation_id;
    assert result.after_state.revision == 1;
    assert get_grid_state().revision == 1;
}


test "duplicate request returns already applied without calling planner" {
    reset_simulation();
    first = _run_triage_with_planner(FAULT_LINE_A_H, _valid);
    assert first.status == TriageStatus.APPLIED;
    second = _run_triage_with_planner(FAULT_LINE_A_H, _unexpected_call);
    assert second.status == TriageStatus.ALREADY_APPLIED;
    assert second.proposal_count == 0 and len(second.attempts) == 0;
    assert second.after_state.revision == first.after_state.revision;
}


test "malformed planner output returns without application" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _malformed);
    assert result.status == TriageStatus.PROVIDER_FAILED;
    assert result.proposal_count == 0;
    assert result.after_state.revision == 1;
    assert result.failure_reason == "Planner returned a malformed proposal";
}


test "provider exception returns without application or raw error text" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _provider_error);
    assert result.status == TriageStatus.PROVIDER_FAILED;
    assert result.proposal_count == 0 and len(result.attempts) == 0;
    assert result.after_state.revision == 1;
    assert result.failure_reason == "Planner provider failed before a valid proposal was available";
}

test "deterministic fallback applies after both AI providers fail" {
    reset_simulation();
    result = _run_triage_with_providers(
        FAULT_LINE_A_H, _provider_failure, _provider_failure
    );
    assert result.status == TriageStatus.APPLIED;
    assert result.recovery_result is not None;
    assert result.recovery_result.execution_mode == ExecutionMode.DETERMINISTIC;
    assert result.after_state.revision == result.before_state.revision + 1;
    assert result.after_state.metrics.critical_preserved_pct == 100.0;
    assert any([
        event.kind == AgentEventKind.FALLBACK and
        "deterministic" in event.summary.lower()
        for event in get_agent_events(result.run_id)
    ]);
}

test "expired request budget prevents another provider call" {
    reset_simulation();
    result = _run_triage_with_planner(
        FAULT_LINE_A_H, _unexpected_call, perf_counter() - 1.0
    );
    assert result.status == TriageStatus.BUDGET_EXHAUSTED;
    assert result.proposal_count == 0 and len(result.attempts) == 0;
    assert result.failure_reason == "Recovery deadline left no time for another provider request";
    assert get_grid_state().revision == 1;
    assert get_grid_state().active_fault_ids == [FAULT_LINE_A_H];
}

test "provider timeout leaves the faulted graph unchanged" {
    reset_simulation();
    result = _run_triage_with_planner(FAULT_LINE_A_H, _provider_timeout);
    assert result.status == TriageStatus.PROVIDER_FAILED;
    assert result.failure_reason == "Planner request timed out";
    assert result.proposal_count == 0 and len(result.attempts) == 0;
    assert get_grid_state().revision == result.before_state.revision;
    assert get_grid_state().metrics.served_kw == result.before_state.metrics.served_kw;
}

test "provider failures still permit partial recovery during backup shortage" {
    reset_simulation();
    result = _run_triage_with_providers(
        FAULT_INSUFFICIENT_BACKUP, _provider_failure, _provider_failure
    );
    assert result.status == TriageStatus.APPLIED;
    assert result.recovery_result is not None;
    assert result.recovery_result.outcome == RecoveryOutcome.PARTIAL;
    assert result.recovery_result.execution_mode == ExecutionMode.DETERMINISTIC;
    assert result.after_state.metrics.served_kw == 155.0;
    assert result.after_state.metrics.unmet_kw == 50.0;
    assert result.after_state.metrics.critical_preserved_pct == 100.0;
}

test "unavailable alternate path leaves no feasible fallback and commits nothing" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = [root -->[?:Grid]][0];
    for line in fixture_lines(grid) {
        if line.line_id == "TIE-B-H" { line.physically_faulted = True; }
    }
    before = get_grid_state();
    result = _run_triage_with_providers(FAULT_LINE_A_H, _provider_failure, _provider_failure);
    assert result.status == TriageStatus.EXHAUSTED;
    assert result.recovery_result is not None;
    assert result.recovery_result.outcome == RecoveryOutcome.INFEASIBLE;
    assert result.recovery_result.execution_mode == ExecutionMode.NONE;
    assert len(result.recovery_result.applied_actions) == 0;
    assert result.after_state.revision == before.revision;
    assert result.after_state.metrics.served_kw == before.metrics.served_kw;
    assert not any([event.kind == AgentEventKind.APPLICATION for event in get_agent_events(result.run_id)]);
}
