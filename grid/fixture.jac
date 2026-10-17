"""Healthy twelve-bus fixture; fault scenarios are added in Task 2."""

import from grid.graph { Grid, GridBus, Source, Load, PowerLine }

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

    src_a +>:PowerLine(line_id="LINE-A-H", switch_id="SW-A-H", capacity_kw=65.0):+> hospital;
    hospital +>:PowerLine(line_id="LINE-H-W", switch_id="SW-H-W", capacity_kw=30.0):+> water;
    src_a +>:PowerLine(line_id="LINE-A-L", switch_id="SW-A-L", capacity_kw=50.0):+> lab;
    lab +>:PowerLine(line_id="LINE-L-O", switch_id="SW-L-O", capacity_kw=30.0):+> offices;

    src_b +>:PowerLine(line_id="LINE-B-D", switch_id="SW-B-D", capacity_kw=55.0):+> data;
    data +>:PowerLine(line_id="LINE-D-P", switch_id="SW-D-P", capacity_kw=25.0):+> pump;
    src_b +>:PowerLine(line_id="LINE-B-HM", switch_id="SW-B-HM", capacity_kw=30.0):+> homes;

    src_r +>:PowerLine(line_id="LINE-R-C", switch_id="SW-R-C", capacity_kw=30.0):+> clinic;
    clinic +>:PowerLine(line_id="LINE-C-LT", switch_id="SW-C-LT", capacity_kw=15.0):+> lights;

    # Normally open ties give real alternate routes without silently conducting.
    src_b +>:PowerLine(line_id="TIE-B-H", switch_id="SW-TIE-B-H", capacity_kw=65.0, switch_closed=False):+> hospital;
    src_b +>:PowerLine(line_id="TIE-B-A", switch_id="SW-TIE-B-A", capacity_kw=40.0, switch_closed=False):+> src_a;
    src_r +>:PowerLine(line_id="TIE-R-A", switch_id="SW-TIE-R-A", capacity_kw=40.0, switch_closed=False):+> src_a;

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
