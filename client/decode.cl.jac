"""Validate draft wire data at one boundary before constructing presentation objects."""

import from .models { SourceView, LoadView, LineView, MetricsView, GridView, EventView, RecoveryView }

def:pub object_value(raw: any) -> dict[str, any] {
    # Jac 0.16.7 tags dictionaries as Maps, whereas JSON.parse returns plain objects.
    js_object: any = Object;
    if js_object.prototype.toString.call(raw) != "[object Object]" {
        raise ValueError("Expected an object in the server response.");
    }
    return raw as dict[str, any];
}

def:pub text(raw: dict[str, any], key: str) -> str {
    value = raw[key];
    if not isinstance(value, str) { raise ValueError("Missing or invalid text field: " + key); }
    return value as str;
}

def:pub number(raw: dict[str, any], key: str) -> float {
    value = raw[key];
    if isinstance(value, bool) or not isinstance(value, (int, float)) {
        raise ValueError("Missing or invalid numeric field: " + key);
    }
    numeric = value as float;
    if not Number.isFinite(numeric) or numeric < 0 { raise ValueError("Invalid nonnegative number: " + key); }
    return numeric;
}

def:pub integer(raw: dict[str, any], key: str) -> int {
    value = number(raw, key);
    if value != int(value) { raise ValueError("Expected an integer: " + key); }
    return int(value);
}

def:pub flag(raw: dict[str, any], key: str) -> bool {
    value = raw[key];
    if not isinstance(value, bool) { raise ValueError("Missing or invalid boolean field: " + key); }
    return value as bool;
}

def:pub array(raw: dict[str, any], key: str) -> list[any] {
    value = raw[key];
    if not isinstance(value, list) { raise ValueError("Missing or invalid list field: " + key); }
    return value as list[any];
}

def:pub metrics_value(raw: any) -> MetricsView {
    data = object_value(raw);
    critical: float | None = None;
    if data["critical_served_pct"] is not None {
        critical = number(data, "critical_served_pct");
        if critical > 100 { raise ValueError("Critical demand percentage exceeds 100."); }
    }
    return MetricsView(critical_served_pct=critical, shed_kw=number(data, "shed_kw"), unmet_kw=number(data, "unmet_kw"), available_capacity_kw=number(data, "available_capacity_kw"), dispatch_kw=number(data, "dispatch_kw"), active_faults=integer(data, "active_faults"));
}

def:pub unwrap(raw: any) -> any {
    data = object_value(raw);
    if "ok" in data {
        if not flag(data, "ok") { raise ValueError("The server rejected the operation. Refresh state before retrying."); }
        return data["data"];
    }
    return data;
}

def:pub grid_value(raw: any) -> GridView {
    data = object_value(raw);
    sources: list[SourceView] = [];
    loads: list[LoadView] = [];
    lines: list[LineView] = [];
    ids: list[str] = [];
    for item in array(data, "sources") {
        row = object_value(item);
        identity = text(row, "id");
        if not identity or identity in ids { raise ValueError("Duplicate or empty component ID."); }
        ids.append(identity);
        sources.append(SourceView(id=identity, name=text(row, "name"), capacity_kw=number(row, "capacity_kw"), dispatch_kw=number(row, "dispatch_kw"), status=text(row, "status")));
    }
    for item in array(data, "loads") {
        row = object_value(item);
        identity = text(row, "id");
        if not identity or identity in ids { raise ValueError("Duplicate or empty component ID."); }
        ids.append(identity);
        tier = integer(row, "tier");
        if tier not in [1, 2, 3] { raise ValueError("Unsupported load priority tier."); }
        loads.append(LoadView(id=identity, name=text(row, "name"), demand_kw=number(row, "demand_kw"), served_kw=number(row, "served_kw"), tier=tier, status=text(row, "status")));
    }
    line_ids: list[str] = [];
    for item in array(data, "lines") {
        row = object_value(item);
        identity = text(row, "id");
        start = text(row, "from_id");
        end = text(row, "to_id");
        if identity in line_ids or not identity or start not in ids or end not in ids { raise ValueError("Invalid line identity or endpoint."); }
        line_ids.append(identity);
        # Transfer may be signed; direction belongs to the backend.
        transfer = row["transfer_kw"];
        if isinstance(transfer, bool) or not isinstance(transfer, (int, float)) or not Number.isFinite(transfer) { raise ValueError("Invalid line transfer."); }
        lines.append(LineView(id=identity, from_id=start, to_id=end, capacity_kw=number(row, "capacity_kw"), transfer_kw=transfer as float, faulted=flag(row, "faulted"), switch_closed=flag(row, "switch_closed"), switch_id=text(row, "switch_id")));
    }
    faults: list[str] = [];
    for item in array(data, "faults") {
        if not isinstance(item, str) { raise ValueError("Fault IDs must be strings."); }
        faults.append(item as str);
    }
    return GridView(version=integer(data, "version"), sources=sources, loads=loads, lines=lines, faults=faults, metrics=metrics_value(data["metrics"]), busy=flag(data, "busy"));
}

def:pub events_value(raw: any) -> list[EventView] {
    data = object_value(raw);
    result: list[EventView] = [];
    for item in array(data, "events") {
        row = object_value(item);
        result.append(EventView(run_id=text(row, "run_id"), sequence=integer(row, "sequence"), actor=text(row, "actor"), kind=text(row, "kind"), message=text(row, "message")));
    }
    return result;
}

def:pub recovery_value(raw: any) -> RecoveryView {
    data = object_value(raw);
    outcome = text(data, "outcome");
    mode = text(data, "mode");
    if outcome not in ["complete", "infeasible", "error"] { raise ValueError("Unknown recovery outcome."); }
    if mode not in ["primary_ai", "backup_ai", "deterministic"] { raise ValueError("Unknown execution mode."); }
    return RecoveryView(run_id=text(data, "run_id"), outcome=outcome, mode=mode, summary=text(data, "summary"), before=metrics_value(data["before"]), after=metrics_value(data["after"]), applied_action_count=integer(data, "applied_action_count"));
}
