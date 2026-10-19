"""Inspectable topology for canonical server state and explicit fixed previews."""
sv import from ..shared.contracts { GraphState }
import from .console_styles { s, bus_style, colors }
import from .console_format { number as kw }
import from .console_assets { image_urls }
import from .network_geometry { network_positions, network_height, network_route }

glob assets: list[str] = ["imgLineLineAH", "imgLineLineHW", "imgLineLineAL", "imgLineLineLO", "imgLineLineBD", "imgLineLineDP", "imgLineLineBHm", "imgLineLineRC", "imgLineLineCLt", "imgLineTieBH", "imgLineTieBA", "imgLineTieRA"];
glob labels: dict[str, str] = {"LOAD-WATER": "Water plant", "LOAD-LAB": "Laboratory", "LOAD-HOMES": "Homes", "LOAD-LIGHTS": "Street lights"};

def:pub ConsoleNetwork(grid: GraphState, example: str, selected: str, preview: bool, onSelect: Callable[[str], None]) -> JsxElement {
    baseline = preview and example == "baseline";
    positions = network_positions(grid);
    height = network_height(grid, positions);
    return <section id="network" style={{**s("panel"), "gap": 8, "minHeight": 492}} aria-labelledby="network-title">
        <div style={s("row")}><h2 id="network-title" style={s("sectionTitle")}>Microgrid topology</h2><span style={s("healthyPill") if baseline else s("pill")}>{"Healthy baseline" if baseline else "Fixed display snapshot" if preview else "Server state · revision " + str(grid.revision)}</span></div>
        <div className="topology-scroll" style={s("scroll")} tabIndex={0} aria-label="Scrollable network diagram; use component inspection below for all measurements">
            <div style={{**s("diagram"), "height": height}}>
                {if baseline {
                    for asset in assets { <img key={asset} className="network-asset" src={image_urls[asset]} alt="" style={s("lineAsset")}/> }
                } else {
                    <svg key="dynamic-lines" width="740" height={height} style={s("lineAsset")} aria-hidden="true">
                        {for line in grid.lines {
                            <path key={line.line_id} data-line-id={line.line_id} className="topology-wire" d={network_route(line, positions)} fill="none" stroke={colors["fault"] if line.physically_faulted else colors["green"] if line.conducting else colors["muted"]} strokeWidth="2" strokeDasharray={"none" if line.conducting else "6 5"}/>;
                        }}
                    </svg>;
                }}
                <p style={{**s("tiny"), "position": "absolute", "left": 360, "top": -4}}>{"Reserve tie · normally open" if baseline else "Fixed preview · inspect line state below" if preview else "Live connectivity · inspect line state below"}</p>
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

        <p style={s("tiny")}>Dashed lines are nonconducting. Physical faults are separate from switch state.</p>
    </section>;
}
