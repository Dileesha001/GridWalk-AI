"""Member 1 Task 6: deterministic fallback and scenario handoff checks."""

import from agents.monitor { MonitorFacts }
import from agents.orchestration { _run_triage_with_planner, TriageStatus }
import from grid.fallback { generate_fallback_plan }
import from grid.fixture { FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP, fixture_lines }
import from grid.graph { Grid }
import from grid.simulation { get_grid_state, inject_fault, reset_simulation, apply_approved_plan }
import from grid.validation { validate_plan }
import from shared.contracts { RecoveryActionType, RecoveryPlan }


def _fixed_fallback(facts: MonitorFacts, feedback: str) -> RecoveryPlan {
    plan = generate_fallback_plan(facts.graph_state);
    if plan is None { raise ValueError("No feasible deterministic proposal"); }
    return plan;
}


test "healthy state has no fallback proposal" {
    healthy = reset_simulation();
    assert generate_fallback_plan(healthy) is None;
    assert get_grid_state().generation_id == healthy.generation_id;
    assert get_grid_state().revision == 0;
}


test "line fault fallback reroutes through healthy tie and retains physical fault" {
    reset_simulation();
    before = inject_fault(FAULT_LINE_A_H);
    plan = generate_fallback_plan(before);
    assert plan is not None;
    assert plan.fault_id == FAULT_LINE_A_H;
    assert plan.grid_generation_id == before.generation_id;
    assert plan.grid_revision == before.revision;
    assert get_grid_state().revision == before.revision;
    assert get_grid_state().metrics.served_kw == before.metrics.served_kw;
    validation = validate_plan(plan);
    assert validation.accepted and validation.candidate_metrics is not None;
    assert validation.candidate_metrics.critical_preserved_pct == 100.0;
    assert validation.candidate_metrics.served_kw == 180.0;
    assert validation.candidate_metrics.unmet_kw == 25.0;
    assert validation.candidate is not None;
    assert validation.candidate.unserved_load_ids == ["LOAD-HOMES"];
    actions = plan.actions;
    closed = [action.target_id for action in actions if action.action_type == RecoveryActionType.CLOSE_SWITCH];
    assert closed == ["SW-TIE-B-A", "SW-TIE-B-H"];
    after = apply_approved_plan(plan);
    assert after.metrics.served_kw == validation.candidate_metrics.served_kw;
    assert after.active_fault_ids == [FAULT_LINE_A_H];
    assert [line for line in after.lines if line.line_id == "LINE-A-H"][0].physically_faulted;
    assert not validate_plan(plan).accepted;
    try {
        apply_approved_plan(plan);
        assert False, "a repeated fallback plan must be stale";
    } except ValueError as error {
        assert "Stale plan revision" in str(error);
    }
    assert get_grid_state().revision == after.revision;
    assert generate_fallback_plan(before) is None;
}


test "source reduction fallback preserves critical demand within ratings" {
    reset_simulation();
    before = inject_fault(FAULT_SOURCE_A);
    plan = generate_fallback_plan(before);
    assert plan is not None;
    assert get_grid_state().revision == before.revision;
    validation = validate_plan(plan);
    assert validation.accepted and validation.candidate_metrics is not None;
    assert validation.candidate_metrics.critical_preserved_pct == 100.0;
    assert validation.candidate_metrics.served_kw == 180.0;
    assert validation.candidate_metrics.unmet_kw == 25.0;
    assert validation.candidate is not None;
    assert validation.candidate.unserved_load_ids == ["LOAD-OFFICE"];
    assert [action.target_id for action in plan.actions] == ["SW-TIE-B-A", "SW-TIE-B-H", "SW-TIE-R-A"];
    after = apply_approved_plan(plan);
    assert after.metrics.served_kw == validation.candidate_metrics.served_kw;
    assert after.metrics.shed_kw == validation.candidate_metrics.shed_kw;
    assert after.active_fault_ids == [FAULT_SOURCE_A];
}


test "insufficient backup fallback leaves unavoidable demand visible" {
    reset_simulation();
    before = inject_fault(FAULT_INSUFFICIENT_BACKUP);
    plan = generate_fallback_plan(before);
    assert get_grid_state().revision == before.revision;
    assert plan is not None;
    assert [action.target_id for action in plan.actions] == ["SW-TIE-B-H"];
    validation = validate_plan(plan);
    assert validation.accepted and validation.candidate_metrics is not None;
    assert validation.candidate_metrics.critical_preserved_pct == 100.0;
    assert validation.candidate_metrics.served_kw == 155.0;
    assert validation.candidate_metrics.unmet_kw == 50.0;
    assert validation.candidate is not None;
    assert validation.candidate.unserved_load_ids == ["LOAD-HOMES", "LOAD-OFFICE"];
    after = apply_approved_plan(plan);
    assert after.metrics.served_kw == validation.candidate_metrics.served_kw;
    assert after.active_fault_ids == [FAULT_INSUFFICIENT_BACKUP];
    assert after.metrics.unmet_kw == 50.0;
}


test "reset makes an old fallback proposal stale" {
    reset_simulation();
    observed = inject_fault(FAULT_LINE_A_H);
    old = generate_fallback_plan(observed);
    assert old is not None;
    reset_simulation();
    reinjected = inject_fault(FAULT_LINE_A_H);
    assert reinjected.revision == old.grid_revision;
    assert reinjected.generation_id != old.grid_generation_id;
    assert not validate_plan(old).accepted;
    assert generate_fallback_plan(observed) is None;
    assert get_grid_state().revision == reinjected.revision;
}


test "blocked alternate path returns no fallback and leaves fault visible" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = [root -->[?:Grid]][0];
    for line in fixture_lines(grid) {
        if line.line_id == "TIE-B-H" { line.physically_faulted = True; }
    }
    before = get_grid_state();
    assert generate_fallback_plan(before) is None;
    after = get_grid_state();
    assert after.generation_id == before.generation_id;
    assert after.revision == before.revision;
    assert after.active_fault_ids == [FAULT_LINE_A_H];
    assert after.metrics.unmet_kw == before.metrics.unmet_kw;
    assert [line for line in after.lines if line.line_id == "TIE-B-H"][0].physically_faulted;
}


test "member two triage accepts fixed fallback proposals for all three faults" {
    faults = [FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP];
    served = [180.0, 180.0, 155.0];
    for index in range(len(faults)) {
        reset_simulation();
        result = _run_triage_with_planner(faults[index], _fixed_fallback);
        assert result.status == TriageStatus.APPLIED;
        assert result.proposal_count == 1;
        assert result.last_validation is not None and result.last_validation.accepted;
        assert result.after_state.metrics.served_kw == served[index];
        assert result.after_state.metrics.critical_preserved_pct == 100.0;
        assert result.after_state.active_fault_ids == [faults[index]];
        assert result.after_state.revision == result.before_state.revision + 1;
    }
}
