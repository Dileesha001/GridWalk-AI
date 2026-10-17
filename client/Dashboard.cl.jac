"""Initial GridWalk dashboard shell. Server data will be wired here."""

def:pub Dashboard -> JsxElement {
    return
        <main style={{"maxWidth": "960px", "margin": "2rem auto", "padding": "0 1rem", "fontFamily": "system-ui, sans-serif"}}>
            <h1>GridWalk AI</h1>
            <p>Microgrid recovery decision-support simulator</p>
            <section>
                <h2>Simulation</h2>
                <p>Graph state, fault controls, and recovery results will appear here.</p>
            </section>
            <section>
                <h2>Agent activity</h2>
                <p>Monitor, Planner, validation, and Auditor events will appear here.</p>
            </section>
        </main>;
}
