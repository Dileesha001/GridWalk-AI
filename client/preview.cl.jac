"""Fixed UI examples only: no allocation solver, AI calls, or simulation mutations."""

import from .models { SourceView, LoadView, LineView, GridView, MetricsView, EventView, RecoveryView }

def:pub preview_grid(stage: str = "baseline", scenario: str = "source_reduction") -> GridView {
    fault = stage != "baseline";
    recovered = stage == "recovered";
    limited = scenario == "insufficient_backup";
    line_fault = fault and scenario == "line_failure";
    capacity_a = 60.0 if fault and not line_fault else 180.0;
    capacity_b = 120.0 if fault and limited else 200.0;
    sources = [
        SourceView(id="SRC-A", name="Campus solar", capacity_kw=capacity_a, dispatch_kw=60.0 if fault and not line_fault else 120.0, status="fault" if fault and not line_fault else "powered"),
        SourceView(id="SRC-B", name="Utility supply", capacity_kw=capacity_b, dispatch_kw=180.0 if recovered and not limited and not line_fault else 120.0, status="powered"),
        SourceView(id="SRC-C", name="Battery reserve", capacity_kw=100.0, dispatch_kw=30.0, status="powered")
    ];
    names = ["Medical centre", "Data centre", "Campus housing", "Research lab", "Water station", "Lecture halls", "Emergency hub", "Network core", "Sports centre"];
    demands = [50.0, 40.0, 30.0, 50.0, 40.0, 30.0, 10.0, 10.0, 10.0];
    loads: list[LoadView] = [];
    lines: list[LineView] = [];
    for (i, name) in enumerate(names) {
        demand = demands[i];
        affected = fault and i < 3 and not line_fault;
        disconnected = line_fault and i == 0 and not recovered;
        served = demand;
        status = "powered";
        if affected and i > 0 { served = 0.0; status = "unserved"; }
        if affected and i == 1 { served = 10.0; status = "partial"; }
        if recovered and affected and not limited { served = demand; status = "rerouted"; }
        if recovered and affected and limited and i == 2 { status = "shed"; }
        if disconnected { served = 0.0; status = "unserved"; }
        if recovered and line_fault and i == 0 { status = "rerouted"; }
        load_id = "LOAD-" + str(i + 1);
        loads.append(LoadView(id=load_id, name=name, demand_kw=demand, served_kw=served, tier=i % 3 + 1, status=status));
        lines.append(LineView(id="LINE-" + str(i + 1), from_id=sources[i // 3].id, to_id=load_id, capacity_kw=80.0, transfer_kw=0.0 if line_fault and i == 0 else served, faulted=line_fault and i == 0, switch_closed=True, switch_id="SW-" + str(i + 1)));
    }
    lines.append(LineView(id="TIE-AB", from_id="SRC-B", to_id="SRC-A", capacity_kw=80.0, transfer_kw=60.0 if recovered and not limited and not line_fault else 0.0, faulted=False, switch_closed=recovered and not limited, switch_id="SW-TIE"));
    lines.append(LineView(id="ALT-MED", from_id="SRC-A", to_id="LOAD-1", capacity_kw=60.0, transfer_kw=50.0 if recovered and line_fault else 0.0, faulted=False, switch_closed=recovered and line_fault, switch_id="SW-ALT"));
    unmet = 0.0;
    shed = 0.0;
    for load in loads {
        unmet += load.demand_kw - load.served_kw;
        if load.status == "shed" { shed += load.demand_kw; }
    }
    if line_fault { sources[0].dispatch_kw = 120.0 if recovered else 70.0; }
    metrics = MetricsView(critical_served_pct=100.0 if not line_fault or recovered else 100.0 * 60.0 / 110.0, shed_kw=shed, unmet_kw=unmet, available_capacity_kw=capacity_a + capacity_b + 100.0, dispatch_kw=270.0 - unmet, active_faults=1 if fault else 0);
    return GridView(version=0 if not fault else 1 if not recovered else 2, sources=sources, loads=loads, lines=lines, faults=[scenario] if fault else [], metrics=metrics);
}

def:pub preview_events(stage: str) -> list[EventView] {
    if stage == "baseline" { return []; }
    return [EventView(run_id="preview", sequence=1, actor="Preview", kind="sample", message="Fixed UI snapshot loaded. No agents ran and no plan was validated.")];
}

def:pub preview_recovery(scenario: str) -> RecoveryView {
    before = preview_grid("fault", scenario).metrics;
    after = preview_grid("recovered", scenario).metrics;
    return RecoveryView(run_id="preview", outcome="infeasible" if scenario == "insufficient_backup" else "complete", mode="preview",
        summary="Illustrative display data only. This snapshot is not evidence of a simulation, validation, or AI recovery run.", before=before, after=after, applied_action_count=0);
}
