"""Figma evidence cards populated only by canonical completed run records."""
sv import from ..shared.contracts { AgentEvent, RecoveryResult }
import from .ConsoleEvidence { ConsoleActivity }
import from .console_styles { s, colors }
import from .console_format { number as kw }

def:pub execution_label(mode: str) -> str {
    if mode == "primary_ai" { return "Primary AI"; }
    if mode == "backup_ai" { return "Backup AI"; }
    if mode == "deterministic" { return "Deterministic fallback"; }
    return "No committed mode";
}

def:pub outcome_label(outcome: str) -> str {
    if outcome == "recovered" { return "Recovery verified"; }
    if outcome == "partial" { return "Partial recovery"; }
    if outcome == "infeasible" { return "Critical demand remains unmet"; }
    if outcome == "no_action" { return "No new actions applied"; }
    return "No recovery applied";
}

def:pub RecoveryActivity(events: list[AgentEvent], result: RecoveryResult | None, pending: bool, preview: bool) -> JsxElement {
    if preview or (result is None and not pending) { return <ConsoleActivity preview={preview}/>; }
    return <section id="activity" style={{**s("panel"), "gap": 4, "minHeight": 492}} aria-labelledby="activity-title">
        <div style={s("row")}><h2 id="activity-title" style={s("sectionTitle")}>Agent activity</h2><span style={{**s("pill"), "background": colors["amberTint"] if pending else colors["tealTint"]}}>{"Awaiting result" if pending else execution_label(str(result.execution_mode)) if result else "No run"}</span></div>
        <p id="run-identity" style={{**s("mono"), "overflowWrap": "anywhere"}}>{"Recovery requested · awaiting server result" if pending else "RUN " + result.run_id if result else "No run"}</p>
        {if pending {
            <div key="pending" style={{**s("event"), "flex": 1}} role="status"><h3 style={s("strong")}>The server is processing recovery.</h3><p style={s("small")}>Confirmed decisions appear together when the run finishes. No intermediate agent events have been received.</p><p style={s("small")}>Keep this console open. Grid controls are paused until the request finishes.</p></div>;
        } else {
            <ol key="events" id="agent-events" aria-label="Ordered agent evidence" tabIndex={0} style={{"listStyle": "none", "margin": 0, "padding": 0, "maxHeight": 332, "overflowY": "auto", "overflowWrap": "anywhere"}}>
                {for event in events {
                    tone = "faultTint" if str(event.outcome) in ["rejected", "error"] else "greenTint" if str(event.outcome) == "accepted" else "blueTint" if str(event.outcome) == "applied" else "amberTint" if str(event.kind) in ["revision", "fallback"] else "surface";
                    <li key={event.sequence} data-sequence={event.sequence} data-actor={str(event.actor)} data-outcome={str(event.outcome)} style={{**s("event"), "borderRadius": 8, "background": colors[tone], "marginBottom": 4}}><h3 style={{**s("strong"), "textTransform": "capitalize"}}>{str(event.sequence) + " · " + str(event.actor) + " · " + str(event.kind) + " · " + str(event.outcome)}</h3><p style={s("small")}>{event.summary}</p>{if event.evidence { <details key="evidence"><summary style={{**s("small"), "cursor": "pointer", "padding": "8px 0"}}>Evidence</summary><p style={{**s("small"), "whiteSpace": "pre-wrap"}}>{event.evidence}</p></details>; }}</li>;
                }}
            </ol>;
        }}
        <div style={{**s("approval"), "marginTop": "auto"}}><p style={{**s("strong"), "color": colors["tealStrong"]}}>AI proposes. Code verifies.</p><p style={s("small")}>Only committed actions are reported as applied.</p></div>
    </section>;
}

def:pub RecoveryIncident(result: RecoveryResult) -> JsxElement {
    before = result.before_metrics; after = result.after_metrics;
    critical_before = kw(before.critical_preserved_pct) + "%" if before.critical_preserved_pct is not None else "N/A";
    critical_after = kw(after.critical_preserved_pct) + "%" if after.critical_preserved_pct is not None else "N/A";
    return <section id="incident" style={{**s("evidence"), "overflowWrap": "anywhere"}} aria-labelledby="incident-title">
        <h2 id="incident-title" style={s("strong")}>Incident account</h2><p id="incident-summary" style={s("small")}>{result.incident_summary}</p>
        <div><span id="execution-mode" style={s("pill")}>{execution_label(str(result.execution_mode))}</span></div>
        {if result.failure_reason { <p key="failure" id="recovery-failure" style={{**s("small"), "color": colors["fault"]}}>{result.failure_reason}</p>; }}
        <table id="run-metrics" style={s("table")}><caption style={{**s("tiny"), "textAlign": "left"}}>Server-reported run measurements</caption><thead><tr><th scope="col" style={s("th")}>Measure</th><th scope="col" style={s("th")}>Before</th><th scope="col" style={s("th")}>After</th></tr></thead><tbody>
            {for row in [("Critical served", critical_before, critical_after), ("Served", kw(before.served_kw) + " kW", kw(after.served_kw) + " kW"), ("Unmet", kw(before.unmet_kw) + " kW", kw(after.unmet_kw) + " kW"), ("Deliberately shed", kw(before.shed_kw) + " kW", kw(after.shed_kw) + " kW")] { <tr key={row[0]}><th scope="row" style={{**s("td"), "fontWeight": 400}}>{row[0]}</th><td style={s("td")}>{row[1]}</td><td style={s("td")}>{row[2]}</td></tr> }}
        </tbody></table>
        <p style={s("tiny")}>{str(result.proposal_count) + " proposals · " + str(result.revision_count) + " revisions · " + str(result.elapsed_ms) + " ms server elapsed"}</p>
        <details><summary style={s("summary")}>{str(len(result.applied_actions)) + " committed actions"}</summary><ul style={{"margin": 0, "paddingLeft": 20}}>{for action in result.applied_actions { <li key={action.target_id} style={s("small")}>{str(action.action_type) + " · " + action.target_id}</li> }}</ul>{if not result.applied_actions { <p key="none" style={s("small")}>This run committed no actions.</p>; }}</details>
    </section>;
}

def:pub RecoveryBanner(result: RecoveryResult) -> JsxElement {
    outcome = str(result.outcome); success = outcome == "recovered"; partial = outcome == "partial";
    return <div id="recovery-outcome" role="status" style={{**s("banner"), "flexWrap": "wrap", "background": colors["greenTint"] if success else colors["amberTint"] if partial else colors["faultTint"] if outcome in ["failed", "infeasible"] else colors["tealTint"]}}><span style={s("pill")}>{outcome_label(outcome)}</span><div><h2 style={s("strong")}>{"Server-verified service restored." if success else "Critical demand preserved; some demand remains unmet." if partial else "This run committed no new recovery actions."}</h2><p style={s("small")}>The physical fault remains active. Inspect the measured outcome and agent evidence below.</p></div></div>;
}
