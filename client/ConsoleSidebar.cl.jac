import from .console_styles { s, colors }
import from .ConsoleControls { scenarios }

def:pub ConsoleSidebar(compact: bool, scenario: str, disabled: bool, onScenario: Callable[[str], None]) -> JsxElement {
    return <aside style={s("sidebar") if not compact else {"background": colors["nav"], "color": "white", "padding": "16px 20px", "display": "flex", "alignItems": "center", "justifyContent": "space-between", "gap": 16}} aria-label="Console navigation">
        <div><p style={s("brand")}>GridWalk</p><p style={s("navSmall")}>AI recovery console</p></div>
        <a href="#workspace" style={s("navActive")}>{if compact { <span key="compact">Recovery console</span>; } else { <span key="expanded">Recovery<br/>console</span>; }}</a>
        {if not compact {
            <nav key="workflow" aria-label="Recovery workflow"><p style={s("navHeading")}>THE WORKFLOW</p>
                <a href="#activity" style={s("navItem")}>01  Monitor<p style={s("navSmall")}>Detect the fault</p></a>
                <a href="#activity" style={s("navItem")}>02  Planner<p style={s("navSmall")}>Propose a plan</p></a>
                <a href="#activity" style={s("navItem")}>03  Auditor<p style={s("navSmall")}>Explain the result</p></a>
            </nav>;
            <nav key="scenarios" aria-label="Simulation scenarios"><p style={s("navHeading")}>TEST SCENARIOS</p>{for option in scenarios { <button key={option[0]} aria-pressed={scenario == option[0]} disabled={disabled} style={{**s("navScenario"), "background": colors["tealStrong"] if scenario == option[0] else "transparent", "opacity": 0.6 if disabled else 1, "cursor": "not-allowed" if disabled else "pointer"}} onClick={lambda (e: MouseEvent) { onScenario(option[0]); }}>{option[1]}</button> }}<p style={s("navSmall")}>Select here; inject with the fault control.</p></nav>;
            <div key="simulation" style={{"marginTop": "auto", "paddingTop": 48}}><p style={s("navSmall")}>Simulation only</p><p style={s("navSmall")}>Built with Jac</p></div>;
        }}
    </aside>;
}
