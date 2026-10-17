"""Fixed display snapshots using the canonical graph projection; no simulation runs."""

sv import from ..shared.contracts { GraphState, SourceView, LoadView, LineView, GridMetrics }

def:pub topology_example(example: str = "baseline") -> GraphState {
    # IDs, baseline values and wiring match docs/MEMBER_1_FIXTURE.md.
    fault = example in ["line_fault", "rerouted"];
    rerouted = example == "rerouted";
    source_fault = example == "source_fault";
    sources = [
        {"bus_id": "SRC-A", "label": "North substation", "capacity_kw": 50.0 if source_fault else 120.0, "dispatched_kw": 0.0 if source_fault else 45.0 if fault else 105.0, "is_backup": False, "status": "derated" if source_fault else "online"},
        {"bus_id": "SRC-B", "label": "South substation", "capacity_kw": 95.0, "dispatched_kw": 75.0, "is_backup": False, "status": "online"},
        {"bus_id": "SRC-R", "label": "Reserve generator", "capacity_kw": 60.0, "dispatched_kw": 60.0 if rerouted else 25.0, "is_backup": True, "status": "online"}
    ] as list[SourceView];
    ids = ["LOAD-HOSP", "LOAD-WATER", "LOAD-LAB", "LOAD-OFFICE", "LOAD-DATA", "LOAD-PUMP", "LOAD-HOMES", "LOAD-CLINIC", "LOAD-LIGHTS"];
    labels = ["Hospital", "Water treatment", "Research lab", "Offices", "Data center", "Pump station", "Housing", "Clinic", "Street lighting"];
    demands = [35.0, 25.0, 20.0, 25.0, 30.0, 20.0, 25.0, 15.0, 10.0];
    tiers = [1, 1, 2, 3, 1, 2, 3, 1, 3];
    loads: list[LoadView] = [];
    for (i, identity) in enumerate(ids) {
        served = 0.0 if (fault and not rerouted and i < 2) or (source_fault and i < 4) else demands[i];
        status = "unmet" if served == 0 else "rerouted" if rerouted and i < 2 else "powered";
        if rerouted and i == 6 { served = 0.0; status = "shed"; }
        loads.append({"bus_id": identity, "label": labels[i], "demand_kw": demands[i], "tier": tiers[i], "served_kw": served, "deliberately_shed": status == "shed", "status": status} as LoadView);
    }
    endpoints = [["SRC-A", "LOAD-HOSP"], ["LOAD-HOSP", "LOAD-WATER"], ["SRC-A", "LOAD-LAB"], ["LOAD-LAB", "LOAD-OFFICE"], ["SRC-B", "LOAD-DATA"], ["LOAD-DATA", "LOAD-PUMP"], ["SRC-B", "LOAD-HOMES"], ["SRC-R", "LOAD-CLINIC"], ["LOAD-CLINIC", "LOAD-LIGHTS"], ["SRC-B", "LOAD-HOSP"], ["SRC-B", "SRC-A"], ["SRC-R", "SRC-A"]];
    suffixes = ["A-H", "H-W", "A-L", "L-O", "B-D", "D-P", "B-HM", "R-C", "C-LT", "TIE-B-H", "TIE-B-A", "TIE-R-A"];
    capacities = [65.0, 30.0, 50.0, 30.0, 55.0, 25.0, 30.0, 30.0, 15.0, 65.0, 40.0, 40.0];
    transfers = [0.0 if fault or source_fault else 60.0, 0.0 if source_fault or (fault and not rerouted) else 25.0, 0.0 if source_fault else 45.0, 0.0 if source_fault else 25.0, 50.0, 20.0, 0.0 if rerouted else 25.0, 25.0, 10.0, 60.0 if rerouted else 0.0, -35.0 if rerouted else 0.0, 35.0 if rerouted else 0.0];
    lines: list[LineView] = [];
    for (i, suffix) in enumerate(suffixes) {
        physical_fault = fault and i == 0;
        closed = i < 9 or (rerouted and i in [9, 10, 11]);
        lines.append({"line_id": suffix if i >= 9 else "LINE-" + suffix, "from_bus_id": endpoints[i][0], "to_bus_id": endpoints[i][1], "switch_id": "SW-" + suffix, "capacity_kw": capacities[i], "switch_closed": closed, "physically_faulted": physical_fault, "conducting": closed and not physical_fault, "transfer_kw": transfers[i]} as LineView);
    }
    # Post-fault/rerouted snapshots are illustrative display examples, not approved plans.
    metrics = {"total_demand_kw": 205.0, "served_kw": 100.0 if source_fault else 180.0 if rerouted else 145.0 if fault else 205.0, "unmet_kw": 105.0 if source_fault else 25.0 if rerouted else 60.0 if fault else 0.0, "shed_kw": 25.0 if rerouted else 0.0, "available_capacity_kw": 205.0 if source_fault else 275.0, "dispatched_kw": 100.0 if source_fault else 180.0 if rerouted else 145.0 if fault else 205.0, "critical_preserved_pct": 100.0 if not fault and not source_fault or rerouted else 100.0 * 45.0 / 105.0, "active_fault_count": 1 if fault or source_fault else 0} as GridMetrics;
    return {"grid_id": "GRID-01", "generation_id": "FIXED-DISPLAY-EXAMPLE", "revision": 0, "active_fault_ids": ["FAULT-SOURCE-A"] if source_fault else ["FAULT-LINE-A-H"] if fault else [], "sources": sources, "loads": loads, "lines": lines, "metrics": metrics} as GraphState;
}
