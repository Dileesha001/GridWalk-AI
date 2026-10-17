"""Read-only dashboard presentation types. Draft wire fields await backend ratification."""

obj:pub SourceView {
    has id: str, name: str, capacity_kw: float, dispatch_kw: float, status: str;
}

obj:pub LoadView {
    has id: str, name: str, demand_kw: float, served_kw: float, tier: int, status: str;
}

obj:pub LineView {
    has id: str, from_id: str, to_id: str, capacity_kw: float,
        transfer_kw: float, faulted: bool, switch_closed: bool, switch_id: str;
}

obj:pub MetricsView {
    has critical_served_pct: float | None, shed_kw: float, unmet_kw: float,
        available_capacity_kw: float, dispatch_kw: float, active_faults: int;
}

obj:pub GridView {
    has version: int, sources: list[SourceView], loads: list[LoadView],
        lines: list[LineView], faults: list[str], metrics: MetricsView;
    has busy: bool = False;
}

obj:pub EventView {
    has run_id: str, sequence: int, actor: str, kind: str, message: str;
}

obj:pub RecoveryView {
    has run_id: str, outcome: str, mode: str, summary: str,
        before: MetricsView, after: MetricsView, applied_action_count: int;
}

def:pub kw(value: float) -> str { return f"{value:.1f}"; }

def:pub critical_label(value: float | None) -> str {
    if value is None { return "N/A"; }
    return f"{value:.1f}%";
}

def:pub mode_label(mode: str) -> str {
    if mode == "primary_ai" { return "Primary AI"; }
    if mode == "backup_ai" { return "Backup provider"; }
    if mode == "deterministic" { return "Deterministic fallback"; }
    if mode == "preview" { return "Preview snapshot"; }
    return "No recovery run";
}

def:pub event_order(item: EventView) -> int { return item.sequence; }

def:pub ordered_events(items: list[EventView], run_id: str) -> list[EventView] {
    selected = [item for item in items if item.run_id == run_id];
    ordered = sorted(selected, key=event_order);
    seen: list[int] = [];
    result: list[EventView] = [];
    for item in ordered {
        if item.sequence not in seen {
            seen.append(item.sequence);
            result.append(item);
        }
    }
    return result;
}
