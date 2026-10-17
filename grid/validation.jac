"""Deterministic, non-mutating validation of typed recovery plans and allocations."""

import math;
import from grid.graph { Grid, GridBus, PowerLine }
import from grid.fixture { fixture_sources, fixture_loads, fixture_lines }
import from grid.allocation { AllocationResult, preview_allocation }
import from grid.metrics { compute_metrics }
import from shared.contracts { RecoveryPlan, RecoveryAction, RecoveryActionType, ValidationResult, CandidateAllocationView, SourceView, LoadView, LineView, GridMetrics }

obj CandidateValidation {
    has accepted: bool;
    has reasons: list[str];
    has allocation: AllocationResult | None;
    has grid_revision: int;
}

def _conducts_in_candidate(line: PowerLine, switches: dict[str, bool]) -> bool {
    return switches.get(line.switch_id, line.switch_closed) and not line.physically_faulted;
}

def _has_supply_path(load_id: str, sources_with_dispatch: set[str],
                     lines: list[PowerLine], switches: dict[str, bool]) -> bool {
    queue: list[str] = [load_id];
    visited: set[str] = {load_id};
    while len(queue) > 0 {
        bus_id = queue.pop(0);
        if bus_id in sources_with_dispatch { return True; }
        for line in lines {
            if not _conducts_in_candidate(line, switches) { continue; }
            neighbor = "";
            if line.from_bus_id == bus_id { neighbor = line.to_bus_id; }
            elif line.to_bus_id == bus_id { neighbor = line.from_bus_id; }
            if neighbor != "" and neighbor not in visited {
                visited.add(neighbor);
                queue.append(neighbor);
            }
        }
    }
    return False;
}

def _validate_allocation(grid: Grid, switches: dict[str, bool],
                         shed_ids: set[str], candidate: AllocationResult) -> list[str] {
    reasons: list[str] = [];
    tolerance_kw = 0.000001;
    sources = fixture_sources(grid);
    loads = fixture_loads(grid);
    lines = fixture_lines(grid);
    source_ids = {source.bus_id for source in sources};
    load_ids = {load.bus_id for load in loads};
    line_ids = {line.line_id for line in lines};
    if candidate.grid_revision != grid.revision {
        reasons.append(f"Stale allocation revision {candidate.grid_revision}; current revision is {grid.revision}");
    }
    if set(candidate.source_dispatch_kw) != source_ids {
        reasons.append("Source dispatch must contain every source ID exactly once");
    }
    if set(candidate.served_load_kw) != load_ids {
        reasons.append("Served load allocation must contain every load ID exactly once");
    }
    if set(candidate.line_transfer_kw) != line_ids {
        reasons.append("Line transfer must contain every line ID exactly once");
    }
    if set(candidate.deliberately_shed_ids) != shed_ids or len(candidate.deliberately_shed_ids) != len(shed_ids) {
        reasons.append("Recorded deliberate sheds do not match requested shed load IDs");
    }
    for source in sources {
        if not math.isfinite(source.capacity_kw) or source.capacity_kw < 0.0 {
            reasons.append(f"Source {source.bus_id} has invalid available capacity");
        }
    }
    for load in loads {
        if not math.isfinite(load.demand_kw) or load.demand_kw < 0.0 {
            reasons.append(f"Load {load.bus_id} has invalid demand");
        }
    }
    for line in lines {
        if not math.isfinite(line.capacity_kw) or line.capacity_kw < 0.0 {
            reasons.append(f"Line {line.line_id} has invalid rating");
        }
    }
    if len(reasons) > 0 { return reasons; }

    for source in sources {
        dispatch = candidate.source_dispatch_kw[source.bus_id];
        if not math.isfinite(dispatch) or dispatch < -tolerance_kw or dispatch > source.capacity_kw + tolerance_kw {
            reasons.append(f"Source {source.bus_id} dispatch {dispatch} kW exceeds its 0..{source.capacity_kw} kW range");
        }
    }
    for load in loads {
        served = candidate.served_load_kw[load.bus_id];
        if not math.isfinite(served) or (abs(served) > tolerance_kw and abs(served - load.demand_kw) > tolerance_kw) {
            reasons.append(f"Load {load.bus_id} must be whole-served ({load.demand_kw} kW) or unserved");
        }
        if load.bus_id in shed_ids and abs(served) > tolerance_kw {
            reasons.append(f"Shed load {load.bus_id} is still allocated {served} kW");
        }
        if load.tier == 1 and served < load.demand_kw - tolerance_kw {
            reasons.append(f"Tier 1 load {load.bus_id} remains unserved");
        }
    }
    for line in lines {
        transfer = candidate.line_transfer_kw[line.line_id];
        if not math.isfinite(transfer) or abs(transfer) > line.capacity_kw + tolerance_kw {
            reasons.append(f"Line {line.line_id} transfer {transfer} kW exceeds its {line.capacity_kw} kW rating");
        }
        if not _conducts_in_candidate(line, switches) and abs(transfer) > tolerance_kw {
            reasons.append(f"Line {line.line_id} carries power while open or physically faulted");
        }
    }
    if len(reasons) > 0 { return reasons; }

    actual_unserved = {load.bus_id for load in loads if candidate.served_load_kw[load.bus_id] < load.demand_kw - tolerance_kw};
    if set(candidate.unserved_load_ids) != actual_unserved or len(candidate.unserved_load_ids) != len(actual_unserved) {
        reasons.append("Recorded unserved loads do not match the candidate service allocation");
    }

    supplying_sources = {source.bus_id for source in sources if candidate.source_dispatch_kw[source.bus_id] > tolerance_kw};
    for load in loads {
        if candidate.served_load_kw[load.bus_id] > tolerance_kw and not _has_supply_path(
            load.bus_id, supplying_sources, lines, switches
        ) {
            reasons.append(f"Served load {load.bus_id} has no healthy conducting supply path");
        }
    }
    buses: list[GridBus] = [];
    buses.extend(sources);
    buses.extend(loads);
    for bus in buses {
        balance = candidate.source_dispatch_kw.get(bus.bus_id, 0.0);
        for line in lines {
            if line.to_bus_id == bus.bus_id { balance += candidate.line_transfer_kw[line.line_id]; }
            if line.from_bus_id == bus.bus_id { balance -= candidate.line_transfer_kw[line.line_id]; }
        }
        served = candidate.served_load_kw.get(bus.bus_id, 0.0);
        if abs(balance - served) > tolerance_kw {
            reasons.append(f"Bus {bus.bus_id} flow imbalance: net {balance} kW, served {served} kW");
        }
    }
    if abs(sum(candidate.source_dispatch_kw.values()) - sum(candidate.served_load_kw.values())) > tolerance_kw {
        reasons.append("Total source dispatch does not equal total served demand");
    }
    for load in loads {
        if load.tier == 2 and load.bus_id in shed_ids {
            for other in loads {
                if other.tier == 3 and candidate.served_load_kw[other.bus_id] > tolerance_kw {
                    reasons.append(f"Tier 2 load {load.bus_id} was deliberately shed while Tier 3 load {other.bus_id} remains served");
                    break;
                }
            }
        }
    }
    return reasons;
}

def validate_candidate(grid: Grid, switch_overrides: dict[str, bool],
                       shed_load_ids: set[str],
                       claimed_allocation: AllocationResult | None = None) -> CandidateValidation {
    reasons: list[str] = [];
    lines = fixture_lines(grid);
    loads = fixture_loads(grid);
    switches_by_id = {line.switch_id: line for line in lines};
    loads_by_id = {load.bus_id: load for load in loads};
    for switch_id in switch_overrides {
        if switch_id not in switches_by_id {
            reasons.append(f"Unknown switch ID: {switch_id}");
        } elif switch_overrides[switch_id] and switches_by_id[switch_id].physically_faulted {
            reasons.append(f"Switch {switch_id} cannot make physically faulted line {switches_by_id[switch_id].line_id} conduct");
        }
    }
    for load_id in shed_load_ids {
        if load_id not in loads_by_id {
            reasons.append(f"Unknown load ID: {load_id}");
        } elif loads_by_id[load_id].tier == 1 {
            reasons.append(f"Deliberate Tier 1 shedding is forbidden: {load_id}");
        }
    }
    if len(reasons) > 0 {
        return CandidateValidation(accepted=False, reasons=reasons, allocation=None, grid_revision=grid.revision);
    }

    candidate: AllocationResult;
    if claimed_allocation is None {
        candidate = preview_allocation(grid, switch_overrides, shed_load_ids);
    } else {
        candidate = claimed_allocation;
    }
    reasons = _validate_allocation(grid, switch_overrides, shed_load_ids, candidate);
    return CandidateValidation(
        accepted=len(reasons) == 0, reasons=reasons,
        allocation=candidate, grid_revision=grid.revision
    );
}


def _candidate_metrics(grid: Grid, switches: dict[str, bool],
                       allocation: AllocationResult) -> GridMetrics {
    sources: list[SourceView] = [];
    loads: list[LoadView] = [];
    lines: list[LineView] = [];
    shed_ids = set(allocation.deliberately_shed_ids);
    for source in fixture_sources(grid) {
        sources.append(SourceView(
            bus_id=source.bus_id, label=source.label, capacity_kw=source.capacity_kw,
            dispatched_kw=allocation.source_dispatch_kw[source.bus_id],
            is_backup=source.is_backup, status="online"
        ));
    }
    for load in fixture_loads(grid) {
        served = allocation.served_load_kw[load.bus_id];
        loads.append(LoadView(
            bus_id=load.bus_id, label=load.label, demand_kw=load.demand_kw,
            tier=load.tier, served_kw=served,
            deliberately_shed=load.bus_id in shed_ids,
            status="powered" if served == load.demand_kw else "unmet"
        ));
    }
    for line in fixture_lines(grid) {
        closed = switches.get(line.switch_id, line.switch_closed);
        lines.append(LineView(
            line_id=line.line_id, from_bus_id=line.from_bus_id,
            to_bus_id=line.to_bus_id, switch_id=line.switch_id,
            capacity_kw=line.capacity_kw, switch_closed=closed,
            physically_faulted=line.physically_faulted,
            conducting=closed and not line.physically_faulted,
            transfer_kw=allocation.line_transfer_kw[line.line_id]
        ));
    }
    faults: list[str] = [];
    if grid.active_fault_id != "" { faults.append(grid.active_fault_id); }
    return compute_metrics(sources, loads, lines, faults);
}


"""Check an observed plan against the current graph without applying it."""
def:pub validate_plan(plan: RecoveryPlan) -> ValidationResult {
    existing = [root -->[?:Grid]];
    if len(existing) == 0 {
        return ValidationResult(
            accepted=False, checked_generation_id="", checked_revision=-1,
            reasons=["No grid is initialized"]
        );
    }
    grid = existing[0];
    reasons: list[str] = [];
    if grid.active_fault_id == "" {
        reasons.append("No active fault to recover");
    }
    if plan.fault_id != grid.active_fault_id {
        reasons.append(f"Plan fault {plan.fault_id} does not match active fault {grid.active_fault_id}");
    }
    if plan.grid_generation_id != grid.generation_id {
        reasons.append("Stale plan generation; reset created a different grid snapshot");
    }
    if plan.grid_revision != grid.revision {
        reasons.append(f"Stale plan revision {plan.grid_revision}; current revision is {grid.revision}");
    }
    if len(reasons) > 0 {
        return ValidationResult(
            accepted=False, checked_generation_id=grid.generation_id,
            checked_revision=grid.revision, reasons=reasons
        );
    }

    switch_ids = {line.switch_id for line in fixture_lines(grid)};
    load_ids = {load.bus_id for load in fixture_loads(grid)};
    switches: dict[str, bool] = {};
    shed_ids: set[str] = {load.bus_id for load in fixture_loads(grid) if load.deliberately_shed};
    for action in plan.actions {
        if not isinstance(action, RecoveryAction) {
            reasons.append("Plan contains an invalid recovery action");
            continue;
        }
        if action.action_type == RecoveryActionType.CLOSE_SWITCH {
            if action.target_id not in switch_ids {
                if action.target_id in load_ids {
                    reasons.append(f"CLOSE_SWITCH target {action.target_id} is a load ID, expected switch ID");
                } else {
                    reasons.append(f"Unknown switch ID: {action.target_id}");
                }
            } elif action.target_id in switches {
                reasons.append(f"Duplicate CLOSE_SWITCH action for {action.target_id}");
            } else {
                switches[action.target_id] = True;
            }
        } elif action.action_type == RecoveryActionType.SHED_LOAD {
            if action.target_id not in load_ids {
                if action.target_id in switch_ids {
                    reasons.append(f"SHED_LOAD target {action.target_id} is a switch ID, expected load ID");
                } else {
                    reasons.append(f"Unknown load ID: {action.target_id}");
                }
            } elif action.target_id in shed_ids {
                reasons.append(f"Duplicate or already applied SHED_LOAD action for {action.target_id}");
            } else {
                shed_ids.add(action.target_id);
            }
        } else {
            reasons.append(f"Unsupported recovery action type: {action.action_type}");
        }
    }
    if len(reasons) > 0 {
        return ValidationResult(
            accepted=False, checked_generation_id=grid.generation_id,
            checked_revision=grid.revision, reasons=reasons
        );
    }
    checked = validate_candidate(grid, switches, shed_ids);
    if not checked.accepted or checked.allocation is None {
        return ValidationResult(
            accepted=False, checked_generation_id=grid.generation_id,
            checked_revision=grid.revision, reasons=checked.reasons
        );
    }
    allocation = checked.allocation;
    candidate = CandidateAllocationView(
        source_dispatch_kw=allocation.source_dispatch_kw.copy(),
        served_load_kw=allocation.served_load_kw.copy(),
        line_transfer_kw=allocation.line_transfer_kw.copy(),
        unserved_load_ids=allocation.unserved_load_ids.copy(),
        deliberately_shed_ids=allocation.deliberately_shed_ids.copy()
    );
    return ValidationResult(
        accepted=True, checked_generation_id=grid.generation_id,
        checked_revision=grid.revision, reasons=[], candidate=candidate,
        candidate_metrics=_candidate_metrics(grid, switches, allocation)
    );
}
