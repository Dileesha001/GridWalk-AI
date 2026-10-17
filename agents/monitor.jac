"""Factual graph observations for the recovery Planner.

The walker visits the grid's bus nodes and reads physical line edges. Service,
dispatch, and metrics come from Member 1's authoritative GraphState projection.
Connectivity here describes possible conducting paths, not a valid allocation.
"""

import from grid.graph { Grid, GridBus, PowerLine, conducts }
import from grid.simulation { get_grid_state }
import from shared.contracts { GraphState }

obj MonitorFacts {
    has graph_state: GraphState;
    has visited_bus_ids: list[str];
    has conducting_line_ids: list[str];
    has faulted_line_ids: list[str];
    has affected_load_ids: list[str];
    has isolated_load_ids: list[str];
    has derated_source_ids: list[str];
    has overloaded_source_ids: list[str];
    has overloaded_line_ids: list[str];
    has backup_source_ids_with_spare: list[str];
    has incident_detected: bool;
}
sem MonitorFacts = "Observed facts about the simulated grid; no recovery action has been approved or applied.";
sem MonitorFacts.graph_state = "Authoritative server projection with current source, load, line, fault, and metric readings.";
sem MonitorFacts.visited_bus_ids = "Stable IDs of the source and load buses inspected by the graph walker.";
sem MonitorFacts.conducting_line_ids = "Physical line IDs whose lines are healthy and switches are closed now.";
sem MonitorFacts.faulted_line_ids = "Physical line IDs marked faulted; a closed switch does not repair them.";
sem MonitorFacts.affected_load_ids = "Loads whose current served kW is below demand, whether due to disconnection or insufficient capacity.";
sem MonitorFacts.isolated_load_ids = "Loads with no conducting path from a source with positive available capacity.";
sem MonitorFacts.derated_source_ids = "Sources whose server-computed status is derated.";
sem MonitorFacts.overloaded_source_ids = "Sources whose current dispatched kW exceeds available capacity in the server projection.";
sem MonitorFacts.overloaded_line_ids = "Lines whose current transfer magnitude exceeds their own rating in the server projection.";
sem MonitorFacts.backup_source_ids_with_spare = "Backup sources with capacity above current dispatch; route and transfer feasibility are unverified.";
sem MonitorFacts.incident_detected = "True when an active fault, derating, physical line fault, unserved load, or current overload was observed.";

def _reachable_bus_ids(state: GraphState) -> set[str] {
    frontier: list[str] = [];
    for source in state.sources {
        if source.capacity_kw > 0.0 and source.status not in ["offline", "faulted"] {
            frontier.append(source.bus_id);
        }
    }
    reachable: set[str] = set();
    while len(frontier) > 0 {
        bus_id = frontier.pop();
        if bus_id in reachable { continue; }
        reachable.add(bus_id);
        for line in state.lines {
            if not line.conducting { continue; }
            if line.from_bus_id == bus_id and line.to_bus_id not in reachable {
                frontier.append(line.to_bus_id);
            } elif line.to_bus_id == bus_id and line.from_bus_id not in reachable {
                frontier.append(line.from_bus_id);
            }
        }
    }
    return reachable;
}

def _assemble_facts(state: GraphState, visited_bus_ids: list[str],
                    visited_line_ids: list[str], conducting_line_ids: list[str],
                    faulted_line_ids: list[str]) -> MonitorFacts {
    for source in state.sources {
        if source.bus_id not in visited_bus_ids {
            raise ValueError(f"Monitor did not visit source {source.bus_id}");
        }
    }
    for load in state.loads {
        if load.bus_id not in visited_bus_ids {
            raise ValueError(f"Monitor did not visit load {load.bus_id}");
        }
    }
    for line in state.lines {
        if line.line_id not in visited_line_ids {
            raise ValueError(f"Monitor did not inspect line {line.line_id}");
        }
    }

    tolerance_kw = 0.000001;
    reachable = _reachable_bus_ids(state);
    affected_load_ids: list[str] = [];
    isolated_load_ids: list[str] = [];
    derated_source_ids: list[str] = [];
    overloaded_source_ids: list[str] = [];
    overloaded_line_ids: list[str] = [];
    backup_source_ids_with_spare: list[str] = [];

    for load in state.loads {
        if load.served_kw + tolerance_kw < load.demand_kw {
            affected_load_ids.append(load.bus_id);
        }
        if load.bus_id not in reachable {
            isolated_load_ids.append(load.bus_id);
        }
    }
    for source in state.sources {
        if source.status == "derated" { derated_source_ids.append(source.bus_id); }
        if source.dispatched_kw > source.capacity_kw + tolerance_kw {
            overloaded_source_ids.append(source.bus_id);
        }
        if source.is_backup and source.capacity_kw > source.dispatched_kw + tolerance_kw {
            backup_source_ids_with_spare.append(source.bus_id);
        }
    }
    for line in state.lines {
        if abs(line.transfer_kw) > line.capacity_kw + tolerance_kw {
            overloaded_line_ids.append(line.line_id);
        }
    }

    affected_load_ids.sort();
    isolated_load_ids.sort();
    derated_source_ids.sort();
    overloaded_source_ids.sort();
    overloaded_line_ids.sort();
    backup_source_ids_with_spare.sort();
    visited_bus_ids.sort();
    conducting_line_ids.sort();
    faulted_line_ids.sort();

    incident_detected = (
        len(state.active_fault_ids) > 0 or len(affected_load_ids) > 0 or
        len(faulted_line_ids) > 0 or len(derated_source_ids) > 0 or
        len(overloaded_source_ids) > 0 or len(overloaded_line_ids) > 0
    );
    return MonitorFacts(
        graph_state=state, visited_bus_ids=visited_bus_ids,
        conducting_line_ids=conducting_line_ids, faulted_line_ids=faulted_line_ids,
        affected_load_ids=affected_load_ids, isolated_load_ids=isolated_load_ids,
        derated_source_ids=derated_source_ids,
        overloaded_source_ids=overloaded_source_ids,
        overloaded_line_ids=overloaded_line_ids,
        backup_source_ids_with_spare=backup_source_ids_with_spare,
        incident_detected=incident_detected
    );
}

walker TelemetryMonitor {
    has graph_state: GraphState;
    has reports: list[MonitorFacts] = [];
    has visited_bus_ids: list[str] = [];
    has visited_line_ids: list[str] = [];
    has conducting_line_ids: list[str] = [];
    has faulted_line_ids: list[str] = [];

    can enter_root with Root entry {
        visit [here -->[?:Grid]];
    }

    can enter_grid with Grid entry {
        if here.grid_id == self.graph_state.grid_id {
            visit [here -->[?:GridBus]];
        }
    }

    can inspect_bus with GridBus entry {
        self.visited_bus_ids.append(here.bus_id);
        for line in [edge here ->:PowerLine:->] {
            self.visited_line_ids.append(line.line_id);
            if conducts(line) { self.conducting_line_ids.append(line.line_id); }
            if line.physically_faulted { self.faulted_line_ids.append(line.line_id); }
        }
    }

    can finish with Root exit {
        report _assemble_facts(
            self.graph_state, self.visited_bus_ids, self.visited_line_ids,
            self.conducting_line_ids, self.faulted_line_ids
        );
    }
}

def inspect_grid() -> MonitorFacts {
    state = get_grid_state();
    result = root spawn TelemetryMonitor(graph_state=state);
    if len(result.reports) != 1 {
        raise ValueError("Monitor produced no single factual snapshot");
    }
    return result.reports[0];
}
