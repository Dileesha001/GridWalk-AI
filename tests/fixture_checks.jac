"""Task 1 checks for the healthy fictional grid."""

import from grid.fixture { build_healthy_fixture, fixture_sources, fixture_loads, fixture_lines }
import from grid.graph { PowerLine }

test "healthy fixture has distinct entities and a feasible reference flow" {
    grid = build_healthy_fixture();
    sources = fixture_sources(grid);
    loads = fixture_loads(grid);
    lines = fixture_lines(grid);

    assert len(sources) == 3;
    assert len(loads) == 9;
    assert len(lines) == 12;

    source_ids = [s.bus_id for s in sources];
    load_ids = [l.bus_id for l in loads];
    line_ids = [e.line_id for e in lines];
    switch_ids = [e.switch_id for e in lines];
    assert len(set(source_ids + load_ids)) == 12;
    assert len(set(line_ids)) == 12;
    assert len(set(switch_ids)) == 12;
    assert len([e for e in lines if not e.switch_closed]) == 3;
    assert len([e for e in lines if e.physically_faulted]) == 0;

    source_by_id = {s.bus_id: s for s in sources};
    load_by_id = {l.bus_id: l for l in loads};
    line_by_id = {e.line_id: e for e in lines};

    # Verify the conducting tree and the separate alternate hospital route.
    assert set([n.bus_id for n in [source_by_id["SRC-A"] ->:PowerLine:->]]) == {"LOAD-HOSP", "LOAD-LAB"};
    assert set([n.bus_id for n in [source_by_id["SRC-B"] ->:PowerLine:->]]) == {"LOAD-DATA", "LOAD-HOMES", "LOAD-HOSP", "SRC-A"};
    assert set([n.bus_id for n in [source_by_id["SRC-R"] ->:PowerLine:->]]) == {"LOAD-CLINIC", "SRC-A"};
    assert [n.bus_id for n in [load_by_id["LOAD-HOSP"] ->:PowerLine:->]] == ["LOAD-WATER"];

    # A reference dispatch that serves every load on normally closed lines.
    a_kw = sum([load_by_id[k].demand_kw for k in ["LOAD-HOSP", "LOAD-WATER", "LOAD-LAB", "LOAD-OFFICE"]]);
    b_kw = sum([load_by_id[k].demand_kw for k in ["LOAD-DATA", "LOAD-PUMP", "LOAD-HOMES"]]);
    r_kw = sum([load_by_id[k].demand_kw for k in ["LOAD-CLINIC", "LOAD-LIGHTS"]]);
    assert a_kw == 105.0 and a_kw <= source_by_id["SRC-A"].capacity_kw;
    assert b_kw == 75.0 and b_kw <= source_by_id["SRC-B"].capacity_kw;
    assert r_kw == 25.0 and r_kw <= source_by_id["SRC-R"].capacity_kw;
    assert sum([l.demand_kw for l in loads]) == a_kw + b_kw + r_kw;
    assert sum([l.demand_kw for l in loads if l.tier == 1]) == 105.0;
    assert sum([s.capacity_kw for s in sources]) == 275.0;
    assert source_by_id["SRC-R"].capacity_kw - r_kw == 35.0;

    reference_flow: dict[str, float] = {
        "LINE-A-H": 60.0, "LINE-H-W": 25.0,
        "LINE-A-L": 45.0, "LINE-L-O": 25.0,
        "LINE-B-D": 50.0, "LINE-D-P": 20.0,
        "LINE-B-HM": 25.0,
        "LINE-R-C": 25.0, "LINE-C-LT": 10.0,
        "TIE-B-H": 0.0, "TIE-B-A": 0.0, "TIE-R-A": 0.0,
    };
    assert len(reference_flow) == len(lines);
    for line in lines {
        assert line.line_id in reference_flow;
        assert reference_flow[line.line_id] <= line.capacity_kw;
        if not line.switch_closed { assert reference_flow[line.line_id] == 0.0; }
    }

    # Demand at each branching load equals incoming less outgoing transfer.
    assert reference_flow["LINE-A-H"] - reference_flow["LINE-H-W"] == load_by_id["LOAD-HOSP"].demand_kw;
    assert reference_flow["LINE-H-W"] == load_by_id["LOAD-WATER"].demand_kw;
    assert reference_flow["LINE-A-L"] - reference_flow["LINE-L-O"] == load_by_id["LOAD-LAB"].demand_kw;
    assert reference_flow["LINE-L-O"] == load_by_id["LOAD-OFFICE"].demand_kw;
    assert reference_flow["LINE-B-D"] - reference_flow["LINE-D-P"] == load_by_id["LOAD-DATA"].demand_kw;
    assert reference_flow["LINE-D-P"] == load_by_id["LOAD-PUMP"].demand_kw;
    assert reference_flow["LINE-B-HM"] == load_by_id["LOAD-HOMES"].demand_kw;
    assert reference_flow["LINE-R-C"] - reference_flow["LINE-C-LT"] == load_by_id["LOAD-CLINIC"].demand_kw;
    assert reference_flow["LINE-C-LT"] == load_by_id["LOAD-LIGHTS"].demand_kw;
    assert reference_flow["LINE-A-H"] + reference_flow["LINE-A-L"] == a_kw;
    assert reference_flow["LINE-B-D"] + reference_flow["LINE-B-HM"] == b_kw;
    assert reference_flow["LINE-R-C"] == r_kw;
    assert not line_by_id["TIE-B-H"].switch_closed;
}
