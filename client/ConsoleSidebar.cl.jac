import from .console_styles { s }

def:pub ConsoleSidebar(compact: bool, onPreview: Callable[[str], None]) -> JsxElement {
    return <aside style={s("sidebar") if not compact else {"background": "#102b30", "color": "white", "padding": "16px 20px", "display": "flex", "alignItems": "center", "justifyContent": "space-between", "gap": 16}} aria-label="Console navigation">
        <div><p style={s("brand")}>GridWalk</p><p style={s("navSmall")}>AI recovery console</p></div>
        <a href="#workspace" style={s("navActive")}>{if compact { <span key="compact">Recovery console</span>; } else { <span key="expanded">Recovery<br/>console</span>; }}</a>
        {if not compact {
            <nav key="workflow" aria-label="Recovery workflow"><p style={s("navHeading")}>THE WORKFLOW</p>
                <a href="#activity" style={s("navItem")}>01  Monitor<p style={s("navSmall")}>Detect the fault</p></a>
                <a href="#activity" style={s("navItem")}>02  Planner<p style={s("navSmall")}>Propose a plan</p></a>
                <a href="#activity" style={s("navItem")}>03  Auditor<p style={s("navSmall")}>Explain the result</p></a>
            </nav>;
            <nav key="scenarios" aria-label="Preview scenarios"><p style={s("navHeading")}>TEST SCENARIOS</p><button style={s("navScenario")} onClick={lambda e: MouseEvent { onPreview("source_fault"); }}>Source capacity</button><button style={s("navScenario")} onClick={lambda e: MouseEvent { onPreview("line_fault"); }}>Line failure</button><button style={{**s("navScenario"), "opacity": 0.6, "cursor": "not-allowed"}} disabled={True} title="Available after live scenario integration">Backup shortage</button><p style={s("navSmall")}>Fixed display examples</p></nav>;
            <div key="simulation" style={{"marginTop": "auto", "paddingTop": 48}}><p style={s("navSmall")}>Simulation only</p><p style={s("navSmall")}>12 buses · 3 sources</p><p style={s("navSmall")}>9 loads · Built with Jac</p></div>;
        }}
    </aside>;
}
