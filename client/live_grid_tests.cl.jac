import from .grid_decode { decode_grid, decode_grid_response }
import from .topology_examples { topology_example }
import from .network_geometry { network_positions, network_height, network_route }

test "canonical decoding preserves generation signed flows and server metrics" {
    raw: any = JSON.parse(JSON.stringify(topology_example("rerouted")));
    grid = decode_grid_response({"ok": True, "data": {"result": raw, "reports": []}});
    assert grid.generation_id == "FIXED-DISPLAY-EXAMPLE";
    assert grid.lines[10].transfer_kw == -35;
    assert grid.lines[0].physically_faulted and grid.lines[0].switch_closed and not grid.lines[0].conducting;
    assert grid.metrics.served_kw == 180;
    assert grid.metrics.shed_kw == 25 and grid.metrics.unmet_kw == 25;
}

test "missing canonical metadata and malformed metrics are rejected" {
    for issue in ["generation", "revision", "fraction", "number", "missing", "critical", "count"] {
        raw: any = JSON.parse(JSON.stringify(topology_example()));
        if issue == "generation" { raw.generation_id = ""; }
        elif issue == "revision" { raw.revision = True; }
        elif issue == "fraction" { raw.revision = 1.5; }
        elif issue == "number" { raw.metrics.served_kw = "205"; }
        elif issue == "missing" { raw.metrics = {}; }
        elif issue == "critical" { raw.metrics.critical_preserved_pct = 101; }
        else { raw.metrics.active_fault_count = 1; }
        rejected = False;
        try { decode_grid(raw); } except Exception { rejected = True; }
        assert rejected, issue;
    }
}

test "duplicate bus switch IDs and unknown endpoints fail closed" {
    for issue in ["bus", "switch", "endpoint", "source_capacity", "service"] {
        raw: any = JSON.parse(JSON.stringify(topology_example()));
        if issue == "bus" { raw.loads[0].bus_id = raw.sources[0].bus_id; }
        elif issue == "switch" { raw.lines[0].switch_id = raw.lines[1].switch_id; }
        elif issue == "endpoint" { raw.lines[0].to_bus_id = "missing"; }
        elif issue == "source_capacity" { raw.sources[0].dispatched_kw = 999; }
        else { raw.loads[0].served_kw = 999; }
        rejected = False;
        try { decode_grid(raw); } except Exception { rejected = True; }
        assert rejected, issue;
    }
}

test "physically faulted and open lines cannot claim conduction or transfer" {
    for issue in ["fault", "open", "transfer", "finite"] {
        raw: any = JSON.parse(JSON.stringify(topology_example("line_fault")));
        if issue == "fault" { raw.lines[0].conducting = True; }
        elif issue == "open" { raw.lines[2].switch_closed = False; }
        elif issue == "transfer" { raw.lines[0].transfer_kw = 1; }
        else { raw.lines[0].transfer_kw = Number.POSITIVE_INFINITY; }
        rejected = False;
        try { decode_grid(raw); } except Exception { rejected = True; }
        assert rejected, issue;
    }
}

test "null critical denominator remains unavailable and wrappers are required" {
    raw: any = JSON.parse(JSON.stringify(topology_example()));
    raw.metrics.critical_preserved_pct = None;
    assert decode_grid(raw).metrics.critical_preserved_pct is None;
    for bad in [{"ok": False, "data": {"result": raw}}, {"ok": True, "data": {"reports": []}}, {"ok": True, "data": {"result": None}}] {
        rejected = False;
        try { decode_grid_response(bad); } except Exception { rejected = True; }
        assert rejected;
    }
}

test "live geometry keeps stable IDs and places new buses inside an expanded canvas" {
    raw: any = JSON.parse(JSON.stringify(topology_example()));
    before = network_positions(decode_grid(raw));
    raw.loads[0].bus_id = "LOAD-NEW";
    raw.lines[0].to_bus_id = "LOAD-NEW";
    raw.lines[1].from_bus_id = "LOAD-NEW";
    raw.lines[9].to_bus_id = "LOAD-NEW";
    grid = decode_grid(raw); points = network_positions(grid);
    assert points["SRC-A"] == before["SRC-A"];
    assert points["LOAD-NEW"][1] >= 364;
    assert network_height(grid, points) > 344;
    assert len(network_route(grid.lines[0], points)) > 0;
}
