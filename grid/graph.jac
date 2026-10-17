"""Persistent entities for the fictional lossless kW grid."""

node Grid {
    has grid_id: str;
    has generation_id: str;
    has revision: int = 0;
    has active_fault_id: str = "";
    has allocation_committed: bool = False;
}

node GridBus {
    has bus_id: str;
    has label: str;
}

node Source(GridBus) {
    has capacity_kw: float;
    has is_backup: bool = False;
    has dispatched_kw: float = 0.0;
}

node Load(GridBus) {
    has demand_kw: float;
    has tier: int;
    has served_kw: float = 0.0;
    has deliberately_shed: bool = False;
}

edge PowerLine: GridBus --> GridBus {
    has line_id: str;
    has from_bus_id: str;
    has to_bus_id: str;
    has switch_id: str;
    has capacity_kw: float;
    has switch_closed: bool = True;
    has physically_faulted: bool = False;
    has transfer_kw: float = 0.0;
}

def conducts(line: PowerLine) -> bool {
    return line.switch_closed and not line.physically_faulted;
}
