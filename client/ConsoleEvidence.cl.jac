sv import from ..shared.contracts { GraphState }
import from .console_styles { s, colors }
import from .console_format { number as kw }

def:pub ConsoleActivity() -> JsxElement {
    roles: list[tuple[str, str]] = [
        ("01  Monitor · ready", "Waiting for a fault. No monitoring agent has run."),
        ("02  Planner · waiting", "Will propose recovery after the Monitor reports a fault."),
        ("03  Validator · not run", "Checks paths, capacity and critical-load policy."),
        ("04  Auditor · waiting", "Will summarize the committed recovery result.")
    ];
    return <section id="activity" style={{**s("panel"), "gap": 4, "minHeight": 492}} aria-labelledby="activity-title">
        <div style={s("row")}><h2 id="activity-title" style={s("sectionTitle")}>Agent activity</h2><span style={s("pill")}>No run</span></div>
        <p style={s("mono")}>DESIGN PREVIEW · no live events</p>
        {for role in roles { <div key={role[0]} style={s("event")}><h3 style={s("strong")}>{role[0]}</h3><p style={s("small")}>{role[1]}</p></div> }}
        <div style={s("approval")}><p style={{**s("strong"), "color": colors["tealStrong"]}}>AI proposes. Code verifies.</p><p style={s("small")}>3 agents + deterministic validation.</p></div>
    </section>;
}

def:pub ConsoleSupply(grid: GraphState) -> JsxElement {
    return <section style={s("evidence")} aria-labelledby="supply-title"><h2 id="supply-title" style={s("strong")}>Source capacity &amp; dispatch</h2>
        <div style={s("scroll")} tabIndex={0} aria-label="Source supply table"><table style={s("table")}><thead><tr>{for label in ["SOURCE", "CAPACITY", "DISPATCH", "STATUS"] { <th key={label} scope="col" style={s("th")}>{label}</th> }}</tr></thead>
            <tbody>{for source in grid.sources { <tr key={source.bus_id}><th scope="row" style={{**s("td"), "fontWeight": 400}}>{source.bus_id + " / " + source.label}</th><td style={s("td")}>{kw(source.capacity_kw) + " kW"}</td><td style={s("td")}>{kw(source.dispatched_kw) + " kW"}</td><td style={{**s("td"), "color": colors["green"] if source.status == "online" else colors["amber"]}}>{source.status}</td></tr> }}</tbody>
        </table></div>
    </section>;
}

def:pub ConsoleIncident(grid: GraphState, baseline: bool) -> JsxElement {
    return <section id="incident" style={s("evidence")} aria-labelledby="incident-title"><h2 id="incident-title" style={s("strong")}>{"A clear starting point" if baseline else "Inspect the fixed snapshot"}</h2>
        <p style={s("small")}>{"105 kW critical demand · 205 kW total demand. Reserve supply already includes local commitments." if baseline else kw(grid.metrics.unmet_kw) + " kW unmet · " + kw(grid.metrics.shed_kw) + " kW deliberately shed. This display example is not a recovery result."}</p>
        <div><span style={s("pill")}>{"No action needed" if baseline else "No live recovery result"}</span></div>
    </section>;
}
