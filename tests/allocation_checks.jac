"""Member 1 Task 3: deterministic candidate allocation and routing."""

import from grid.graph { Grid, GridBus, PowerLine }
import from grid.fixture { fixture_sources, fixture_loads, fixture_lines, FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP }
import from grid.simulation { reset_simulation, inject_fault, get_grid_state }
import from grid.allocation { AllocationResult, preview_allocation }

def _current_grid() -> Grid {
    return [root -->[?:Grid]][0];
}

def _assert_conservation(grid: Grid, result: AllocationResult,
                         switches: dict[str, bool]) {
    sources = fixture_sources(grid);
    loads = fixture_loads(grid);
    lines = fixture_lines(grid);
    for source in sources {
        assert result.source_dispatch_kw[source.bus_id] >= 0.0;
        assert result.source_dispatch_kw[source.bus_id] <= source.capacity_kw + 0.000001;
    }
    for load in loads {
        assert result.served_load_kw[load.bus_id] in [0.0, load.demand_kw];
    }
    for line in lines {
        transfer = result.line_transfer_kw[line.line_id];
        assert abs(transfer) <= line.capacity_kw + 0.000001;
        if line.physically_faulted or not switches.get(line.switch_id, line.switch_closed) {
            assert transfer == 0.0;
        }
    }
    buses: list[GridBus] = [];
    buses.extend(sources);
    buses.extend(loads);
    for bus in buses {
        balance = result.source_dispatch_kw.get(bus.bus_id, 0.0);
        for line in lines {
            if line.to_bus_id == bus.bus_id { balance += result.line_transfer_kw[line.line_id]; }
            if line.from_bus_id == bus.bus_id { balance -= result.line_transfer_kw[line.line_id]; }
        }
        assert abs(balance - result.served_load_kw.get(bus.bus_id, 0.0)) < 0.000001;
    }
    assert sum(result.source_dispatch_kw.values()) == sum(result.served_load_kw.values());
}

test "healthy whole-load allocation reproduces reference dispatch" {
    reset_simulation();
    grid = _current_grid();
    result = preview_allocation(grid, {}, set());
    assert result.grid_revision == 0;
    assert result.unserved_load_ids == [];
    assert result.source_dispatch_kw == {"SRC-A": 105.0, "SRC-B": 75.0, "SRC-R": 25.0};
    assert result.line_transfer_kw["LINE-A-H"] == 60.0;
    assert result.line_transfer_kw["LINE-B-D"] == 50.0;
    assert result.line_transfer_kw["LINE-R-C"] == 25.0;
    assert result.line_transfer_kw["TIE-B-H"] == 0.0;
    _assert_conservation(grid, result, {});
}

test "source reduction serves critical demand first and tie can restore water" {
    reset_simulation();
    inject_fault(FAULT_SOURCE_A);
    grid = _current_grid();
    before_revision = grid.revision;
    no_tie = preview_allocation(grid, {}, set());
    assert no_tie.served_load_kw["LOAD-HOSP"] == 35.0;
    assert no_tie.served_load_kw["LOAD-WATER"] == 0.0;
    assert no_tie.served_load_kw["LOAD-LAB"] == 0.0;
    assert sum(no_tie.served_load_kw.values()) == 135.0;
    _assert_conservation(grid, no_tie, {});

    switches = {"SW-TIE-B-A": True};
    with_tie = preview_allocation(grid, switches, set());
    assert with_tie.served_load_kw["LOAD-WATER"] == 25.0;
    assert with_tie.line_transfer_kw["TIE-B-A"] == 25.0;
    assert sum([with_tie.served_load_kw[l.bus_id] for l in fixture_loads(grid) if l.tier == 1]) == 105.0;
    _assert_conservation(grid, with_tie, switches);
    assert grid.revision == before_revision;
    assert not [line for line in fixture_lines(grid) if line.line_id == "TIE-B-A"][0].switch_closed;
    assert get_grid_state().metrics.served_kw == 100.0;
}

test "line fault needs a real alternate path and respects tie rating" {
    reset_simulation();
    inject_fault(FAULT_LINE_A_H);
    grid = _current_grid();
    stranded = preview_allocation(grid, {"SW-A-H": True}, set());
    assert stranded.served_load_kw["LOAD-HOSP"] == 0.0;
    assert stranded.served_load_kw["LOAD-WATER"] == 0.0;
    assert stranded.line_transfer_kw["LINE-A-H"] == 0.0;
    _assert_conservation(grid, stranded, {"SW-A-H": True});
    switches = {"SW-TIE-B-H": True};
    restored = preview_allocation(grid, switches, set());
    assert restored.served_load_kw["LOAD-HOSP"] == 35.0;
    assert restored.served_load_kw["LOAD-WATER"] == 25.0;
    assert restored.line_transfer_kw["LINE-A-H"] == 0.0;
    assert restored.line_transfer_kw["TIE-B-H"] == 60.0;
    _assert_conservation(grid, restored, switches);

    tie = [line for line in fixture_lines(grid) if line.line_id == "TIE-B-H"][0];
    tie.capacity_kw = 20.0;
    limited = preview_allocation(grid, switches, set());
    assert limited.served_load_kw["LOAD-HOSP"] == 0.0;
    assert limited.served_load_kw["LOAD-WATER"] == 0.0;
    assert limited.line_transfer_kw["TIE-B-H"] == 0.0;
    _assert_conservation(grid, limited, switches);
    assert [line for line in fixture_lines(grid) if line.line_id == "LINE-A-H"][0].physically_faulted;
}

test "backup commitments are counted and preview rejects unknown references" {
    reset_simulation();
    inject_fault(FAULT_INSUFFICIENT_BACKUP);
    grid = _current_grid();
    candidate = preview_allocation(grid, {"SW-TIE-B-A": True, "SW-TIE-R-A": True}, set());
    assert candidate.served_load_kw["LOAD-CLINIC"] == 15.0;
    assert candidate.source_dispatch_kw["SRC-R"] <= 30.0;
    _assert_conservation(grid, candidate, {"SW-TIE-B-A": True, "SW-TIE-R-A": True});
    assert get_grid_state().metrics.served_kw == 100.0;

    try {
        preview_allocation(grid, {"SW-UNKNOWN": True}, set());
        assert False, "unknown switch should fail";
    } except ValueError { assert True; }
    try {
        preview_allocation(grid, {}, {"LOAD-UNKNOWN"});
        assert False, "unknown load should fail";
    } except ValueError { assert True; }
    assert grid.revision == 1;
}

test "reverse tie flow and deliberate whole-load shed remain previews" {
    reset_simulation();
    grid = _current_grid();
    south = [source for source in fixture_sources(grid) if source.bus_id == "SRC-B"][0];
    south.capacity_kw = 0.0;
    switches = {"SW-TIE-B-A": True};
    candidate = preview_allocation(grid, switches, {"LOAD-OFFICE"});
    assert candidate.line_transfer_kw["TIE-B-A"] < 0.0;
    assert candidate.served_load_kw["LOAD-DATA"] == 30.0;
    assert candidate.served_load_kw["LOAD-OFFICE"] == 0.0;
    assert "LOAD-OFFICE" in candidate.deliberately_shed_ids;
    _assert_conservation(grid, candidate, switches);
    assert not [line for line in fixture_lines(grid) if line.line_id == "TIE-B-A"][0].switch_closed;
    assert grid.revision == 0;
}
