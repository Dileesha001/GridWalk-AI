sv import from ..shared.contracts { GraphState }
import from .console_styles { s, colors }
import from .console_format { number as kw }

def:pub ConsoleMetrics(grid: GraphState) -> JsxElement {
    m = grid.metrics;
    return <section style={s("metrics")} aria-label="Fixed snapshot metrics">
        <article style={s("criticalMetric") if m.critical_preserved_pct == 100 else s("metric")}><p style={s("small")}>Critical demand served</p><strong style={{**s("metricValue"), "color": colors["green"] if m.critical_preserved_pct == 100 else colors["fault"]}}>{kw(m.critical_preserved_pct) + "%" if m.critical_preserved_pct is not None else "N/A"}</strong><p style={s("tiny")}>Tier 1 demand protected</p></article>
        <article style={s("metric")}><p style={s("small")}>Demand served</p><strong style={s("metricValue")}>{kw(m.served_kw) + " kW"}</strong><p style={s("tiny")}>{"of " + kw(m.total_demand_kw) + " kW total demand"}</p></article>
        <article style={s("metric")}><p style={s("small")}>Unmet demand</p><strong style={s("metricValue")}>{kw(m.unmet_kw) + " kW"}</strong><p style={s("tiny")}>{kw(m.shed_kw) + " kW deliberately shed"}</p></article>
        <article style={s("metric")}><p style={s("small")}>Active physical faults</p><strong style={s("metricValue")}>{str(m.active_fault_count)}</strong><p style={s("tiny")}>Rerouting does not repair a fault</p></article>
    </section>;
}
