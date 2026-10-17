"""Verify only the local recovery_ui_fixture server; never target a live AI server."""
import json
import sys
from urllib.request import Request, urlopen


def values(value):
    if isinstance(value, dict):
        return {key: values(item) for key, item in value.items() if not key.startswith("_jac_")}
    if isinstance(value, list):
        return [values(item) for item in value]
    return value


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8013"

    def call(name, **body):
        request = Request(base + "/function/" + name,
                          data=json.dumps(body).encode(),
                          headers={"Content-Type": "application/json"})
        with urlopen(request, timeout=60) as response:
            envelope = json.load(response)
        assert envelope["ok"], envelope
        return values(envelope["data"]["result"])

    try:
        call("reset_simulation")
        call("inject_fault", fault_id="FAULT-LINE-A-H")
        observed = call("get_grid_state")
        stale = call("run_triage", fault_id="FAULT-LINE-A-H",
                     generation_id=observed["generation_id"],
                     expected_revision=observed["revision"] + 1)
        assert stale["status"] == "stale", stale
        assert stale["recovery_result"]["applied_actions"] == []
        assert stale["recovery_result"]["execution_mode"] == "none"
        after_stale = call("get_grid_state")
        assert after_stale["revision"] == observed["revision"]
        assert after_stale["metrics"] == observed["metrics"]
        print("PASS stale revision rejected without changing grid")

        for fault, outcome in [("FAULT-LINE-A-H", "partial"),
                               ("FAULT-SOURCE-A", "partial"),
                               ("FAULT-INSUFFICIENT-BACKUP", "infeasible")]:
            call("reset_simulation")
            assert call("get_agent_events") == []
            call("inject_fault", fault_id=fault)
            triage = call("run_triage", fault_id=fault)
            result = triage["recovery_result"]
            assert result["outcome"] == outcome, result
            assert result["execution_mode"] == ("none" if outcome == "infeasible" else "deterministic")
            events = call("get_agent_events", run_id=triage["run_id"])
            assert [e["sequence"] for e in events] == list(range(1, len(events) + 1))
            assert all(e["run_id"] == result["run_id"] for e in events)
            assert call("get_agent_events") == events
            assert call("get_recovery_result", run_id=result["run_id"]) == result
            state = call("get_grid_state")
            assert state["metrics"] == result["after_metrics"]
            assert fault in state["active_fault_ids"]
            applied = [e for e in events if e["outcome"] == "applied"]
            assert bool(applied) == bool(result["applied_actions"])
            if fault == "FAULT-LINE-A-H":
                assert any(e["outcome"] == "rejected" for e in events)
                assert any(e["kind"] == "revision" for e in events)
            print("PASS", fault, outcome, len(events), "ordered events")
    finally:
        call("reset_simulation")
    assert call("get_agent_events") == []
    print("PASS reset clears current-generation evidence")


if __name__ == "__main__":
    main()
