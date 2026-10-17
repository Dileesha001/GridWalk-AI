"""Deterministic whole-load allocation preview for the Jac grid.

The preview takes switch choices and deliberate sheds as values. It does not
modify graph nodes, line switches, physical faults, or the grid revision.
"""

import from grid.graph { Grid, PowerLine, Source, Load }
import from grid.fixture { fixture_sources, fixture_loads, fixture_lines }

obj RouteStep {
    has parent_bus_id: str;
    has next_bus_id: str;
    has line_id: str;
    has direction: int;
}

obj AllocationResult {
    has grid_revision: int;
    has source_dispatch_kw: dict[str, float];
    has served_load_kw: dict[str, float];
    has line_transfer_kw: dict[str, float];
    has unserved_load_ids: list[str];
    has deliberately_shed_ids: list[str];
}

def _candidate_conducts(line: PowerLine, switches: dict[str, bool]) -> bool {
    return switches.get(line.switch_id, line.switch_closed) and not line.physically_faulted;
}

def _path(source_id: str, load_id: str, demand_kw: float,
          lines: list[PowerLine], switches: dict[str, bool],
          transfer_kw: dict[str, float], tolerance_kw: float) -> list[RouteStep] | None {
    queue: list[str] = [source_id];
    visited: set[str] = {source_id};
    prior: dict[str, RouteStep] = {};
    while len(queue) > 0 {
        current = queue.pop(0);
        if current == load_id {
            route: list[RouteStep] = [];
            cursor = load_id;
            while cursor != source_id {
                step = prior[cursor];
                route.append(step);
                cursor = step.parent_bus_id;
            }
            route.reverse();
            return route;
        }
        for line in lines {
            if not _candidate_conducts(line, switches) { continue; }
            next_id = "";
            direction = 0;
            if line.from_bus_id == current {
                next_id = line.to_bus_id;
                direction = 1;
            } elif line.to_bus_id == current {
                next_id = line.from_bus_id;
                direction = -1;
            }
            if next_id == "" or next_id in visited { continue; }
            new_transfer = transfer_kw[line.line_id] + direction * demand_kw;
            if abs(new_transfer) > line.capacity_kw + tolerance_kw { continue; }
            visited.add(next_id);
            prior[next_id] = RouteStep(
                parent_bus_id=current, next_bus_id=next_id,
                line_id=line.line_id, direction=direction
            );
            queue.append(next_id);
        }
    }
    return None;
}

def preview_allocation(grid: Grid, switch_overrides: dict[str, bool],
                       shed_load_ids: set[str]) -> AllocationResult {
    sources = fixture_sources(grid);
    loads = fixture_loads(grid);
    lines = fixture_lines(grid);
    known_switches = {line.switch_id for line in lines};
    known_loads = {load.bus_id for load in loads};
    for switch_id in switch_overrides {
        if switch_id not in known_switches { raise ValueError(f"Unknown switch ID: {switch_id}"); }
    }
    for load_id in shed_load_ids {
        if load_id not in known_loads { raise ValueError(f"Unknown load ID: {load_id}"); }
    }

    dispatch_kw: dict[str, float] = {source.bus_id: 0.0 for source in sources};
    served_kw: dict[str, float] = {load.bus_id: 0.0 for load in loads};
    transfer_kw: dict[str, float] = {line.line_id: 0.0 for line in lines};
    unserved_ids: list[str] = [];
    tolerance_kw = 0.000001;
    ordered_loads = loads.copy();
    ordered_loads.sort(key=lambda load: Load : (load.tier, load.bus_id));

    # Serve Tier 1 first, then Tier 2, then Tier 3; IDs break ties.
    for load in ordered_loads {
        if load.bus_id in shed_load_ids {
            unserved_ids.append(load.bus_id);
            continue;
        }
        chosen_source_id = "";
        chosen_route: list[RouteStep] = [];
        best_hops = len(lines) + 1;
        for source in sources {
            if dispatch_kw[source.bus_id] + load.demand_kw > source.capacity_kw + tolerance_kw {
                continue;
            }
            route = _path(
                source.bus_id, load.bus_id, load.demand_kw,
                lines, switch_overrides, transfer_kw, tolerance_kw
            );
            if route is None { continue; }
            hops = len(route);
            if hops < best_hops or (hops == best_hops and source.bus_id < chosen_source_id) {
                chosen_source_id = source.bus_id;
                chosen_route.clear();
                chosen_route.extend(route);
                best_hops = hops;
            }
        }
        if chosen_source_id == "" {
            unserved_ids.append(load.bus_id);
            continue;
        }
        served_kw[load.bus_id] = load.demand_kw;
        dispatch_kw[chosen_source_id] += load.demand_kw;
        for step in chosen_route {
            transfer_kw[step.line_id] += step.direction * load.demand_kw;
        }
    }
    return AllocationResult(
        grid_revision=grid.revision, source_dispatch_kw=dispatch_kw,
        served_load_kw=served_kw, line_transfer_kw=transfer_kw,
        unserved_load_ids=unserved_ids, deliberately_shed_ids=sorted(shed_load_ids)
    );
}
