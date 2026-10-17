"""Checks for fixed topology examples and presentation helpers, not simulation claims."""

sv import from ..shared.contracts { LoadView }
import from .topology_examples { topology_example }
import from .topology_layout { topology_positions, topology_height, line_label, line_color, load_style, source_style }

test "canonical fixture IDs and baseline dispatch agree" {
    grid = topology_example();
    assert grid.grid_id == "GRID-01";
    assert len(grid.sources) == 3 and len(grid.loads) == 9 and len(grid.lines) == 12;
    assert grid.sources[0].bus_id == "SRC-A";
    assert grid.loads[0].bus_id == "LOAD-HOSP";
    assert grid.lines[0].switch_id == "SW-A-H";
    assert grid.metrics.total_demand_kw == 205.0;
    assert grid.metrics.available_capacity_kw == 275.0;
    assert grid.metrics.dispatched_kw == 205.0;
}

test "every display example conserves power without repairing faults" {
    for name in ["baseline", "source_fault", "line_fault", "rerouted"] {
        grid = topology_example(name);
        supply = 0.0;
        served = 0.0;
        for source in grid.sources {
            assert source.dispatched_kw <= source.capacity_kw;
            supply += source.dispatched_kw;
            balance = source.dispatched_kw;
            for line in grid.lines {
                if line.from_bus_id == source.bus_id { balance -= line.transfer_kw; }
                if line.to_bus_id == source.bus_id { balance += line.transfer_kw; }
            }
            assert balance == 0.0;
        }
        for load in grid.loads {
            served += load.served_kw;
            balance = -load.served_kw;
            for line in grid.lines {
                if line.from_bus_id == load.bus_id { balance -= line.transfer_kw; }
                if line.to_bus_id == load.bus_id { balance += line.transfer_kw; }
            }
            assert balance == 0.0;
        }
        assert supply == served and served == grid.metrics.served_kw;
        for line in grid.lines {
            assert abs(line.transfer_kw) <= line.capacity_kw;
            if not line.conducting { assert line.transfer_kw == 0.0; }
        }
        if name == "rerouted" {
            assert grid.lines[0].physically_faulted;
            assert grid.lines[0].switch_closed;
            assert not grid.lines[0].conducting;
            assert grid.loads[0].status == "rerouted";
            assert grid.loads[6].deliberately_shed;
            assert len(grid.active_fault_ids) == 1;
        }
    }
}

test "positions depend on stable IDs rather than response order" {
    grid = topology_example();
    before = topology_positions(grid);
    grid.sources = list(reversed(grid.sources));
    grid.loads = list(reversed(grid.loads));
    after = topology_positions(grid);
    assert before["SRC-A"][0] == after["SRC-A"][0];
    assert before["LOAD-HOSP"][1] == after["LOAD-HOSP"][1];
}

test "new IDs get visible distinct positions and extend the canvas" {
    grid = topology_example();
    grid.loads = grid.loads + [{"bus_id": "LOAD-NEW", "label": "New facility", "demand_kw": 1.0, "tier": 3, "served_kw": 0.0, "deliberately_shed": False, "status": "unmet"} as LoadView];
    points = topology_positions(grid);
    assert points["LOAD-NEW"][1] > 580.0;
    assert topology_height(grid) > points["LOAD-NEW"][1];
}

test "switch closure never overrides the physical fault display" {
    grid = topology_example("rerouted");
    assert line_label(grid.lines[0]) == "FAULTED / Closed";
    assert line_color(grid.lines[0]) == "var(--fault)";
    assert line_label(topology_example().lines[9]) == "Healthy / Open";
}

test "status styling retains distinct states and signed transfers" {
    grid = topology_example("rerouted");
    assert grid.lines[10].transfer_kw == -35.0;
    assert load_style("rerouted") == "rerouted";
    assert load_style("shed") == "shed";
    assert load_style("unmet") == "fault";
    assert source_style("derated") == "source-warning";
    assert load_style("future-status") == "unknown";
}
