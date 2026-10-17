"""Figma presentation tokens and shared browser style dictionaries, authored in Jac."""

glob:pub colors: dict[str, str] = {
    "canvas": "#f5f7fa", "surface": "#ffffff", "nav": "#102b30",
    "navText": "#c8d9dd", "text": "#142c35", "muted": "#536574",
    "border": "#d8e1e7", "teal": "#087f83", "tealStrong": "#006b70",
    "tealTint": "#e5f4f2", "green": "#147d55", "greenTint": "#e7f4ed",
    "fault": "#b33b38", "faultTint": "#fff0ee", "amber": "#99610b", "amberTint": "#fff4dd",
    "blue": "#315bb8", "blueTint": "#edf2ff"
};

glob styles: dict[str, dict[str, object]] = {
    "app": {"display": "flex", "minHeight": "100vh", "background": colors["canvas"], "color": colors["text"], "fontFamily": "'Fira Sans', sans-serif", "fontSize": 14, "lineHeight": "20px"},
    "sidebar": {"width": 176, "flexShrink": 0, "background": colors["nav"], "color": colors["surface"], "padding": 20, "boxSizing": "border-box", "display": "flex", "flexDirection": "column", "gap": 24},
    "brand": {"fontSize": 20, "fontWeight": 600, "lineHeight": "28px", "margin": 0},
    "navSmall": {"fontSize": 12, "lineHeight": "18px", "color": colors["navText"], "margin": 0},
    "navActive": {"padding": 12, "borderRadius": 8, "background": colors["tealStrong"], "color": "white", "textDecoration": "none", "fontWeight": 500},
    "navHeading": {"fontSize": 11, "lineHeight": "16px", "color": colors["navText"], "margin": "0 0 12px"},
    "navItem": {"display": "block", "padding": "8px 0", "color": "white", "textDecoration": "none"},
    "navScenario": {"display": "block", "padding": "10px 8px", "minHeight": 44, "width": "100%", "textAlign": "left", "border": 0, "borderRadius": 12, "background": "transparent", "color": "white", "fontFamily": "inherit", "fontSize": 12, "cursor": "pointer"},
    "main": {"flex": 1, "minWidth": 0},
    "header": {"minHeight": 64, "padding": "12px 32px", "boxSizing": "border-box", "background": "white", "borderBottom": "1px solid " + colors["border"], "display": "flex", "alignItems": "center", "justifyContent": "space-between", "gap": 16, "flexWrap": "wrap"},
    "content": {"maxWidth": 1200, "padding": "24px 32px", "margin": "0 auto", "display": "flex", "flexDirection": "column", "gap": 16},
    "row": {"display": "flex", "alignItems": "center", "justifyContent": "space-between", "gap": 16, "flexWrap": "wrap"},
    "title": {"fontSize": 28, "fontWeight": 500, "lineHeight": "36px", "margin": "0 0 4px"},
    "sectionTitle": {"fontSize": 18, "fontWeight": 500, "lineHeight": "26px", "margin": 0},
    "strong": {"fontSize": 14, "fontWeight": 500, "lineHeight": "20px", "margin": 0},
    "small": {"fontSize": 12, "lineHeight": "18px", "color": colors["muted"], "margin": 0},
    "tiny": {"fontSize": 11, "lineHeight": "16px", "color": colors["muted"], "margin": 0},
    "mono": {"fontFamily": "'Fira Code', monospace", "fontSize": 11, "lineHeight": "17px", "color": colors["muted"], "margin": 0},
    "pill": {"display": "inline-block", "padding": "6px 8px", "borderRadius": 999, "background": colors["tealTint"], "color": colors["tealStrong"], "fontSize": 12, "lineHeight": "18px", "whiteSpace": "nowrap"},
    "healthyPill": {"display": "inline-block", "padding": "6px 8px", "borderRadius": 999, "background": colors["greenTint"], "color": colors["green"], "fontSize": 12, "lineHeight": "18px", "whiteSpace": "nowrap"},
    "button": {"minHeight": 44, "padding": "10px 20px", "border": "1px solid " + colors["tealStrong"], "borderRadius": 8, "background": colors["tealStrong"], "color": "white", "fontFamily": "inherit", "fontSize": 14, "fontWeight": 500, "cursor": "not-allowed", "opacity": 0.65},
    "metrics": {"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(min(100%, 220px), 1fr))", "gap": 16},
    "metric": {"padding": 12, "minHeight": 112, "boxSizing": "border-box", "border": "1px solid " + colors["border"], "background": "white", "borderRadius": 12, "display": "flex", "flexDirection": "column", "gap": 4},
    "criticalMetric": {"padding": 12, "minHeight": 112, "boxSizing": "border-box", "border": "1px solid " + colors["green"], "background": colors["greenTint"], "borderRadius": 12, "display": "flex", "flexDirection": "column", "gap": 4},
    "metricValue": {"fontSize": 32, "fontWeight": 500, "lineHeight": "40px", "margin": 0},
    "banner": {"background": colors["tealTint"], "borderRadius": 12, "padding": 16, "display": "flex", "gap": 16, "alignItems": "center"},
    "columns": {"display": "grid", "gridTemplateColumns": "minmax(0, 780fr) minmax(320px, 396fr)", "gap": 24},
    "panel": {"background": "white", "border": "1px solid " + colors["border"], "borderRadius": 12, "padding": 20, "minWidth": 0, "boxSizing": "border-box", "display": "flex", "flexDirection": "column", "gap": 12},
    "evidence": {"background": "white", "border": "1px solid " + colors["border"], "borderRadius": 12, "padding": 16, "minHeight": 172, "minWidth": 0, "boxSizing": "border-box", "display": "flex", "flexDirection": "column", "gap": 8},
    "event": {"padding": 8, "minHeight": 76, "boxSizing": "border-box", "display": "flex", "flexDirection": "column", "gap": 4},
    "approval": {"background": colors["tealTint"], "borderRadius": 8, "padding": 12, "display": "flex", "flexDirection": "column", "gap": 4},
    "scroll": {"overflowX": "auto", "minWidth": 0},
    "diagram": {"width": 740, "height": 344, "position": "relative", "margin": "0 auto"},
    "lineAsset": {"position": "absolute", "left": 0, "top": 0, "pointerEvents": "none"},
    "legend": {"display": "flex", "flexWrap": "wrap", "gap": 16, "fontSize": 11, "lineHeight": "16px", "color": colors["muted"]},
    "legendItem": {"display": "flex", "alignItems": "center", "gap": 6},
    "select": {"minHeight": 44, "maxWidth": "100%", "padding": "8px 12px", "borderRadius": 8, "border": "1px solid " + colors["border"], "background": "white", "fontFamily": "inherit", "fontSize": 14, "color": colors["text"], "boxSizing": "border-box"},
    "details": {"borderTop": "1px solid " + colors["border"], "paddingTop": 12},
    "summary": {"cursor": "pointer", "padding": "10px 0", "minHeight": 24, "fontWeight": 500},
    "dl": {"display": "grid", "gridTemplateColumns": "repeat(auto-fit, minmax(140px, 1fr))", "gap": 12, "margin": "12px 0 0"},
    "dd": {"margin": "4px 0 0", "fontSize": 13},
    "table": {"width": "100%", "borderCollapse": "collapse", "fontSize": 12, "lineHeight": "18px", "textAlign": "left"},
    "th": {"textAlign": "left", "fontSize": 11, "fontWeight": 400, "color": colors["muted"], "padding": "4px", "whiteSpace": "nowrap"},
    "td": {"padding": "4px", "whiteSpace": "nowrap"}
};

def:pub s(name: str) -> dict[str, object] { return styles[name]; }

def:pub bus_style(x: int, y: int, source: bool, status: str) -> dict[str, object] {
    tone = "teal" if source else "green";
    if status in ["unmet", "unserved", "fault", "offline"] { tone = "fault"; }
    elif status in ["derated", "shed", "partial"] { tone = "amber"; }
    elif status == "rerouted" { tone = "blue"; }
    return {"position": "absolute", "left": x, "top": y, "width": 160, "height": 56,
        "padding": "8px", "boxSizing": "border-box", "borderRadius": 12,
        "border": "1px solid " + colors[tone], "background": colors[tone + "Tint"],
        "color": colors["text"], "textAlign": "left", "fontFamily": "inherit", "cursor": "pointer"};
}
