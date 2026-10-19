"""Read-only topology preview. Snapshot selection never calls simulation mutations."""

import from .ShellPanel { ShellPanel }
import from .topology_examples { topology_example }
import from .TopologyDiagram { TopologyDiagram }
import from .TopologyDetails { TopologyDetails }

def:pub Topology() -> JsxElement {
    has example: str = "baseline", selected: str = "SRC-A";
    grid = topology_example(example);

    return <ShellPanel eyebrow="NETWORK OVERVIEW" title="Microgrid topology" badge="Fixed snapshot">
        <div className="topology-toolbar"><div><label htmlFor="topology-example">Display example</label><select id="topology-example" value={example} onChange={lambda (e: ChangeEvent) { example = e.target.value; }}><option value="baseline">Healthy baseline</option><option value="source_fault">Source capacity reduced</option><option value="line_fault">Physical line fault</option><option value="rerouted">Rerouted service with shedding</option></select></div><span className="topology-count">{str(len(grid.sources)) + " sources · " + str(len(grid.loads)) + " loads"}</span></div>
        <p className="snapshot-note">Fixed display data. No simulator, validator, or agents run when you change this example.</p>
        {if len(grid.active_fault_ids) > 0 { <p key="fault-retained" className="topology-fault" role="status"><strong>Fault retained: </strong>{grid.active_fault_ids[0]}{" · A recovered supply path does not repair the physical component."}</p>; }}
        <p className="diagram-help" id="diagram-help">Inspect a component below for its ID and measurements. On a small screen, scroll the diagram horizontally.</p>
        <TopologyDiagram grid={grid} selected={selected}/>
        <div className="legend" aria-label="Grid status legend"><span><i className="powered" aria-hidden="true"></i>Powered</span><span><i className="fault" aria-hidden="true"></i>Fault / unmet</span><span><i className="shed" aria-hidden="true"></i>Shed / derated</span><span><i className="rerouted" aria-hidden="true"></i>Rerouted</span><span className="open-legend">- - Open switch</span></div>
        <div className="component-picker"><label htmlFor="topology-component">Inspect component</label><select id="topology-component" value={selected} onChange={lambda (e: ChangeEvent) { selected = e.target.value; }}><optgroup label="Sources">{for item in grid.sources { <option key={item.bus_id} value={item.bus_id}>{item.bus_id + " · " + item.label}</option> }}</optgroup><optgroup label="Loads">{for item in grid.loads { <option key={item.bus_id} value={item.bus_id}>{item.bus_id + " · " + item.label}</option> }}</optgroup><optgroup label="Lines and switches">{for item in grid.lines { <option key={item.line_id} value={item.line_id}>{item.line_id + " · " + item.switch_id}</option> }}</optgroup></select></div>
        <TopologyDetails grid={grid} selected={selected}/>
        <p className="panel-note">{grid.grid_id + " · Fictional facilities · Simplified connectivity and lossless kW allocation"}</p>
    </ShellPanel>;
}
