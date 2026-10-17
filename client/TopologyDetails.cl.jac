"""Accessible source/load/line inspection using authoritative projection fields."""

sv import from ..shared.contracts { GraphState }
import from .models { kw }

def:pub TopologyDetails(grid: GraphState, selected: str) -> JsxElement {
    return <div className="topology-inspector" aria-live="polite">
        {for item in grid.sources {
            if item.bus_id == selected {
                <div key={item.bus_id}><h3>{item.label}</h3><dl><div><dt>Source ID</dt><dd>{item.bus_id}</dd></div><div><dt>Status</dt><dd>{item.status}</dd></div><div><dt>Available capacity</dt><dd>{kw(item.capacity_kw) + " kW"}</dd></div><div><dt>Dispatched power</dt><dd>{kw(item.dispatched_kw) + " kW"}</dd></div><div><dt>Backup source</dt><dd>{"Yes" if item.is_backup else "No"}</dd></div></dl></div>;
            }
        }}
        {for item in grid.loads {
            if item.bus_id == selected {
                <div key={item.bus_id}><h3>{item.label}</h3><dl><div><dt>Load ID</dt><dd>{item.bus_id}</dd></div><div><dt>Status</dt><dd>{item.status}</dd></div><div><dt>Priority</dt><dd>{"Tier " + str(item.tier) + (" · Critical" if item.tier == 1 else " · Essential" if item.tier == 2 else " · Noncritical")}</dd></div><div><dt>Served / demand</dt><dd>{kw(item.served_kw) + " / " + kw(item.demand_kw) + " kW"}</dd></div><div><dt>Deliberately shed</dt><dd>{"Yes" if item.deliberately_shed else "No"}</dd></div></dl></div>;
            }
        }}
        {for item in grid.lines {
            if item.line_id == selected {
                <div key={item.line_id}><h3>{item.line_id}</h3><dl><div><dt>Endpoints</dt><dd>{item.from_bus_id + " → " + item.to_bus_id}</dd></div><div><dt>Physical line</dt><dd>{"FAULTED" if item.physically_faulted else "Healthy"}</dd></div><div><dt>Switch</dt><dd>{item.switch_id + " · " + ("Closed" if item.switch_closed else "Open")}</dd></div><div><dt>Conducting</dt><dd>{"Yes" if item.conducting else "No"}</dd></div><div><dt>Transfer / rating</dt><dd>{kw(item.transfer_kw) + " / " + kw(item.capacity_kw) + " kW"}</dd></div></dl><p className="panel-note">Positive transfer follows the displayed endpoints; negative transfer flows in reverse.</p></div>;
            }
        }}
    </div>;
}
