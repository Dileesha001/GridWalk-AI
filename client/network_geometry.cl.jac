"""Stable presentation geometry; line states and measurements always come from data."""
sv import from ..shared.contracts { GraphState, LineView }

def:pub network_positions(grid: GraphState) -> dict[str, tuple[int, int]] {
    points: dict[str, tuple[int, int]] = {
        "SRC-A": (185, 36), "SRC-B": (365, 36), "SRC-R": (550, 36),
        "LOAD-HOSP": (10, 116), "LOAD-WATER": (10, 196), "LOAD-LAB": (185, 116),
        "LOAD-OFFICE": (185, 196), "LOAD-DATA": (365, 116), "LOAD-PUMP": (365, 196),
        "LOAD-HOMES": (365, 276), "LOAD-CLINIC": (550, 116), "LOAD-LIGHTS": (550, 196)
    };
    extra = sorted([item.bus_id for item in grid.sources if item.bus_id not in points] + [item.bus_id for item in grid.loads if item.bus_id not in points]);
    for (index, identity) in enumerate(extra) { points[identity] = (10 + (index % 4) * 180, 364 + (index // 4) * 80); }
    return points;
}

def:pub network_height(grid: GraphState, points: dict[str, tuple[int, int]]) -> int {
    height = 344;
    for item in grid.sources { height = max(height, points[item.bus_id][1] + 68); }
    for item in grid.loads { height = max(height, points[item.bus_id][1] + 68); }
    return height;
}

def:pub network_route(line: LineView, points: dict[str, tuple[int, int]]) -> str {
    start = points[line.from_bus_id]; end = points[line.to_bus_id];
    x1 = start[0] + 80; y1 = start[1] + 56; x2 = end[0] + 80; y2 = end[1];
    if start[1] == end[1] {
        if line.from_bus_id == "SRC-R" or line.to_bus_id == "SRC-R" { return f"M {x1} {start[1]} V 14 H {x2} V {end[1]}"; }
        return f"M {start[0]} {start[1] + 28} H {end[0] + 160}" if start[0] > end[0] else f"M {start[0] + 160} {start[1] + 28} H {end[0]}";
    }
    if abs(end[1] - start[1]) >= 200 {
        side = max(start[0], end[0]) + 172;
        return f"M {start[0] + 160} {start[1] + 28} H {side} V {end[1] + 28} H {end[0] + 160}";
    }
    if line.line_id == "TIE-B-H" { return f"M {start[0]} {start[1] + 28} H {start[0] - 10} V {end[1] - 8} H {x2} V {y2}"; }
    return f"M {x1} {y1} V {(y1 + y2) / 2} H {x2} V {y2}";
}
