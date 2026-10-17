"""Live simulator shell with an explicitly separate fixed-example mode."""
import from react { useMemo, useEffect }
sv import from ..shared.contracts { GraphState }
import from .console_styles { s, colors }
import from .console_browser { use_console_layout, use_snapshot_motion }
import from .ConsoleSidebar { ConsoleSidebar }
import from .ConsoleMetrics { ConsoleMetrics }
import from .ConsoleNetwork { ConsoleNetwork }
import from .ConsoleInspector { ConsoleInspector }
import from .ConsoleEvidence { ConsoleActivity, ConsoleSupply, ConsoleIncident }
import from .ConsoleControls { ConsoleControls, action_style }
import from .grid_client { read_live_grid, inject_live_fault, reset_live_grid }
import from .topology_examples { topology_example }

def:pub Dashboard() -> JsxElement {
    has liveGrid: GraphState | None = None, previewMode: bool = False,
        example: str = "baseline", scenario: str = "FAULT-SOURCE-A", selected: str = "SRC-A",
        busy: bool = True, uncertain: bool = False, error: str = "",
        phase: str = "Connecting to the simulation…", skipFocused: bool = False;
    has mountedRef: Ref[bool] = Ref(False), epochRef: Ref[int] = Ref(0), lockRef: Ref[bool] = Ref(False);
    mode = use_console_layout();
    displayExample = useMemo(lambda { return topology_example(example); }, [example]) as GraphState;
    grid = displayExample if previewMode else liveGrid;
    faulted = bool(grid and len(grid.active_fault_ids) > 0);
    use_snapshot_motion(example if previewMode else str(liveGrid.revision) if liveGrid else "loading");
    columns = s("columns") if mode == 2 else {"display": "grid", "gridTemplateColumns": "minmax(0, 1fr)", "gap": 24};

    def inspect(identity: str) -> None;
    def choose_scenario(identity: str) -> None;
    def switch_mode(preview: bool) -> None;
    async def operate(operation: str) -> None;

    useEffect(lambda {
        mountedRef.current = True;
        operate("read");
        return lambda {
            mountedRef.current = False;
            epochRef.current = (epochRef.current or 0) + 1;
            lockRef.current = False;
        };
    }, []);

    return <div style={{**s("app"), "flexDirection": "row" if mode > 0 else "column"}}>
        <a href="#workspace" onFocus={lambda (e: FocusEvent) { skipFocused = True; }} onBlur={lambda (e: FocusEvent) { skipFocused = False; }} style={{"position": "fixed", "top": 8, "left": 8, "zIndex": 10, "padding": 12, "background": "white", "color": colors["tealStrong"], "transform": "translateY(0)" if skipFocused else "translateY(-200%)"}}>Skip to workspace</a>
        <ConsoleSidebar compact={mode == 0} scenario={scenario} disabled={busy or previewMode or faulted} onScenario={choose_scenario}/>
        <div style={s("main")}>
            <header style={{**s("header"), "padding": "12px 16px" if mode == 0 else "12px 32px"}}><div><p style={s("mono")}>WORKSPACE / RECOVERY CONSOLE</p><p style={s("tiny")}>Fictional microgrid · deterministic approval</p></div><div style={s("row")}><span style={s("pill")}>{"Fixed preview" if previewMode else "Live simulation"}</span><span style={s("mono")}>{grid.grid_id + " · revision " + str(grid.revision) if grid else "Connecting…"}</span></div></header>
            <main id="workspace" tabIndex={-1} aria-busy={busy} style={{**s("content"), "padding": "24px 16px" if mode == 0 else "24px 32px"}}>
                <div style={s("row")}><div><h1 style={s("title")}>See the grid. Understand every decision.</h1><p style={s("small")}>Start with a healthy network, then introduce a repeatable fault.</p></div><div style={{"display": "flex", "gap": 8}} role="group" aria-label="Data mode"><button id="live-mode" aria-pressed={not previewMode} disabled={busy} style={action_style(busy, previewMode)} onClick={lambda (e: MouseEvent) { switch_mode(False); }}>Live simulation</button><button id="preview-mode" aria-pressed={previewMode} disabled={busy} style={action_style(busy, not previewMode)} onClick={lambda (e: MouseEvent) { switch_mode(True); }}>Fixed previews</button></div></div>
                <ConsoleControls scenario={scenario} preview={previewMode} busy={busy} available={liveGrid is not None} faulted={faulted} uncertain={uncertain} phase={phase if not previewMode else "Fixed display examples · no server changes"} onScenario={choose_scenario} onInject={lambda { operate("inject"); }} onReset={lambda { operate("reset"); }} onRefresh={lambda { operate("read"); }}/>
                {if error and not previewMode { <div key="error" id="grid-error" role="alert" style={{**s("evidence"), "minHeight": 0, "borderColor": colors["fault"]}}><strong>Live state could not be confirmed.</strong><p style={s("small")}>{error}</p><p style={s("small")}>Showing the last confirmed state if available. Refresh live state before another change.</p></div>; }}
                <ConsoleMetrics grid={grid} preview={previewMode}/>
                <div id="snapshot-status" style={{**s("banner"), "background": colors["faultTint"] if faulted else colors["tealTint"]}} role="status"><span style={s("pill")}>{"Preview" if previewMode else "Updating" if busy else "Unconfirmed" if uncertain else "Fault active" if faulted else "Ready" if grid else "Not connected"}</span><div><h2 style={s("strong")}>{"Fixed display example" if previewMode else "Live state is awaiting confirmation." if uncertain or grid is None else "A simulated fault is active." if faulted else "Your microgrid is ready to test."}</h2><p style={s("small")}>{"No simulator, validator, or agents run in preview mode." if previewMode else "Fault injection and reset update the simulator. Recovery agents are not connected to this screen yet."}</p>{if grid and len(grid.active_fault_ids) > 0 { <p key="fault-retained" style={{**s("small"), "color": colors["fault"]}}>{"Fault retained: " + grid.active_fault_ids[0] + ". Rerouting does not repair the physical component."}</p>; }}</div></div>
                {if grid {
                    <div key="network-row" style={columns}><ConsoleNetwork grid={grid} example={example} selected={selected} preview={previewMode} onSelect={inspect}/><ConsoleActivity preview={previewMode}/></div>;
                    <div key="supply-row" style={columns}><ConsoleSupply grid={grid}/><ConsoleIncident grid={grid} baseline={not faulted} preview={previewMode}/></div>;
                } else {
                    <section key="waiting" style={s("panel")} aria-label="Waiting for live grid"><h2 style={s("sectionTitle")}>Waiting for the server grid</h2><p style={s("small")}>Topology and supply measurements appear after a successful read. No sample numbers are substituted.</p></section>;
                }}
                <footer style={s("tiny")}>{"FIXED PREVIEW · Recovery examples are illustrative, not a live model run." if previewMode else "LIVE SIMULATION · Server-reported grid state · Shared guest simulation on this local console · No recovery run started."}</footer>
                {if previewMode { <section key="preview-tools" id="preview-tools" style={s("evidence")}><label htmlFor="topology-example">Display example</label><select id="topology-example" value={example} style={s("select")} onChange={lambda (e: ChangeEvent) { example = e.target.value; }}><option value="baseline">Healthy baseline</option><option value="source_fault">Source capacity reduced</option><option value="line_fault">Physical line fault</option><option value="rerouted">Rerouted service with shedding</option></select></section>; }}
                {if grid { <ConsoleInspector key="inspection" grid={grid} selected={selected} onSelect={lambda (identity: str) { selected = identity; }}/>; }}
            </main>
        </div>
    </div>;
}
