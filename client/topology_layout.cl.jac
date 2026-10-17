"""Presentation coordinates and labels; service and conducting states come from data."""

sv import from ..shared.contracts { GraphState, LineView }

def:pub topology_positions(grid: GraphState) -> dict[str, tuple[float, float]] {
    positions: dict[str, tuple[float, float]] = {
        "SRC-A": (180.0, 115.0), "SRC-B": (525.0, 115.0), "SRC-R": (835.0, 115.0),
        "LOAD-HOSP": (100.0, 300.0), "LOAD-WATER": (100.0, 495.0),
        "LOAD-LAB": (285.0, 300.0), "LOAD-OFFICE": (285.0, 495.0),
        "LOAD-DATA": (480.0, 300.0), "LOAD-PUMP": (480.0, 495.0),
        "LOAD-HOMES": (660.0, 300.0), "LOAD-CLINIC": (840.0, 300.0),
        "LOAD-LIGHTS": (840.0, 495.0)
    };
    extra_ids = sorted([item.bus_id for item in grid.sources if item.bus_id not in positions] + [item.bus_id for item in grid.loads if item.bus_id not in positions]);
    for (i, identity) in enumerate(extra_ids) { positions[identity] = (100.0 + (i % 5) * 185.0, 690.0 + (i // 5) * 150.0); }
    return positions;
}

def:pub topology_height(grid: GraphState) -> float {
    points = topology_positions(grid);
    height = 580.0;
    for item in grid.sources { height = max(height, points[item.bus_id][1] + 80.0); }
    for item in grid.loads { height = max(height, points[item.bus_id][1] + 80.0); }
    return height;
}

def:pub line_label(line: LineView) -> str {
    return ("FAULTED" if line.physically_faulted else "Healthy") + " / " + ("Closed" if line.switch_closed else "Open");
}

def:pub line_color(line: LineView) -> str {
    if line.physically_faulted { return "var(--fault)"; }
    if not line.switch_closed { return "var(--wire-open)"; }
    return "var(--powered)" if line.conducting else "var(--wire-open)";
}

def:pub source_style(status: str) -> str {
    return "source-warning" if status in ["derated", "fault", "offline"] else "powered" if status == "online" else "unknown";
}

def:pub load_style(status: str) -> str {
    if status in ["powered", "rerouted", "shed"] { return status; }
    if status == "partial" { return "shed"; }
    return "fault" if status in ["unmet", "unserved"] else "unknown";
}

def:pub wire_path(grid: GraphState, line: LineView) -> str {
    points = topology_positions(grid);
    start = points[line.from_bus_id];
    end = points[line.to_bus_id];
    if start[1] == end[1] {
        control_y = -65.0 if line.line_id == "TIE-R-A" else 15.0;
        return f"M {start[0]} {start[1]} Q {(start[0] + end[0]) / 2} {control_y} {end[0]} {end[1]}";
    }
    return f"M {start[0]} {start[1]} L {end[0]} {end[1]}";
}

def:pub wire_midpoint(grid: GraphState, line: LineView) -> tuple[float, float] {
    points = topology_positions(grid);
    start = points[line.from_bus_id];
    end = points[line.to_bus_id];
    return ((start[0] + end[0]) / 2, 25.0 if line.line_id == "TIE-R-A" else 65.0 if start[1] == end[1] else (start[1] + end[1]) / 2);
}
