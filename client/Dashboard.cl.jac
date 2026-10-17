"""Step 4: responsive layout only. Controls and live integration are not enabled."""

import "./dashboard.css";
import from .ShellPanel { ShellPanel, EmptyState }

def:pub Dashboard -> JsxElement {
    return <div className="dashboard">
        <a className="skip-link" href="#workspace">Skip to workspace</a>
        <header className="app-header">
            <a className="brand" href="#workspace" aria-label="GridWalk AI workspace"><span className="brand-symbol" aria-hidden="true">G</span><span>GridWalk<span className="brand-ai"> AI</span></span></a>
            <nav aria-label="Workspace sections"><a href="#network">Network</a><a href="#activity">Activity</a><a href="#incident">Incident</a></nav>
            <span className="connection-status"><span aria-hidden="true"></span>Not connected</span>
        </header>
        <main id="workspace" tabIndex={-1}>
            <div className="page-heading"><div><p className="eyebrow">MICROGRID DECISION SUPPORT</p><h1>Grid recovery workspace</h1><p className="muted">Protect critical demand. Make every decision visible.</p></div><span className="workspace-label">SIMULATION CONSOLE <span>01</span></span></div>
            <div className="preview-notice" role="note"><strong>Layout preview</strong><p>No grid state or recovery run is loaded. Metrics and controls will become available as integration progresses.</p></div>
            <section className="metric-grid" aria-label="Recovery metrics">
                <article className="metric"><p>Critical demand served</p><strong aria-label="Not available">—</strong><span>Share of Tier 1 demand served</span></article>
                <article className="metric"><p>Shed / unmet demand</p><strong aria-label="Not available">— <small>/ — kW</small></strong><span>Deliberate shedding / all unserved demand</span></article>
                <article className="metric"><p>Available capacity</p><strong aria-label="Not available">— <small>kW</small></strong><span>Source capability, distinct from dispatch</span></article>
                <article className="metric"><p>Active physical faults</p><strong aria-label="Not available">—</strong><span>Rerouting does not repair a fault</span></article>
            </section>
            <div className="workspace-grid">
                <div id="network" className="network-column">
                    <ShellPanel eyebrow="NETWORK OVERVIEW" title="Microgrid topology" badge="Awaiting state">
                        <div className="topology-placeholder"><EmptyState title="Your microgrid will appear here" description="Inspect sources, prioritized loads, and the physical lines connecting them."/></div>
                        <div className="legend" aria-label="Planned grid status legend"><span><i className="powered" aria-hidden="true"></i>Powered</span><span><i className="fault" aria-hidden="true"></i>Fault</span><span><i className="shed" aria-hidden="true"></i>Shed</span><span><i className="rerouted" aria-hidden="true"></i>Rerouted</span></div>
                        <p className="panel-note">Fictional facilities · Simplified connectivity and lossless kW allocation</p>
                    </ShellPanel>
                </div>
                <aside className="right-column" aria-label="Scenario and agent workspace">
                    <ShellPanel eyebrow="SCENARIO CONTROLS" title="Test a disruption" badge="01–03">
                        <label htmlFor="scenario">Fault scenario</label>
                        <select id="scenario" disabled={True} aria-describedby="controls-note"><option>Source capacity reduction</option><option>Distribution line failure</option><option>Insufficient backup</option></select>
                        <p className="control-hint">Explore reserve transfers, alternate paths, and priority-aware shedding.</p>
                        <div className="control-buttons"><button className="button secondary" disabled={True} aria-describedby="controls-note"><span>01</span>Inject fault</button><button className="button primary" disabled={True} aria-describedby="controls-note"><span>02</span>Run recovery</button><button className="button subtle" disabled={True} aria-describedby="controls-note"><span>03</span>Reset simulation</button></div>
                        <p id="controls-note" className="panel-note">Controls are unavailable until a grid state is connected.</p>
                    </ShellPanel>
                    <div id="activity"><ShellPanel eyebrow="AGENT WORKFLOW" title="Agent activity" badge="No run"><p className="workflow">Monitor → Planner → Validator → Auditor</p><EmptyState title="No agent activity yet" description="Observations, proposals, and validation evidence will appear during a recovery run."/></ShellPanel></div>
                </aside>
            </div>
            <div id="incident" className="incident-section"><ShellPanel eyebrow="RECOVERY OUTCOME" title="Incident account" badge="No result"><div className="incident-empty"><span className="incident-mark" aria-hidden="true">—</span><div><h3>No recovery result yet</h3><p className="muted">The incident summary, execution mode, and before/after measurements will appear here.</p></div></div></ShellPanel></div>
            <footer><p>AI proposes. Deterministic code validates. The simulation applies.</p><p>Fictional simulation · Not physical grid control</p></footer>
        </main>
    </div>;
}
