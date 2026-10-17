"""Inspectable Figma network, backed by the canonical fixed display snapshots."""
sv import from ..shared.contracts { GraphState }
import from .console_styles { s, bus_style, colors }
import from .console_format { number as kw }
import from .console_assets { image_urls }

glob positions: dict[str, tuple[int, int]] = {
    "SRC-A": (185, 36), "SRC-B": (365, 36), "SRC-R": (550, 36),
    "LOAD-HOSP": (10, 116), "LOAD-WATER": (10, 196), "LOAD-LAB": (185, 116),
    "LOAD-OFFICE": (185, 196), "LOAD-DATA": (365, 116), "LOAD-PUMP": (365, 196),
    "LOAD-HOMES": (365, 276), "LOAD-CLINIC": (550, 116), "LOAD-LIGHTS": (550, 196)
};
glob assets: list[str] = ["imgLineLineAH", "imgLineLineHW", "imgLineLineAL", "imgLineLineLO", "imgLineLineBD", "imgLineLineDP", "imgLineLineBHm", "imgLineLineRC", "imgLineLineCLt", "imgLineTieBH", "imgLineTieBA", "imgLineTieRA"];
glob labels: dict[str, str] = {"LOAD-WATER": "Water plant", "LOAD-LAB": "Laboratory", "LOAD-HOMES": "Homes", "LOAD-LIGHTS": "Street lights"};

def:pub ConsoleNetwork(grid: GraphState, example: str, selected: str, onSelect: Callable[[str], None]) -> JsxElement {
    baseline = example == "baseline";
    return <section id="network" style={{**s("panel"), "gap": 8, "minHeight": 492}} aria-labelledby="network-title">
        <div style={s("row")}><h2 id="network-title" style={s("sectionTitle")}>Microgrid topology</h2><span style={s("healthyPill") if baseline else s("pill")}>{"Healthy baseline" if baseline else "Fixed display snapshot"}</span></div>
        <div className="topology-scroll" style={s("scroll")} tabIndex={0} aria-label="Scrollable network diagram; use component inspection below for all measurements">
            <div style={s("diagram")}>
                {if baseline {
                    for asset in assets { <img key={asset} className="network-asset" src={image_urls[asset]} alt="" style={s("lineAsset")}/> }
                } else {
                    <svg key="dynamic-lines" width="740" height="344" style={s("lineAsset")} aria-hidden="true">
                        {for line in grid.lines {
                            start = positions[line.from_bus_id]; end = positions[line.to_bus_id];
                            route = "M " + str(start[0] + 80) + " " + str(start[1] + 28) + " L " + str(end[0] + 80) + " " + str(end[1] + 28);
                            if start[1] == end[1] { route = "M " + str(start[0] + 80) + " " + str(start[1]) + " V 12 H " + str(end[0] + 80) + " V " + str(end[1]); }
                            <path key={line.line_id} d={route} fill="none" stroke={colors["fault"] if line.physically_faulted else colors["green"] if line.conducting else colors["muted"]} strokeWidth="2" strokeDasharray={"none" if line.conducting else "6 5"}/>;
                        }}
                    </svg>;
                }}
                <p style={{**s("tiny"), "position": "absolute", "left": 360, "top": -4}}>{"Reserve tie · normally open" if baseline else "Illustrative connections · inspect line state below"}</p>
                {for source in grid.sources {
                    point = positions[source.bus_id];
                    <button key={source.bus_id} className="topology-node" aria-pressed={selected == source.bus_id} style={bus_style(point[0], point[1], True, source.status)} aria-label={"Inspect " + source.bus_id + ", " + source.label} onClick={lambda (e: MouseEvent) { onSelect(source.bus_id); }}><span style={{**s("strong"), "display": "block"}}>{source.label}</span><span style={s("mono")}>{kw(source.capacity_kw) + " kW cap · " + source.status}</span></button>;
                }}
                {for load in grid.loads {
                    point = positions[load.bus_id];
                    <button key={load.bus_id} className="topology-node" aria-pressed={selected == load.bus_id} style={bus_style(point[0], point[1], False, load.status)} aria-label={"Inspect " + load.bus_id + ", " + load.label} onClick={lambda (e: MouseEvent) { onSelect(load.bus_id); }}><span style={{**s("strong"), "display": "block"}}>{labels[load.bus_id] if load.bus_id in labels else load.label}{" · T" + str(load.tier)}</span><span style={s("mono")}>{kw(load.served_kw) + " kW · " + load.status}</span></button>;
                }}
            </div>
        </div>
        <div style={s("legend")} aria-label="Network status legend">{for (asset, label) in [("imgEllipse", "Powered"), ("imgEllipse1", "Fault / unserved"), ("imgEllipse2", "Shed / derated"), ("imgEllipse3", "Rerouted")] { <span key={asset} style={s("legendItem")}><img src={image_urls[asset]} alt=""/>{label}</span> }}<span>- - Open switch</span></div>

        <p style={s("tiny")}>Dashed ties are open or proposed. Physical faults are separate from switch state.</p>
    </section>;
}
