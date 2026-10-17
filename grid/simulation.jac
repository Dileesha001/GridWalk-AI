"""Task 2 fault controls and truthful pre-recovery graph projection.

No switching or recovery allocation is performed here yet. A source zone whose
unchanged local demand exceeds its current capacity is conservatively tripped.
Task 3 replaces that policy with deterministic candidate allocation/routing.
"""

import from grid.graph { Grid, GridBus, Source, Load, PowerLine, conducts }
import from grid.fixture { build_healthy_fixture, fixture_sources, fixture_loads, fixture_lines, fault_scenario }
import from grid.metrics { compute_metrics }
import from shared.contracts { GraphState, SourceView, LoadView, LineView }

def _ensure_grid() -> Grid {
    existing = [root -->[?:Grid]];
    if len(existing) > 0 { return existing[0]; }
    return build_healthy_fixture();
}

def _reachable_load_ids(start_id: str, lines: list[PowerLine],
                        loads_by_id: dict[str, Load]) -> list[str] {
    frontier: list[str] = [start_id];
    visited: set[str] = set();
    reachable: list[str] = [];
    while len(frontier) > 0 {
        bus_id = frontier.pop();
        if bus_id in visited { continue; }
        visited.add(bus_id);
        if bus_id in loads_by_id { reachable.append(bus_id); }
        for line in lines {
            if line.from_bus_id == bus_id and conducts(line) and line.to_bus_id not in visited {
                frontier.append(line.to_bus_id);
            }
        }
    }
    return reachable;
}

def _subtree_flow(bus_id: str, lines: list[PowerLine],
                  served_by_id: dict[str, float], transfer_by_id: dict[str, float],
                  visited: set[str]) -> float {
    if bus_id in visited { return 0.0; }
    visited.add(bus_id);
    total = served_by_id.get(bus_id, 0.0);
    for line in lines {
        if line.from_bus_id == bus_id and conducts(line) and line.to_bus_id not in visited {
            child_flow = _subtree_flow(line.to_bus_id, lines, served_by_id, transfer_by_id, visited);
            transfer_by_id[line.line_id] = child_flow;
            total += child_flow;
        }
    }
    return total;
}

def _project(grid: Grid) -> GraphState {
    sources = fixture_sources(grid);
    loads = fixture_loads(grid);
    lines = fixture_lines(grid);
    loads_by_id = {load.bus_id: load for load in loads};
    served_by_id: dict[str, float] = {load.bus_id: 0.0 for load in loads};
    dispatched_by_id: dict[str, float] = {};
    transfer_by_id: dict[str, float] = {line.line_id: 0.0 for line in lines};

    # Unchanged baseline switches: serve complete source zones only when feasible.
    for source in sources {
        reachable = _reachable_load_ids(source.bus_id, lines, loads_by_id);
        local_demand = sum([loads_by_id[load_id].demand_kw for load_id in reachable]);
        if local_demand <= source.capacity_kw {
            for load_id in reachable { served_by_id[load_id] = loads_by_id[load_id].demand_kw; }
            dispatched_by_id[source.bus_id] = _subtree_flow(
                source.bus_id, lines, served_by_id, transfer_by_id, set()
            );
        } else {
            dispatched_by_id[source.bus_id] = 0.0;
        }
    }

    source_views: list[SourceView] = [];
    for source in sources {
        status = "online";
        if source.bus_id == "SRC-A" and grid.active_fault_id in ["FAULT-SOURCE-A", "FAULT-INSUFFICIENT-BACKUP"] {
            status = "derated";
        }
        if source.bus_id == "SRC-R" and grid.active_fault_id == "FAULT-INSUFFICIENT-BACKUP" {
            status = "derated";
        }
        source_views.append(SourceView(
            bus_id=source.bus_id, label=source.label, capacity_kw=source.capacity_kw,
            dispatched_kw=dispatched_by_id[source.bus_id], is_backup=source.is_backup,
            status=status
        ));
    }

    load_views: list[LoadView] = [];
    for load in loads {
        served = served_by_id[load.bus_id];
        load_views.append(LoadView(
            bus_id=load.bus_id, label=load.label, demand_kw=load.demand_kw,
            tier=load.tier, served_kw=served, deliberately_shed=False,
            status="powered" if served == load.demand_kw else "unmet"
        ));
    }

    line_views: list[LineView] = [];
    for line in lines {
        line_views.append(LineView(
            line_id=line.line_id, from_bus_id=line.from_bus_id, to_bus_id=line.to_bus_id,
            switch_id=line.switch_id, capacity_kw=line.capacity_kw,
            switch_closed=line.switch_closed, physically_faulted=line.physically_faulted,
            conducting=conducts(line), transfer_kw=transfer_by_id[line.line_id]
        ));
    }
    active_fault_ids: list[str] = [];
    if grid.active_fault_id != "" { active_fault_ids.append(grid.active_fault_id); }
    return GraphState(
        grid_id=grid.grid_id, generation_id=grid.generation_id,
        revision=grid.revision, active_fault_ids=active_fault_ids,
        sources=source_views, loads=load_views, lines=line_views,
        metrics=compute_metrics(source_views, load_views, line_views, active_fault_ids)
    );
}

def:pub get_grid_state() -> GraphState {
    return _project(_ensure_grid());
}

def:pub inject_fault(fault_id: str) -> GraphState {
    scenario = fault_scenario(fault_id);
    if scenario is None { raise ValueError(f"Unknown fault ID: {fault_id}"); }
    grid = _ensure_grid();
    if grid.active_fault_id != "" {
        if grid.active_fault_id == fault_id { return _project(grid); }
        raise ValueError("Reset simulation before injecting another fault");
    }
    for source in fixture_sources(grid) {
        if source.bus_id in scenario.source_capacities_kw {
            source.capacity_kw = scenario.source_capacities_kw[source.bus_id];
        }
    }
    for line in fixture_lines(grid) {
        if line.line_id in scenario.fault_line_ids { line.physically_faulted = True; }
    }
    grid.active_fault_id = fault_id;
    grid.revision += 1;
    return _project(grid);
}

def:pub reset_simulation() -> GraphState {
    for existing in [root -->[?:Grid]] {
        for bus in [existing -->[?:GridBus]] { del bus; }
        del existing;
    }
    return _project(build_healthy_fixture());
}
