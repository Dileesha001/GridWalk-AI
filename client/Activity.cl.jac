import from .models { EventView, RecoveryView, critical_label, kw, mode_label }

def:pub Activity(events: list[EventView], phase: str, preview: bool) -> JsxElement {
    return <section className="panel activity-panel" aria-labelledby="activity-title"><div className="panel-heading"><div><p className="eyebrow">RECOVERY WORKFLOW</p><h2 id="activity-title">Agent activity</h2></div><span className="tag">{str(len(events)) + " events"}</span></div>
        <p className="workflow">Monitor → Planner → Validator → Auditor</p>
        <p className="activity-status" role="status">{phase}</p>
        {if len(events) == 0 {
            <div className="empty"><h3>{"No agents run in preview" if preview else "Waiting for a recovery run"}</h3><p>{"Sample snapshots demonstrate display states only." if preview else "Observations and validation evidence will appear here."}</p></div>;
        } else {
            <ol className="timeline">{for item in events { <li key={item.run_id + ":" + str(item.sequence)}><div className="event-marker">{str(item.sequence)}</div><div><div className="event-heading"><strong>{item.actor}</strong><span className="tag">{item.kind}</span></div><p>{item.message}</p></div></li> }}</ol>;
        }}
    </section>;
}

def:pub Incident(result: RecoveryView | None) -> JsxElement {
    return <section className="panel incident-panel" aria-labelledby="incident-title"><div className="panel-heading"><div><p className="eyebrow">MEASURED OUTCOME</p><h2 id="incident-title">Incident account</h2></div><span className="tag">{mode_label(result.mode) if result else "No result"}</span></div>
        {if result {
            <h3>{"Unmet demand remains" if result.outcome == "infeasible" else "Recovery failed" if result.outcome == "error" else "Recovery complete"}</h3>;
            <p>{result.summary}</p>;
            <div className="table-scroll"><table><caption>{"Sample comparison — not a measured run" if result.mode == "preview" else "Server-reported before and after"}</caption><thead><tr><th>Metric</th><th>Before</th><th>After</th></tr></thead><tbody><tr><td>Critical demand served</td><td>{critical_label(result.before.critical_served_pct)}</td><td>{critical_label(result.after.critical_served_pct)}</td></tr><tr><td>Shed demand</td><td>{kw(result.before.shed_kw) + " kW"}</td><td>{kw(result.after.shed_kw) + " kW"}</td></tr><tr><td>Total unmet demand</td><td>{kw(result.before.unmet_kw) + " kW"}</td><td>{kw(result.after.unmet_kw) + " kW"}</td></tr></tbody></table></div>;
            <p className="map-note">{"Run " + result.run_id + " · Applied actions: " + str(result.applied_action_count)}</p>;
        } else { <p className="muted">A completed run will show the execution mode, incident summary, and before/after metrics here.</p>; }}
    </section>;
}
