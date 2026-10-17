"""Healthy twelve-bus fixture; fault scenarios are added in Task 2."""

import from grid.graph { Grid, GridBus, Source, Load, PowerLine }

"""Stable IDs for the three named Task 2 fault scenarios."""
glob FAULT_SOURCE_A: str = "FAULT-SOURCE-A";
glob FAULT_LINE_A_H: str = "FAULT-LINE-A-H";
glob FAULT_INSUFFICIENT_BACKUP: str = "FAULT-INSUFFICIENT-BACKUP";

obj FaultScenario {
    has fault_id: str;
    has source_capacities_kw: dict[str, float];
    has fault_line_ids: list[str];
}

def fault_ids() -> list[str] {
    return [FAULT_SOURCE_A, FAULT_LINE_A_H, FAULT_INSUFFICIENT_BACKUP];
}

def fault_scenario(fault_id: str) -> FaultScenario | None {
    if fault_id == FAULT_SOURCE_A {
        return FaultScenario(fault_id=fault_id, source_capacities_kw={"SRC-A": 50.0}, fault_line_ids=[]);
    }
    if fault_id == FAULT_LINE_A_H {
        return FaultScenario(fault_id=fault_id, source_capacities_kw={}, fault_line_ids=["LINE-A-H"]);
    }
    if fault_id == FAULT_INSUFFICIENT_BACKUP {
        return FaultScenario(fault_id=fault_id, source_capacities_kw={"SRC-A": 50.0, "SRC-R": 30.0}, fault_line_ids=[]);
    }
    return None;
}

def add_line(from_bus: GridBus, to_bus: GridBus, line_id: str, switch_id: str,
             capacity_kw: float, switch_closed: bool = True) {
    from_bus +>:PowerLine(
        line_id=line_id, from_bus_id=from_bus.bus_id, to_bus_id=to_bus.bus_id,
        switch_id=switch_id, capacity_kw=capacity_kw, switch_closed=switch_closed
    ):+> to_bus;
}

def build_healthy_fixture() -> Grid {
    grid = Grid(grid_id="GRID-01");
    root ++> grid;

    src_a = Source(bus_id="SRC-A", label="North substation", capacity_kw=120.0);
    src_b = Source(bus_id="SRC-B", label="South substation", capacity_kw=95.0);
    src_r = Source(bus_id="SRC-R", label="Reserve generator", capacity_kw=60.0, is_backup=True);

    hospital = Load(bus_id="LOAD-HOSP", label="Hospital", demand_kw=35.0, tier=1);
    water = Load(bus_id="LOAD-WATER", label="Water treatment", demand_kw=25.0, tier=1);
    lab = Load(bus_id="LOAD-LAB", label="Research lab", demand_kw=20.0, tier=2);
    offices = Load(bus_id="LOAD-OFFICE", label="Offices", demand_kw=25.0, tier=3);
    data = Load(bus_id="LOAD-DATA", label="Data center", demand_kw=30.0, tier=1);
    pump = Load(bus_id="LOAD-PUMP", label="Pump station", demand_kw=20.0, tier=2);
    homes = Load(bus_id="LOAD-HOMES", label="Housing", demand_kw=25.0, tier=3);
    clinic = Load(bus_id="LOAD-CLINIC", label="Clinic", demand_kw=15.0, tier=1);
    lights = Load(bus_id="LOAD-LIGHTS", label="Street lighting", demand_kw=10.0, tier=3);

    grid ++> src_a;
    grid ++> src_b;
    grid ++> src_r;
    grid ++> hospital;
    grid ++> water;
    grid ++> lab;
    grid ++> offices;
    grid ++> data;
    grid ++> pump;
    grid ++> homes;
    grid ++> clinic;
    grid ++> lights;

    add_line(src_a, hospital, "LINE-A-H", "SW-A-H", 65.0);
    add_line(hospital, water, "LINE-H-W", "SW-H-W", 30.0);
    add_line(src_a, lab, "LINE-A-L", "SW-A-L", 50.0);
    add_line(lab, offices, "LINE-L-O", "SW-L-O", 30.0);

    add_line(src_b, data, "LINE-B-D", "SW-B-D", 55.0);
    add_line(data, pump, "LINE-D-P", "SW-D-P", 25.0);
    add_line(src_b, homes, "LINE-B-HM", "SW-B-HM", 30.0);

    add_line(src_r, clinic, "LINE-R-C", "SW-R-C", 30.0);
    add_line(clinic, lights, "LINE-C-LT", "SW-C-LT", 15.0);

    # Normally open ties give real alternate routes without silently conducting.
    add_line(src_b, hospital, "TIE-B-H", "SW-TIE-B-H", 65.0, False);
    add_line(src_b, src_a, "TIE-B-A", "SW-TIE-B-A", 40.0, False);
    add_line(src_r, src_a, "TIE-R-A", "SW-TIE-R-A", 40.0, False);

    return grid;
}

def fixture_sources(grid: Grid) -> list[Source] {
    return [grid -->[?:Source]];
}

def fixture_loads(grid: Grid) -> list[Load] {
    return [grid -->[?:Load]];
}

def fixture_lines(grid: Grid) -> list[PowerLine] {
    lines: list[PowerLine] = [];
    for bus in [grid -->[?:GridBus]] {
        for line in [edge bus ->:PowerLine:->] {
            lines.append(line);
        }
    }
    return lines;
}
