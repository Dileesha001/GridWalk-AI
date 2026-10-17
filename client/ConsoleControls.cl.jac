import from .console_styles { s, colors }

glob:pub scenarios: list[tuple[str, str]] = [("FAULT-SOURCE-A", "Source capacity"), ("FAULT-LINE-A-H", "Line failure"), ("FAULT-INSUFFICIENT-BACKUP", "Backup shortage")];

def:pub action_style(disabled: bool, secondary: bool = False) -> dict[str, object] {
    return {**s("button"), "opacity": 0.55 if disabled else 1, "cursor": "not-allowed" if disabled else "pointer",
        "background": colors["surface"] if secondary else colors["tealStrong"], "color": colors["text"] if secondary else "white",
        "borderColor": colors["border"] if secondary else colors["tealStrong"]};
}

def:pub ConsoleControls(scenario: str, preview: bool, busy: bool, available: bool, faulted: bool, uncertain: bool, recoveryReady: bool, phase: str,
    onScenario: Callable[[str], None], onInject: Callable[[], None], onReset: Callable[[], None], onRefresh: Callable[[], None], onRecover: Callable[[], None]) -> JsxElement {
    blocked = busy or preview or not available or uncertain;
    return <section aria-label="Simulation controls" style={{"display": "flex", "gap": 12, "flexDirection": "column", "minWidth": 0}}>
        <div style={s("row")}><div><label htmlFor="fault-scenario" style={{**s("small"), "display": "block"}}>Fault scenario</label><select id="fault-scenario" value={scenario} disabled={busy or preview or faulted} style={s("select")} onChange={lambda (e: ChangeEvent) { onScenario(e.target.value); }}>{for option in scenarios { <option key={option[0]} value={option[0]}>{option[1]}</option> }}</select></div>
            <div style={{"display": "flex", "gap": 12, "flexWrap": "wrap"}}><button id="refresh-grid" style={action_style(busy or preview, True)} disabled={busy or preview} onClick={lambda (e: MouseEvent) { onRefresh(); }}>Refresh live state</button><button id="reset-grid" style={action_style(blocked, True)} disabled={blocked} onClick={lambda (e: MouseEvent) { onReset(); }}>Reset</button><button id="inject-fault" style={action_style(blocked or faulted)} disabled={blocked or faulted} onClick={lambda (e: MouseEvent) { onInject(); }}>Inject fault</button><button id="run-recovery" style={action_style(blocked or not faulted or not recoveryReady)} disabled={blocked or not faulted or not recoveryReady} aria-describedby="controls-note" onClick={lambda (e: MouseEvent) { onRecover(); }}>Run recovery</button></div>
        </div>
        <p id="controls-note" style={s("small")}>{"Display examples do not change the simulator. Return to Live simulation to enable controls." if preview else "Recovery requests a server-side AI proposal. Only a deterministically approved plan can change service. Reset before injecting a different fault."}</p>
        <p role="status" aria-live="polite" style={s("small")}>{phase}</p>
    </section>;
}
