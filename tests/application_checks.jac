"""Member 1 Task 5: approved plans commit one truthful grid snapshot."""

import from grid.simulation { get_grid_state, inject_fault, reset_simulation, apply_approved_plan }
import from grid.fixture { FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP }
import from grid.graph { Grid }
import from grid.fixture { fixture_lines }
import from grid.validation { validate_plan }
import from shared.contracts { RecoveryPlan, RecoveryAction, RecoveryActionType, GraphState, GridMetrics }


def _plan(fault_id: str, actions: list[RecoveryAction]) -> RecoveryPlan {
    state = get_grid_state();
    return RecoveryPlan(
        fault_id=fault_id, grid_generation_id=state.generation_id,
        grid_revision=state.revision, actions=actions, explanation="Fixed Jac test proposal"
    );
}


def _assert_metrics_equal(actual: GridMetrics, expected: GridMetrics) {
    assert actual.total_demand_kw == expected.total_demand_kw;
    assert actual.served_kw == expected.served_kw;
    assert actual.unmet_kw == expected.unmet_kw;
    assert actual.shed_kw == expected.shed_kw;
    assert actual.available_capacity_kw == expected.available_capacity_kw;
    assert actual.dispatched_kw == expected.dispatched_kw;
    assert actual.critical_preserved_pct == expected.critical_preserved_pct;
    assert actual.active_fault_count == expected.active_fault_count;
}


def _assert_state_equal(actual: GraphState, expected: GraphState) {
    assert actual.grid_id == expected.grid_id;
    assert actual.generation_id == expected.generation_id;
    assert actual.revision == expected.revision;
    assert actual.active_fault_ids == expected.active_fault_ids;
    _assert_metrics_equal(actual.metrics, expected.metrics);
    assert [(item.bus_id, item.capacity_kw, item.dispatched_kw) for item in actual.sources] == [
        (item.bus_id, item.capacity_kw, item.dispatched_kw) for item in expected.sources
    ];
    assert [(item.bus_id, item.served_kw, item.deliberately_shed) for item in actual.loads] == [
        (item.bus_id, item.served_kw, item.deliberately_shed) for item in expected.loads
    ];
    assert [(item.line_id, item.switch_closed, item.physically_faulted, item.transfer_kw) for item in actual.lines] == [
        (item.line_id, item.switch_closed, item.physically_faulted, item.transfer_kw) for item in expected.lines
    ];
}


test "approved line-fault reroute commits matching metrics and retains fault" {
    reset_simulation();
    before = inject_fault(FAULT_LINE_A_H);
    plan = _plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"
    )]);
    preview = validate_plan(plan);
    assert preview.accepted and preview.candidate is not None;
    assert preview.candidate_metrics is not None;
    assert get_grid_state().metrics.served_kw == before.metrics.served_kw;
    committed = apply_approved_plan(plan);
    assert committed.generation_id == before.generation_id;
    assert committed.revision == before.revision + 1;
    assert committed.active_fault_ids == [FAULT_LINE_A_H];
    _assert_metrics_equal(committed.metrics, preview.candidate_metrics);
    assert committed.metrics.critical_preserved_pct == 100.0;
    assert [line for line in committed.lines if line.line_id == "TIE-B-H"][0].switch_closed;
    assert [line for line in committed.lines if line.line_id == "TIE-B-H"][0].transfer_kw == 60.0;
    faulted = [line for line in committed.lines if line.line_id == "LINE-A-H"][0];
    assert faulted.physically_faulted and not faulted.conducting and faulted.transfer_kw == 0.0;
    _assert_state_equal(get_grid_state(), committed);
}


test "rejected and repeated plans never change committed state" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    bad = _plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-A-H"
    )]);
    before = get_grid_state();
    try {
        apply_approved_plan(bad);
        assert False, "faulted line closure must fail";
    } except ValueError as error {
        assert "physically faulted" in str(error);
    }
    _assert_state_equal(get_grid_state(), before);
    good = _plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"
    )]);
    once = apply_approved_plan(good);
    try {
        apply_approved_plan(good);
        assert False, "repeated application must be stale";
    } except ValueError as error {
        assert "Stale plan revision" in str(error);
    }
    _assert_state_equal(get_grid_state(), once);
}


test "reset and reinjected fault reject an old generation" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    old = _plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"
    )]);
    reset_simulation();
    current = inject_fault(FAULT_LINE_A_H);
    assert current.revision == old.grid_revision;
    assert current.generation_id != old.grid_generation_id;
    try {
        apply_approved_plan(old);
        assert False, "old generation must fail";
    } except ValueError as error {
        assert "Stale plan generation" in str(error);
    }
    _assert_state_equal(get_grid_state(), current);
}


test "deliberate shedding and dispatch persist in the authoritative projection" {
    reset_simulation();
    inject_fault(FAULT_SOURCE_A);
    plan = _plan(FAULT_SOURCE_A, [
        RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-A"),
        RecoveryAction(action_type=RecoveryActionType.SHED_LOAD, target_id="LOAD-OFFICE")
    ]);
    candidate = validate_plan(plan);
    assert candidate.accepted and candidate.candidate_metrics is not None;
    committed = apply_approved_plan(plan);
    _assert_metrics_equal(committed.metrics, candidate.candidate_metrics);
    assert committed.metrics.shed_kw == 25.0;
    assert committed.metrics.active_fault_count == 1;
    assert [load for load in committed.loads if load.bus_id == "LOAD-OFFICE"][0].deliberately_shed;
    assert [load for load in committed.loads if load.bus_id == "LOAD-OFFICE"][0].status == "shed";
    assert [source for source in committed.sources if source.bus_id == "SRC-A"][0].capacity_kw == 50.0;
    assert sum([source.dispatched_kw for source in committed.sources]) == committed.metrics.dispatched_kw;

    # A later plan at the current revision cannot silently undo earlier shedding.
    later = _plan(FAULT_SOURCE_A, []);
    later_result = validate_plan(later);
    assert later_result.accepted and later_result.candidate is not None;
    assert "LOAD-OFFICE" in later_result.candidate.deliberately_shed_ids;
    _assert_state_equal(get_grid_state(), committed);

    healthy = reset_simulation();
    assert healthy.generation_id != committed.generation_id;
    assert healthy.revision == 0 and healthy.active_fault_ids == [];
    assert healthy.metrics.served_kw == 205.0 and healthy.metrics.shed_kw == 0.0;
    assert not [load for load in healthy.loads if load.bus_id == "LOAD-OFFICE"][0].deliberately_shed;
    assert not [line for line in healthy.lines if line.line_id == "TIE-B-A"][0].switch_closed;
}


test "infeasible recovery leaves physical and measured state unchanged" {
    reset_simulation();
    before = inject_fault(FAULT_INSUFFICIENT_BACKUP);
    grid = [root -->[?:Grid]][0];
    switches_before = {line.switch_id: line.switch_closed for line in fixture_lines(grid)};
    plan = _plan(FAULT_INSUFFICIENT_BACKUP, []);
    assert not validate_plan(plan).accepted;
    try {
        apply_approved_plan(plan);
        assert False, "critical demand cannot be preserved";
    } except ValueError as error {
        assert "Tier 1 load" in str(error);
    }
    _assert_state_equal(get_grid_state(), before);
    assert {line.switch_id: line.switch_closed for line in fixture_lines(grid)} == switches_before;
}
