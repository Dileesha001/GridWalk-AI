import from .models { GridView, critical_label, kw }

def:pub Metrics(grid: GridView | None) -> JsxElement {
    return <section className="metric-grid" aria-label="Server metrics">
        <article className="metric"><p>Critical demand served</p><strong>{critical_label(grid.metrics.critical_served_pct) if grid else "—"}</strong><span>Tier 1 demand in kW</span></article>
        <article className="metric"><p>Shed demand</p><strong>{kw(grid.metrics.shed_kw) if grid else "—"}<small> kW</small></strong><span>{"Unmet: " + kw(grid.metrics.unmet_kw) + " kW" if grid else "Awaiting server state"}</span></article>
        <article className="metric"><p>Available capacity</p><strong>{kw(grid.metrics.available_capacity_kw) if grid else "—"}<small> kW</small></strong><span>{"Dispatch: " + kw(grid.metrics.dispatch_kw) + " kW" if grid else "Capacity differs from dispatch"}</span></article>
        <article className="metric"><p>Active physical faults</p><strong>{str(grid.metrics.active_faults) if grid else "—"}</strong><span>Rerouting does not repair a fault</span></article>
    </section>;
}
