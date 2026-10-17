"""Member 1 Task 2: named faults, state projection, and reset."""

import from grid.simulation { get_grid_state, inject_fault, reset_simulation }
import from grid.fixture { FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP, fault_ids }

test "healthy projection and repeatable reset" {
    first = reset_simulation();
    assert first.grid_id == "GRID-01";
    assert first.revision == 0;
    assert first.active_fault_ids == [];
    assert len(first.sources) == 3 and len(first.loads) == 9 and len(first.lines) == 12;
    assert first.metrics.total_demand_kw == 205.0;
    assert first.metrics.served_kw == 205.0;
    assert first.metrics.unmet_kw == 0.0;
    assert first.metrics.shed_kw == 0.0;
    assert first.metrics.available_capacity_kw == 275.0;
    assert first.metrics.dispatched_kw == 205.0;
    assert first.metrics.critical_preserved_pct == 100.0;
    assert first.metrics.active_fault_count == 0;
    assert sum([line.transfer_kw for line in first.lines]) == 285.0;
    assert len([line for line in first.lines if line.conducting]) == 9;
    assert len([load for load in first.loads if load.status == "powered"]) == 9;

    second = reset_simulation();
    assert second.revision == 0;
    assert second.metrics.total_demand_kw == first.metrics.total_demand_kw;
    assert second.metrics.served_kw == first.metrics.served_kw;
    assert [source.bus_id for source in second.sources] == [source.bus_id for source in first.sources];
    assert [line.line_id for line in second.lines] == [line.line_id for line in first.lines];
    assert [line.transfer_kw for line in second.lines] == [line.transfer_kw for line in first.lines];
    assert get_grid_state().metrics.served_kw == 205.0;
}

test "source reduction leaves unmet demand without overstating recovery" {
    reset_simulation();
    state = inject_fault(FAULT_SOURCE_A);
    source_by_id = {source.bus_id: source for source in state.sources};
    load_by_id = {load.bus_id: load for load in state.loads};
    assert state.active_fault_ids == [FAULT_SOURCE_A];
    assert state.revision == 1;
    assert source_by_id["SRC-A"].capacity_kw == 50.0;
    assert source_by_id["SRC-A"].dispatched_kw == 0.0;
    assert source_by_id["SRC-R"].dispatched_kw == 25.0;
    assert load_by_id["LOAD-HOSP"].served_kw == 0.0;
    assert load_by_id["LOAD-DATA"].served_kw == 30.0;
    assert state.metrics.served_kw == 100.0;
    assert state.metrics.unmet_kw == 105.0;
    assert state.metrics.shed_kw == 0.0;
    assert state.metrics.available_capacity_kw == 205.0;
    assert state.metrics.dispatched_kw == 100.0;
    assert state.metrics.critical_preserved_pct == 100.0 * 45.0 / 105.0;
    assert state.metrics.active_fault_count == 1;
}

test "line fault blocks conducting path but leaves physical fault visible" {
    reset_simulation();
    state = inject_fault(FAULT_LINE_A_H);
    lines = {line.line_id: line for line in state.lines};
    loads = {load.bus_id: load for load in state.loads};
    assert state.active_fault_ids == [FAULT_LINE_A_H];
    assert lines["LINE-A-H"].physically_faulted;
    assert lines["LINE-A-H"].switch_closed;
    assert not lines["LINE-A-H"].conducting;
    assert lines["LINE-A-H"].transfer_kw == 0.0;
    assert lines["LINE-H-W"].transfer_kw == 0.0;
    assert not lines["TIE-B-H"].switch_closed;
    assert loads["LOAD-HOSP"].served_kw == 0.0;
    assert loads["LOAD-WATER"].served_kw == 0.0;
    assert loads["LOAD-LAB"].served_kw == 20.0;
    assert state.metrics.served_kw == 145.0;
    assert state.metrics.unmet_kw == 60.0;
    assert state.metrics.dispatched_kw == 145.0;
}

test "insufficient backup respects local reserve commitments" {
    reset_simulation();
    state = inject_fault(FAULT_INSUFFICIENT_BACKUP);
    sources = {source.bus_id: source for source in state.sources};
    assert sources["SRC-A"].capacity_kw == 50.0;
    assert sources["SRC-R"].capacity_kw == 30.0;
    assert sources["SRC-R"].dispatched_kw == 25.0;
    assert sources["SRC-R"].capacity_kw - sources["SRC-R"].dispatched_kw == 5.0;
    assert state.metrics.available_capacity_kw == 175.0;
    assert state.metrics.served_kw == 100.0;
    assert state.metrics.unmet_kw == 105.0;
    assert state.metrics.shed_kw == 0.0;
}

test "unknown and conflicting faults do not mutate the graph" {
    baseline = reset_simulation();
    assert len(fault_ids()) == 3;
    try {
        inject_fault("FAULT-UNKNOWN");
        assert False, "unknown fault should fail";
    } except ValueError {
        assert True;
    }
    after_unknown = get_grid_state();
    assert after_unknown.revision == baseline.revision;
    assert after_unknown.metrics.served_kw == baseline.metrics.served_kw;
    assert after_unknown.active_fault_ids == [];

    once = inject_fault(FAULT_LINE_A_H);
    again = inject_fault(FAULT_LINE_A_H);
    assert once.revision == 1 and again.revision == 1;
    try {
        inject_fault(FAULT_SOURCE_A);
        assert False, "a different fault requires reset";
    } except ValueError {
        assert True;
    }
    assert get_grid_state().active_fault_ids == [FAULT_LINE_A_H];
    assert get_grid_state().revision == 1;
    assert reset_simulation().active_fault_ids == [];
}
