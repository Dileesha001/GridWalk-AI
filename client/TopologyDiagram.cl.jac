"""Canonical GraphState renderer. SVG labels supplement text-based inspection."""

sv import from ..shared.contracts { GraphState }
import from .models { kw }
import from .topology_layout { topology_positions, topology_height, wire_path, wire_midpoint, line_color, line_label, source_style, load_style }

def:pub TopologyDiagram(grid: GraphState, selected: str) -> JsxElement {
    points = topology_positions(grid);
    return <div className="topology-scroll" tabIndex={0} aria-label="Scrollable microgrid diagram" aria-describedby="diagram-help">
        <svg className="topology-svg" viewBox={"0 0 960 " + str(topology_height(grid))} role="img" aria-label="Microgrid topology. Sources and loads show names, stable IDs, status, and kW. Line and switch details are available in the component inspector.">
            {for line in grid.lines {
                midpoint = wire_midpoint(grid, line);
                <g key={line.line_id} className="topology-wire"><title>{line.line_id + " · " + line.switch_id + " · " + line_label(line) + " · " + kw(line.transfer_kw) + " / " + kw(line.capacity_kw) + " kW"}</title><path d={wire_path(grid, line)} fill="none" stroke={line_color(line)} strokeWidth={4 if selected == line.line_id else 2} strokeDasharray={"7 6" if not line.conducting else "none"}/><rect x={midpoint[0] - 40} y={midpoint[1] - 13} width="80" height="27" rx="5"/><text x={midpoint[0]} y={midpoint[1] - 2}>{line.line_id}</text><text x={midpoint[0]} y={midpoint[1] + 10} className={"wire-fault" if line.physically_faulted else ""}>{"FAULT / closed" if line.physically_faulted and line.switch_closed else "FAULT / open" if line.physically_faulted else "Closed" if line.switch_closed else "Open"}</text></g>;
            }}
            {for item in grid.sources {
                point = points[item.bus_id];
                <g key={item.bus_id} className={"topology-node " + source_style(item.status) + (" selected-node" if selected == item.bus_id else "")}><rect x={point[0] - 78} y={point[1] - 44} width="156" height="88" rx="9"/><text x={point[0]} y={point[1] - 24} className="node-id">{item.bus_id + (" · BACKUP" if item.is_backup else " · SOURCE")}</text><text x={point[0]} y={point[1] - 4}>{item.label}</text><text x={point[0]} y={point[1] + 14} className="node-measurement">{kw(item.dispatched_kw) + " / " + kw(item.capacity_kw) + " kW"}</text><text x={point[0]} y={point[1] + 32} className="node-status">{item.status + " · dispatch / capacity"}</text></g>;
            }}
            {for item in grid.loads {
                point = points[item.bus_id];
                <g key={item.bus_id} className={"topology-node " + load_style(item.status) + (" selected-node" if selected == item.bus_id else "")}><rect x={point[0] - 78} y={point[1] - 44} width="156" height="88" rx="9"/><text x={point[0]} y={point[1] - 24} className="node-id">{item.bus_id + " · T" + str(item.tier)}</text><text x={point[0]} y={point[1] - 4}>{item.label}</text><text x={point[0]} y={point[1] + 14} className="node-measurement">{kw(item.served_kw) + " / " + kw(item.demand_kw) + " kW"}</text><text x={point[0]} y={point[1] + 32} className="node-status">{item.status + " · served / demand"}</text></g>;
            }}
        </svg>
    </div>;
}
