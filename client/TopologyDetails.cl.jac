"""Accessible source/load/line inspection using authoritative projection fields."""

sv import from ..shared.contracts { GraphState }
import from .models { kw }
import from .console_styles { s }

def:pub TopologyDetails(grid: GraphState, selected: str) -> JsxElement {
    return <div className="topology-inspector" aria-live="polite" style={{"paddingTop": 16}}>
        {for item in grid.sources {
            if item.bus_id == selected {
                <div key={item.bus_id}><h3 style={s("strong")}>{item.label}</h3><dl style={s("dl")}><div><dt style={s("tiny")}>Source ID</dt><dd style={s("dd")}>{item.bus_id}</dd></div><div><dt style={s("tiny")}>Status</dt><dd style={s("dd")}>{item.status}</dd></div><div><dt style={s("tiny")}>Available capacity</dt><dd style={s("dd")}>{kw(item.capacity_kw) + " kW"}</dd></div><div><dt style={s("tiny")}>Dispatched power</dt><dd style={s("dd")}>{kw(item.dispatched_kw) + " kW"}</dd></div><div><dt style={s("tiny")}>Backup source</dt><dd style={s("dd")}>{"Yes" if item.is_backup else "No"}</dd></div></dl></div>;
            }
        }}
        {for item in grid.loads {
            if item.bus_id == selected {
                <div key={item.bus_id}><h3 style={s("strong")}>{item.label}</h3><dl style={s("dl")}><div><dt style={s("tiny")}>Load ID</dt><dd style={s("dd")}>{item.bus_id}</dd></div><div><dt style={s("tiny")}>Status</dt><dd style={s("dd")}>{item.status}</dd></div><div><dt style={s("tiny")}>Priority</dt><dd style={s("dd")}>{"Tier " + str(item.tier) + (" · Critical" if item.tier == 1 else " · Essential" if item.tier == 2 else " · Noncritical")}</dd></div><div><dt style={s("tiny")}>Served / demand</dt><dd style={s("dd")}>{kw(item.served_kw) + " / " + kw(item.demand_kw) + " kW"}</dd></div><div><dt style={s("tiny")}>Deliberately shed</dt><dd style={s("dd")}>{"Yes" if item.deliberately_shed else "No"}</dd></div></dl></div>;
            }
        }}
        {for item in grid.lines {
            if item.line_id == selected {
                <div key={item.line_id}><h3 style={s("strong")}>{item.line_id}</h3><dl style={s("dl")}><div><dt style={s("tiny")}>Endpoints</dt><dd style={s("dd")}>{item.from_bus_id + " → " + item.to_bus_id}</dd></div><div><dt style={s("tiny")}>Physical line</dt><dd style={s("dd")}>{"FAULTED" if item.physically_faulted else "Healthy"}</dd></div><div><dt style={s("tiny")}>Switch</dt><dd style={s("dd")}>{item.switch_id + " · " + ("Closed" if item.switch_closed else "Open")}</dd></div><div><dt style={s("tiny")}>Conducting</dt><dd style={s("dd")}>{"Yes" if item.conducting else "No"}</dd></div><div><dt style={s("tiny")}>Transfer / rating</dt><dd style={s("dd")}>{kw(item.transfer_kw) + " / " + kw(item.capacity_kw) + " kW"}</dd></div></dl><p style={{**s("small"), "marginTop": 12}}>Positive transfer follows the displayed endpoints; negative transfer flows in reverse.</p></div>;
            }
        }}
    </div>;
}
