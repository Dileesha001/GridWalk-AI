"""Validate the canonical server projection without calculating recovery outcomes."""
sv import from ..shared.contracts { GraphState }
import from .decode { object_value, text, number, integer, flag, array }

def identity(data: dict[str, any], key: str) -> str {
    value = text(data, key);
    if not value { raise ValueError("Empty server identity: " + key); }
    return value;
}

def:pub decode_grid_response(raw: any) -> GraphState {
    envelope = object_value(raw);
    if not flag(envelope, "ok") { raise ValueError("The server rejected the request. Refresh live state before retrying."); }
    data = object_value(envelope["data"]);
    if "result" not in data { raise ValueError("The server response is missing its result."); }
    return decode_grid(data["result"]);
}

def:pub decode_grid(raw: any) -> GraphState {
    data = object_value(raw);
    identity(data, "grid_id");
    identity(data, "generation_id");
    revision = integer(data, "revision");
    if not Number.isSafeInteger(revision) { raise ValueError("Invalid grid revision."); }
    sources = array(data, "sources"); loads = array(data, "loads"); lines = array(data, "lines");
    if not sources or not loads { raise ValueError("The grid response has no sources or loads."); }
    bus_ids: list[str] = [];
    for item in sources {
        row = object_value(item); bus_id = identity(row, "bus_id");
        if bus_id in bus_ids { raise ValueError("Duplicate bus ID."); }
        bus_ids.append(bus_id);
        identity(row, "label"); flag(row, "is_backup");
        if text(row, "status") not in ["online", "derated", "offline", "fault"] { raise ValueError("Unknown source status."); }
        if number(row, "dispatched_kw") > number(row, "capacity_kw") + 0.000001 { raise ValueError("Source dispatch exceeds capacity."); }
    }
    for item in loads {
        row = object_value(item); bus_id = identity(row, "bus_id");
        if bus_id in bus_ids { raise ValueError("Duplicate bus ID."); }
        bus_ids.append(bus_id); identity(row, "label"); flag(row, "deliberately_shed");
        if integer(row, "tier") not in [1, 2, 3] { raise ValueError("Unknown priority tier."); }
        if text(row, "status") not in ["powered", "unmet", "unserved", "shed", "rerouted", "partial"] { raise ValueError("Unknown load status."); }
        if number(row, "served_kw") > number(row, "demand_kw") + 0.000001 { raise ValueError("Service exceeds demand."); }
    }
    line_ids: list[str] = []; switch_ids: list[str] = [];
    for item in lines {
        row = object_value(item); line_id = identity(row, "line_id"); switch_id = identity(row, "switch_id");
        if line_id in line_ids or switch_id in switch_ids { raise ValueError("Duplicate line or switch ID."); }
        line_ids.append(line_id); switch_ids.append(switch_id);
        if text(row, "from_bus_id") not in bus_ids or text(row, "to_bus_id") not in bus_ids { raise ValueError("Unknown line endpoint."); }
        number(row, "capacity_kw");
        transfer = row["transfer_kw"];
        if isinstance(transfer, bool) or not isinstance(transfer, (int, float)) or not Number.isFinite(transfer) { raise ValueError("Invalid signed transfer."); }
        conducting = flag(row, "conducting"); closed = flag(row, "switch_closed"); faulted = flag(row, "physically_faulted");
        if conducting and (not closed or faulted) { raise ValueError("Inconsistent physical line state."); }
        if not conducting and abs(transfer as float) > 0.000001 { raise ValueError("A nonconducting line carries transfer."); }
    }
    faults: list[str] = [];
    for fault_id in array(data, "active_fault_ids") {
        if not isinstance(fault_id, str) or not fault_id or fault_id in faults { raise ValueError("Invalid active fault ID."); }
        faults.append(fault_id as str);
    }
    metrics = object_value(data["metrics"]);
    for key in ["total_demand_kw", "served_kw", "unmet_kw", "shed_kw", "available_capacity_kw", "dispatched_kw"] { number(metrics, key); }
    if integer(metrics, "active_fault_count") != len(faults) { raise ValueError("Inconsistent active fault count."); }
    if "critical_preserved_pct" not in metrics { raise ValueError("Missing critical demand percentage."); }
    if metrics["critical_preserved_pct"] is not None and number(metrics, "critical_preserved_pct") > 100 { raise ValueError("Invalid critical demand percentage."); }
    return data as GraphState;
}
