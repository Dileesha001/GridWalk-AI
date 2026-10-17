import from .topology_examples { topology_example }
import from .recovery_decode { decode_recovery, decode_triage, decode_events, check_run_evidence }

def result_data() -> any {
    before: any = JSON.parse(JSON.stringify(topology_example("line_fault")));
    after: any = JSON.parse(JSON.stringify(topology_example("baseline")));
    return JSON.parse(JSON.stringify({"run_id": "TEST-RUN", "fault_id": "FAULT-LINE-A-H", "outcome": "recovered", "execution_mode": "primary_ai", "applied_actions": [{"action_type": "CLOSE_SWITCH", "target_id": "SW-TIE-B-H"}], "before_metrics": before.metrics, "after_metrics": after.metrics, "incident_summary": "Fixed decoder test evidence", "proposal_count": 1, "revision_count": 0, "elapsed_ms": 10, "failure_reason": None}));
}

def event_data(sequence: int, actor: str = "monitor", kind: str = "observation", outcome: str = "info") -> any {
    return JSON.parse(JSON.stringify({"run_id": "TEST-RUN", "sequence": sequence, "actor": actor, "kind": kind, "outcome": outcome, "summary": "Fixed decoder event", "evidence": ""}));
}

test "canonical recovery preserves server metrics mode and committed actions" {
    result = decode_recovery(result_data(), "TEST-RUN");
    assert result.after_metrics.served_kw == 205;
    assert str(result.execution_mode) == "primary_ai";
    assert len(result.applied_actions) == 1;
    raw = result_data(); raw.execution_mode = "deterministic";
    assert str(decode_recovery(raw).execution_mode) == "deterministic";
}

test "unknown modes malformed measurements and inconsistent success fail closed" {
    for key in ["mode", "metrics", "action", "outcome", "counts", "missing"] {
        raw = result_data();
        if key == "mode" { raw.execution_mode = "preview"; }
        elif key == "metrics" { raw.after_metrics.served_kw = "205"; }
        elif key == "action" { raw.applied_actions[0].action_type = "REPAIR_LINE"; }
        elif key == "outcome" { raw.after_metrics.unmet_kw = 25; }
        elif key == "counts" { raw.elapsed_ms = -1; }
        else { raw.failure_reason = 5; }
        rejected = False;
        try { decode_recovery(raw); } except Exception { rejected = True; }
        assert rejected;
    }
}

test "uncommitted failure retains measured unmet demand and no execution claim" {
    raw = result_data(); raw.applied_actions = []; raw.execution_mode = "none"; raw.outcome = "infeasible";
    raw.after_metrics = raw.before_metrics; raw.failure_reason = "No accepted plan";
    result = decode_recovery(raw);
    assert result.after_metrics.unmet_kw == 60 and str(result.execution_mode) == "none";
    raw.execution_mode = "primary_ai"; rejected = False;
    try { decode_recovery(raw); } except Exception { rejected = True; }
    assert rejected;
}

test "events sort and deduplicate identical sequences without losing rejection evidence" {
    second = event_data(2, "validator", "validation", "rejected"); second.evidence = "Tier 1 shedding rejected";
    events = decode_events([second, event_data(1), second], "TEST-RUN");
    assert len(events) == 2 and events[0].sequence == 1;
    assert events[1].evidence == "Tier 1 shedding rejected";
}

test "mixed runs event gaps conflicting duplicates and unknown enums are rejected" {
    for key in ["run", "gap", "duplicate", "enum"] {
        first = event_data(1); second = event_data(2);
        if key == "run" { second.run_id = "OLD-RUN"; }
        elif key == "gap" { second.sequence = 3; }
        elif key == "duplicate" { second.sequence = 1; second.summary = "Different evidence"; }
        else { second.actor = "invented"; }
        rejected = False;
        try { decode_events([first, second], "TEST-RUN"); } except Exception { rejected = True; }
        assert rejected;
    }
}

test "committed outcomes need accepted validation and application for the same run" {
    result = decode_recovery(result_data());
    events = decode_events([event_data(1), event_data(2, "validator", "validation", "accepted"), event_data(3, "simulation", "application", "applied")], result.run_id);
    check_run_evidence(result, events);
    rejected = False;
    try { check_run_evidence(result, events[:2]); } except Exception { rejected = True; }
    assert rejected;
}

test "recovery result rejects a different requested run identity" {
    rejected = False;
    try { decode_recovery(result_data(), "NEW-RUN"); } except Exception { rejected = True; }
    assert rejected;
}

test "triage snapshots must match result measurements and committed status" {
    before: any = JSON.parse(JSON.stringify(topology_example("line_fault")));
    after: any = JSON.parse(JSON.stringify(topology_example("baseline")));
    raw: any = JSON.parse(JSON.stringify({"run_id": "TEST-RUN", "fault_id": "FAULT-LINE-A-H", "status": "applied", "before_state": before, "after_state": after, "recovery_result": result_data()}));
    assert decode_triage(raw, "FAULT-LINE-A-H").run_id == "TEST-RUN";
    raw.recovery_result.after_metrics.served_kw = 200; rejected = False;
    try { decode_triage(raw, "FAULT-LINE-A-H"); } except Exception { rejected = True; }
    assert rejected;
}


test "bounded and deterministic failures retain uncommitted server evidence" {
    before: any = JSON.parse(JSON.stringify(topology_example("line_fault")));
    for status in ["budget_exhausted", "fallback_failed"] {
        result: any = result_data();
        result.outcome = "failed";
        result.execution_mode = "none";
        result.applied_actions = [];
        result.after_metrics = before.metrics;
        result.failure_reason = "No recovery plan committed";
        raw: any = JSON.parse(JSON.stringify({
            "run_id": "TEST-RUN", "fault_id": "FAULT-LINE-A-H",
            "status": status, "before_state": before,
            "after_state": before, "recovery_result": result
        }));
        assert str(decode_triage(raw, "FAULT-LINE-A-H").status) == status;
    }
}
