"""Shared typed contracts. Member 1 owns the graph-state projection below.

Member 2 owns recovery-plan and event contracts, which are still to be agreed.
The objects here are projections; persistent graph entities live in grid/graph.jac.
"""

obj SourceView {
    has bus_id: str;
    has label: str;
    has capacity_kw: float;
    has dispatched_kw: float;
    has is_backup: bool;
    has status: str;
}

obj LoadView {
    has bus_id: str;
    has label: str;
    has demand_kw: float;
    has tier: int;
    has served_kw: float;
    has deliberately_shed: bool;
    has status: str;
}

obj LineView {
    has line_id: str;
    has from_bus_id: str;
    has to_bus_id: str;
    has switch_id: str;
    has capacity_kw: float;
    has switch_closed: bool;
    has physically_faulted: bool;
    has conducting: bool;
    has transfer_kw: float;
}

obj GridMetrics {
    has total_demand_kw: float;
    has served_kw: float;
    has unmet_kw: float;
    has shed_kw: float;
    has available_capacity_kw: float;
    has dispatched_kw: float;
    has critical_preserved_pct: float | None;
    has active_fault_count: int;
}

obj GraphState {
    has grid_id: str;
    has revision: int;
    has sources: list[SourceView];
    has loads: list[LoadView];
    has lines: list[LineView];
    has metrics: GridMetrics;
}
