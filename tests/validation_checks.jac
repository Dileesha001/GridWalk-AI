"""Member 1 Task 4: non-mutating candidate-state validation."""

import from grid.graph { Grid }
import from grid.fixture { fixture_lines, FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP }
import from grid.simulation { reset_simulation, inject_fault, get_grid_state }
import from grid.allocation { preview_allocation }
import from grid.validation { validate_candidate, validate_plan }
import from shared.contracts { RecoveryPlan, RecoveryAction, RecoveryActionType }

def _grid() -> Grid {
    return [root -->[?:Grid]][0];
}

test "valid alternate route is accepted without changing the faulted graph" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = _grid();
    result = validate_candidate(grid, {"SW-TIE-B-H": True}, set());
    assert result.accepted;
    assert result.reasons == [];
    assert result.allocation is not None;
    assert result.allocation.served_load_kw["LOAD-HOSP"] == 35.0;
    assert result.allocation.line_transfer_kw["TIE-B-H"] == 60.0;
    assert grid.revision == 1;
    assert get_grid_state().metrics.served_kw == 145.0;
    assert [line for line in fixture_lines(grid) if line.line_id == "LINE-A-H"][0].physically_faulted;
    assert not [line for line in fixture_lines(grid) if line.line_id == "TIE-B-H"][0].switch_closed;
}

test "unknown targets and deliberate critical shedding are rejected" {
    reset_simulation();
    grid = _grid();
    bad_switch = validate_candidate(grid, {"LOAD-HOSP": True}, set());
    assert not bad_switch.accepted;
    assert "Unknown switch ID: LOAD-HOSP" in bad_switch.reasons;
    bad_load = validate_candidate(grid, {}, {"SRC-A"});
    assert not bad_load.accepted;
    assert "Unknown load ID: SRC-A" in bad_load.reasons;
    critical = validate_candidate(grid, {}, {"LOAD-HOSP"});
    assert not critical.accepted;
    assert "Deliberate Tier 1 shedding is forbidden: LOAD-HOSP" in critical.reasons;
    assert critical.allocation is None;
    assert get_grid_state().metrics.served_kw == 205.0;
    assert grid.revision == 0;
}

test "closing a faulted line cannot restore isolated critical demand" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = _grid();
    closed_fault = validate_candidate(grid, {"SW-A-H": True}, set());
    assert not closed_fault.accepted;
    assert len([reason for reason in closed_fault.reasons if "physically faulted" in reason]) > 0;
    isolated = validate_candidate(grid, {}, set());
    assert not isolated.accepted;
    assert "Tier 1 load LOAD-HOSP remains unserved" in isolated.reasons;
    assert "Tier 1 load LOAD-WATER remains unserved" in isolated.reasons;
    assert get_grid_state().metrics.served_kw == 145.0;
}

test "forged source and line overloads are rejected" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = _grid();
    switches = {"SW-TIE-B-H": True};
    over_source = preview_allocation(grid, switches, set());
    over_source.source_dispatch_kw["SRC-B"] = 120.0;
    result_source = validate_candidate(grid, switches, set(), over_source);
    assert not result_source.accepted;
    assert len([reason for reason in result_source.reasons if "Source SRC-B dispatch" in reason]) > 0;

    over_line = preview_allocation(grid, switches, set());
    over_line.line_transfer_kw["TIE-B-H"] = 100.0;
    result_line = validate_candidate(grid, switches, set(), over_line);
    assert not result_line.accepted;
    assert len([reason for reason in result_line.reasons if "Line TIE-B-H transfer" in reason]) > 0;
    assert get_grid_state().metrics.served_kw == 145.0;
}

test "open-line flow and invalid numeric claims are rejected" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = _grid();
    switches = {"SW-TIE-B-H": True};
    open_flow = preview_allocation(grid, switches, set());
    invalid_path = validate_candidate(grid, {}, set(), open_flow);
    assert not invalid_path.accepted;
    assert "Line TIE-B-H carries power while open or physically faulted" in invalid_path.reasons;

    partial = preview_allocation(grid, switches, set());
    partial.served_load_kw["LOAD-HOSP"] = 17.5;
    invalid_service = validate_candidate(grid, switches, set(), partial);
    assert not invalid_service.accepted;
    assert len([reason for reason in invalid_service.reasons if "whole-served" in reason]) > 0;

    nonfinite = preview_allocation(grid, switches, set());
    nonfinite.source_dispatch_kw["SRC-B"] = float("nan");
    invalid_number = validate_candidate(grid, switches, set(), nonfinite);
    assert not invalid_number.accepted;
    assert len([reason for reason in invalid_number.reasons if "Source SRC-B dispatch" in reason]) > 0;
    assert get_grid_state().metrics.served_kw == 145.0;
}

test "false isolated service and double-counted reserve fail complete-state checks" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = _grid();
    claimed = preview_allocation(grid, {"SW-TIE-B-H": True}, set());
    claimed.line_transfer_kw["TIE-B-H"] = 0.0;
    isolated = validate_candidate(grid, {}, set(), claimed);
    assert not isolated.accepted;
    assert len([reason for reason in isolated.reasons if "no healthy conducting supply path" in reason]) > 0;
    assert len([reason for reason in isolated.reasons if "flow imbalance" in reason]) > 0;

    reset_simulation();
    inject_fault(FAULT_INSUFFICIENT_BACKUP);
    grid = _grid();
    reserve = preview_allocation(grid, {"SW-TIE-B-A": True, "SW-TIE-R-A": True}, set());
    reserve.source_dispatch_kw["SRC-R"] = 40.0;
    double_counted = validate_candidate(grid, {"SW-TIE-B-A": True, "SW-TIE-R-A": True}, set(), reserve);
    assert not double_counted.accepted;
    assert len([reason for reason in double_counted.reasons if "Source SRC-R dispatch" in reason]) > 0;
    assert get_grid_state().metrics.served_kw == 100.0;
}

test "tier ordering metadata and stale revisions are checked" {
    reset_simulation();
    grid = _grid();
    priority = validate_candidate(grid, {}, {"LOAD-LAB"});
    assert not priority.accepted;
    assert len([reason for reason in priority.reasons if "Tier 2 load LOAD-LAB" in reason]) > 0;

    claimed = preview_allocation(grid, {}, set());
    claimed.unserved_load_ids.append("LOAD-HOSP");
    false_metadata = validate_candidate(grid, {}, set(), claimed);
    assert not false_metadata.accepted;
    assert "Recorded unserved loads do not match the candidate service allocation" in false_metadata.reasons;

    reset_simulation();
    inject_fault(FAULT_SOURCE_A);
    grid = _grid();
    stale = preview_allocation(grid, {"SW-TIE-B-A": True}, set());
    stale.grid_revision = 0;
    result = validate_candidate(grid, {"SW-TIE-B-A": True}, set(), stale);
    assert not result.accepted;
    assert len([reason for reason in result.reasons if "Stale allocation revision" in reason]) > 0;
    assert get_grid_state().revision == 1;
}


def _plan(fault_id: str, actions: list[RecoveryAction]) -> RecoveryPlan {
    state = get_grid_state();
    return RecoveryPlan(
        fault_id=fault_id, grid_generation_id=state.generation_id,
        grid_revision=state.revision, actions=actions, explanation="Test proposal"
    );
}


test "typed plan returns a complete candidate and candidate metrics without mutation" {
    reset_simulation();
    before = inject_fault(FAULT_LINE_A_H);
    plan = _plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"
    )]);
    result = validate_plan(plan);
    assert result.accepted and result.reasons == [];
    assert result.checked_generation_id == before.generation_id;
    assert result.checked_revision == before.revision;
    assert result.candidate is not None;
    assert result.candidate_metrics is not None;
    assert result.candidate.served_load_kw["LOAD-HOSP"] == 35.0;
    assert result.candidate.line_transfer_kw["TIE-B-H"] == 60.0;
    assert result.candidate.line_transfer_kw["LINE-A-H"] == 0.0;
    assert result.candidate_metrics.served_kw == sum(result.candidate.served_load_kw.values());
    assert result.candidate_metrics.unmet_kw == 205.0 - result.candidate_metrics.served_kw;
    assert result.candidate_metrics.critical_preserved_pct == 100.0;
    assert result.candidate_metrics.active_fault_count == 1;
    after = get_grid_state();
    assert after.generation_id == before.generation_id;
    assert after.revision == before.revision;
    assert after.metrics.served_kw == 145.0;
    assert not [line for line in after.lines if line.line_id == "TIE-B-H"][0].switch_closed;
}


test "typed plan rejects stale revision, fault and reset generation" {
    reset_simulation();
    first = inject_fault(FAULT_LINE_A_H);
    plan = _plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"
    )]);
    plan.grid_revision = 0;
    stale_revision = validate_plan(plan);
    assert not stale_revision.accepted;
    assert len([reason for reason in stale_revision.reasons if "Stale plan revision" in reason]) == 1;
    assert stale_revision.candidate is None;
    plan.grid_revision = first.revision;
    plan.fault_id = FAULT_SOURCE_A;
    wrong_fault = validate_plan(plan);
    assert not wrong_fault.accepted;
    assert len([reason for reason in wrong_fault.reasons if "does not match active fault" in reason]) == 1;
    plan.fault_id = FAULT_LINE_A_H;
    reset_simulation();
    second = inject_fault(FAULT_LINE_A_H);
    assert first.generation_id != second.generation_id;
    stale_generation = validate_plan(plan);
    assert not stale_generation.accepted;
    assert len([reason for reason in stale_generation.reasons if "Stale plan generation" in reason]) == 1;
    assert stale_generation.checked_generation_id == second.generation_id;
    assert get_grid_state().metrics.served_kw == 145.0;
}


test "typed plan rejects wrong target kinds, unknown IDs, duplicates and unsupported actions" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    bad = _plan(FAULT_LINE_A_H, [
        RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="LOAD-HOSP"),
        RecoveryAction(action_type=RecoveryActionType.SHED_LOAD, target_id="SW-TIE-B-H"),
        RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-UNKNOWN"),
        RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"),
        RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-H"),
        RecoveryAction(action_type="OPEN_SWITCH" as RecoveryActionType, target_id="SW-A-H")
    ]);
    result = validate_plan(bad);
    assert not result.accepted;
    assert len(result.reasons) == 5;
    assert len([reason for reason in result.reasons if "expected switch ID" in reason]) == 1;
    assert len([reason for reason in result.reasons if "expected load ID" in reason]) == 1;
    assert "Unknown switch ID: SW-UNKNOWN" in result.reasons;
    assert "Duplicate CLOSE_SWITCH action for SW-TIE-B-H" in result.reasons;
    assert "Unsupported recovery action type: OPEN_SWITCH" in result.reasons;
    assert result.candidate is None and result.candidate_metrics is None;
    assert get_grid_state().revision == 1;
}


test "typed plan rejects physical fault and deliberate critical shedding" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    faulted = validate_plan(_plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-A-H"
    )]));
    assert not faulted.accepted;
    assert len([reason for reason in faulted.reasons if "physically faulted" in reason]) > 0;
    critical = validate_plan(_plan(FAULT_LINE_A_H, [RecoveryAction(
        action_type=RecoveryActionType.SHED_LOAD, target_id="LOAD-HOSP"
    )]));
    assert not critical.accepted;
    assert "Deliberate Tier 1 shedding is forbidden: LOAD-HOSP" in critical.reasons;
    assert get_grid_state().metrics.served_kw == 145.0;
}


test "typed plan records deliberate noncritical shedding in candidate metrics" {
    reset_simulation();
    before = inject_fault(FAULT_SOURCE_A);
    result = validate_plan(_plan(FAULT_SOURCE_A, [
        RecoveryAction(action_type=RecoveryActionType.CLOSE_SWITCH, target_id="SW-TIE-B-A"),
        RecoveryAction(action_type=RecoveryActionType.SHED_LOAD, target_id="LOAD-OFFICE")
    ]));
    assert result.accepted;
    assert result.candidate is not None and result.candidate_metrics is not None;
    assert result.candidate.deliberately_shed_ids == ["LOAD-OFFICE"];
    assert result.candidate.served_load_kw["LOAD-OFFICE"] == 0.0;
    assert result.candidate_metrics.shed_kw == 25.0;
    assert result.candidate_metrics.critical_preserved_pct == 100.0;
    assert get_grid_state().revision == before.revision;
    assert get_grid_state().metrics.shed_kw == 0.0;
}
