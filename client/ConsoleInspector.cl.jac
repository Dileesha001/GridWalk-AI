"""Keyboard-accessible inspection of canonical source, load and physical line fields."""
sv import from ..shared.contracts { GraphState }
import from .console_styles { s }
import from .TopologyDetails { TopologyDetails }

def:pub ConsoleInspector(grid: GraphState, selected: str, onSelect: Callable[[str], None]) -> JsxElement {
    return <details id="component-inspection" style={s("details")}><summary style={s("summary")}>Inspect components and line states</summary><label htmlFor="topology-component" style={{**s("small"), "display": "block", "marginBottom": 8}}>Component</label>
            <select id="topology-component" style={{**s("select"), "width": "100%"}} value={selected} onChange={lambda (e: ChangeEvent) { onSelect(e.target.value); }}><optgroup label="Sources">{for item in grid.sources { <option key={item.bus_id} value={item.bus_id}>{item.bus_id + " · " + item.label}</option> }}</optgroup><optgroup label="Loads">{for item in grid.loads { <option key={item.bus_id} value={item.bus_id}>{item.bus_id + " · " + item.label}</option> }}</optgroup><optgroup label="Lines and switches">{for item in grid.lines { <option key={item.line_id} value={item.line_id}>{item.line_id + " · " + item.switch_id}</option> }}</optgroup></select>
            <TopologyDetails grid={grid} selected={selected}/>
        </details>;
}
