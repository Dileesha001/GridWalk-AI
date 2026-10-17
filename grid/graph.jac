"""Persistent entities for the fictional lossless kW grid."""

node Grid {
    has grid_id: str;
    has revision: int = 0;
    has active_fault_id: str = "";
}

node GridBus {
    has bus_id: str;
    has label: str;
}

node Source(GridBus) {
    has capacity_kw: float;
    has is_backup: bool = False;
}

node Load(GridBus) {
    has demand_kw: float;
    has tier: int;
}

edge PowerLine: GridBus --> GridBus {
    has line_id: str;
    has from_bus_id: str;
    has to_bus_id: str;
    has switch_id: str;
    has capacity_kw: float;
    has switch_closed: bool = True;
    has physically_faulted: bool = False;
}

def conducts(line: PowerLine) -> bool {
    return line.switch_closed and not line.physically_faulted;
}
