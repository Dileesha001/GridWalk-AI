"""Client-runtime checks for the first Member 3 milestone; no backend or AI needed."""

import from .models { EventView, ordered_events, critical_label, mode_label }
import from .preview { preview_grid, preview_recovery, preview_events }
import from .decode { grid_value, metrics_value, number, unwrap, recovery_value }

test "preview baseline has consistent demand and dispatch" {
    grid = preview_grid();
    assert len(grid.sources) + len(grid.loads) == 12;
    assert grid.metrics.active_faults == 0;
    assert grid.metrics.unmet_kw == 0.0;
    total = 0.0;
    for load in grid.loads { total += load.served_kw; }
    assert total == grid.metrics.dispatch_kw;
    decoded = grid_value(JSON.parse(JSON.stringify(grid)));
    assert decoded.version == grid.version;
    assert len(decoded.lines) == len(grid.lines);
}

test "preview scenarios retain faults and honest execution labels" {
    for scenario in ["source_reduction", "line_failure", "insufficient_backup"] {
        fault = preview_grid("fault", scenario);
        recovered = preview_grid("recovered", scenario);
        assert fault.metrics.unmet_kw > 0;
        assert recovered.metrics.active_faults == 1;
        result = preview_recovery(scenario);
        assert result.mode == "preview";
        assert result.applied_action_count == 0;
        assert preview_events("recovered")[0].actor == "Preview";
        if scenario == "line_failure" { assert recovered.lines[0].faulted; }
        if scenario == "insufficient_backup" {
            assert result.outcome == "infeasible";
            assert result.after.unmet_kw > 0;
        }
    }
}

test "events are ordered deduplicated and isolated by run" {
    items = [EventView(run_id="old", sequence=1, actor="Planner", kind="proposal", message="Old run"),
        EventView(run_id="now", sequence=2, actor="Validator", kind="rejected", message="Over capacity"),
        EventView(run_id="now", sequence=1, actor="Monitor", kind="observation", message="Fault detected"),
        EventView(run_id="now", sequence=2, actor="Validator", kind="rejected", message="Over capacity")];
    selected = ordered_events(items, "now");
    assert len(selected) == 2;
    assert selected[0].sequence == 1;
    assert selected[1].sequence == 2;
}

test "malformed numbers and server rejections fail closed" {
    for value in [-1, True, "120", None] {
        rejected = False;
        try { _ = number({"kw": value}, "kw"); }
        except Exception { rejected = True; }
        assert rejected;
    }
    rejected = False;
    try { _ = unwrap({"ok": False, "data": {}}); }
    except Exception { rejected = True; }
    assert rejected;
}

test "duplicate IDs and unknown endpoints are rejected" {
    for issue in ["duplicate", "endpoint"] {
        raw: any = JSON.parse(JSON.stringify(preview_grid()));
        if issue == "duplicate" { raw.loads[0].id = raw.sources[0].id; }
        else { raw.lines[0].to_id = "missing"; }
        rejected = False;
        try { _ = grid_value(raw); }
        except Exception { rejected = True; }
        assert rejected;
    }
}

test "zero critical denominator is displayed as unavailable" {
    raw: any = JSON.parse(JSON.stringify(preview_grid().metrics));
    raw.critical_served_pct = None;
    assert critical_label(metrics_value(raw).critical_served_pct) == "N/A";
    assert mode_label("deterministic") == "Deterministic fallback";
}

test "live recovery cannot claim preview mode" {
    raw: any = JSON.parse(JSON.stringify(preview_recovery("line_failure")));
    rejected = False;
    try { _ = recovery_value(raw); }
    except Exception { rejected = True; }
    assert rejected;
}
