"""Figma recovery console. All readings are explicit fixed display snapshots."""
import from react { useMemo }
sv import from ..shared.contracts { GraphState }
import from .console_styles { s, colors }
import from .console_browser { use_console_layout, use_snapshot_motion }
import from .ConsoleSidebar { ConsoleSidebar }
import from .ConsoleMetrics { ConsoleMetrics }
import from .ConsoleNetwork { ConsoleNetwork }
import from .ConsoleInspector { ConsoleInspector }
import from .ConsoleEvidence { ConsoleActivity, ConsoleSupply, ConsoleIncident }
import from .topology_examples { topology_example }

def:pub Dashboard() -> JsxElement {
    has example: str = "baseline", selected: str = "SRC-A", skipFocused: bool = False;
    mode = use_console_layout();
    grid = useMemo(lambda { return topology_example(example); }, [example]) as GraphState;
    use_snapshot_motion(example);
    columns = s("columns") if mode == 2 else {"display": "grid", "gridTemplateColumns": "minmax(0, 1fr)", "gap": 24};

    def inspect(identity: str) -> None {
        selected = identity;
        browser: any = window;
        details = browser.document.getElementById("component-inspection");
        details.open = True;
        browser.document.getElementById("topology-component").focus();
    }

    def preview(kind: str) -> None {
        example = kind;
        browser: any = window;
        browser.document.getElementById("preview-tools").open = True;
        browser.document.getElementById("snapshot-status").scrollIntoView({"block": "center"});
    }

    return <div style={{**s("app"), "flexDirection": "row" if mode > 0 else "column"}}>
        <a href="#workspace" onFocus={lambda e: FocusEvent { skipFocused = True; }} onBlur={lambda e: FocusEvent { skipFocused = False; }} style={{"position": "fixed", "top": 8, "left": 8, "zIndex": 10, "padding": 12, "background": "white", "color": colors["tealStrong"], "transform": "translateY(0)" if skipFocused else "translateY(-200%)"}}>Skip to workspace</a>
        <ConsoleSidebar compact={mode == 0} onPreview={preview}/>
        <div style={s("main")}>
            <header style={{**s("header"), "padding": "12px 16px" if mode == 0 else "12px 32px"}}><div><p style={s("mono")}>WORKSPACE / RECOVERY CONSOLE</p><p style={s("tiny")}>Fictional microgrid · deterministic approval</p></div><div style={s("row")}><span style={s("pill")}>Design preview</span><span style={s("mono")}>12 buses · lossless kW</span></div></header>
            <main id="workspace" tabIndex={-1} style={{**s("content"), "padding": "24px 16px" if mode == 0 else "24px 32px"}}>
                <div style={s("row")}><div><h1 style={s("title")}>See the grid. Understand every decision.</h1><p style={s("small")}>Start with a healthy network, then introduce a repeatable fault.</p></div><div style={{"display": "flex", "gap": 12, "flexWrap": "wrap"}}><button style={s("button")} disabled={True} aria-describedby="controls-note">Reset</button><button style={s("button")} disabled={True} aria-describedby="controls-note">Inject source fault</button></div></div>
                <ConsoleMetrics grid={grid}/>
                <div id="snapshot-status" style={s("banner")} role="status"><span style={s("healthyPill") if example == "baseline" else s("pill")}>{"Ready" if example == "baseline" else "Preview"}</span><div><h2 style={s("strong")}>{"Your microgrid is ready to test." if example == "baseline" else "You are viewing a fixed display example."}</h2><p style={s("small")}>{"All demand is served. Choose a snapshot below to explore a disruption." if example == "baseline" else "No simulator, validator, or agents run when you change the snapshot."}</p>{if len(grid.active_fault_ids) > 0 { <p key="fault-retained" style={{**s("small"), "color": colors["fault"]}}>{"Fault retained: " + grid.active_fault_ids[0] + ". Rerouting does not repair the physical component."}</p>; }}</div></div>
                <div style={columns}><ConsoleNetwork grid={grid} example={example} selected={selected} onSelect={inspect}/><ConsoleActivity/></div>
                <div style={columns}><ConsoleSupply grid={grid}/><ConsoleIncident grid={grid} baseline={example == "baseline"}/></div>
                <footer style={s("tiny")}>DESIGN PREVIEW · Fixture baseline and pre-recovery readings are documented. Recovery examples are illustrative, not a live model run.</footer>
                <details id="preview-tools" style={s("evidence")}><summary style={s("summary")}>Explore fixed display snapshots</summary><label htmlFor="topology-example" style={{**s("small"), "display": "block", "marginBottom": 8}}>Display example</label><select id="topology-example" value={example} style={s("select")} onChange={lambda e: ChangeEvent { example = e.target.value; }}><option value="baseline">Healthy baseline</option><option value="source_fault">Source capacity reduced</option><option value="line_fault">Physical line fault</option><option value="rerouted">Rerouted service with shedding</option></select><p id="controls-note" style={{**s("small"), "marginTop": 12}}>Live fault injection, recovery, and reset are unavailable until simulation integration is complete. The snapshot selector only changes display data. Backup shortage is reserved for the live scenario controls.</p></details>
                <ConsoleInspector grid={grid} selected={selected} onSelect={lambda identity: str { selected = identity; }}/>
            </main>
        </div>
    </div>;
}
