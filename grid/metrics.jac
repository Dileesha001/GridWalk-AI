"""Server-derived summary metrics for a graph-state projection."""

import from shared.contracts { SourceView, LoadView, LineView, GridMetrics }

def compute_metrics(sources: list[SourceView], loads: list[LoadView],
                    lines: list[LineView], active_fault_ids: list[str]) -> GridMetrics {
    demand = sum([load.demand_kw for load in loads]);
    served = sum([load.served_kw for load in loads]);
    shed = sum([load.demand_kw - load.served_kw for load in loads if load.deliberately_shed]);
    critical_demand = sum([load.demand_kw for load in loads if load.tier == 1]);
    critical_served = sum([load.served_kw for load in loads if load.tier == 1]);
    critical_pct: float | None = None;
    if critical_demand > 0.0 { critical_pct = 100.0 * critical_served / critical_demand; }
    _ = lines;
    return GridMetrics(
        total_demand_kw=demand, served_kw=served, unmet_kw=demand - served,
        shed_kw=shed, available_capacity_kw=sum([source.capacity_kw for source in sources]),
        dispatched_kw=sum([source.dispatched_kw for source in sources]),
        critical_preserved_pct=critical_pct, active_fault_count=len(active_fault_ids)
    );
}
