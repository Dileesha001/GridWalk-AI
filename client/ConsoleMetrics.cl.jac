sv import from ..shared.contracts { GraphState }
import from .console_styles { s, colors }
import from .console_format { number as kw }

def:pub ConsoleMetrics(grid: GraphState | None, preview: bool = False) -> JsxElement {
    m = grid.metrics if grid else None;
    return <section aria-label={"Fixed snapshot metrics" if preview else "Live grid metrics"}>
        <div style={s("metrics")}>
            <article style={s("criticalMetric") if m and m.critical_preserved_pct == 100 else s("metric")}><p style={s("small")}>Critical demand served</p><strong style={{**s("metricValue"), "color": colors["green"] if m and m.critical_preserved_pct == 100 else colors["text"] if not m or m.critical_preserved_pct is None else colors["fault"]}}>{kw(m.critical_preserved_pct) + "%" if m and m.critical_preserved_pct is not None else "N/A" if m else "—"}</strong><p style={s("tiny")}>Tier 1 demand protected</p></article>
            <article style={s("metric")}><p style={s("small")}>Demand served</p><strong style={s("metricValue")}>{kw(m.served_kw) + " kW" if m else "—"}</strong><p style={s("tiny")}>{"of " + kw(m.total_demand_kw) + " kW total demand" if m else "Awaiting server state"}</p></article>
            <article style={s("metric")}><p style={s("small")}>Unmet demand</p><strong style={s("metricValue")}>{kw(m.unmet_kw) + " kW" if m else "—"}</strong><p style={s("tiny")}>{kw(m.shed_kw) + " kW deliberately shed" if m else "Awaiting server state"}</p></article>
            <article style={s("metric")}><p style={s("small")}>Active physical faults</p><strong style={s("metricValue")}>{str(m.active_fault_count) if m else "—"}</strong><p style={s("tiny")}>Rerouting does not repair a fault</p></article>
        </div>
        <p style={{**s("small"), "marginTop": 8}}>{("Preview · " if preview else "Server metrics · ") + "Available capacity " + kw(m.available_capacity_kw) + " kW · Dispatched " + kw(m.dispatched_kw) + " kW" if m else "Capacity and dispatch will appear after a confirmed read."}</p>
    </section>;
}
