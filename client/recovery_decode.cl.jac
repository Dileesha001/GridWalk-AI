"""Validate consumed recovery contracts and correlate complete server evidence."""
sv import from ..shared.contracts { AgentEvent, RecoveryResult }
sv import from ..agents.orchestration { TriageResult }
import from .decode { object_value, text, number, integer, array }
import from .grid_decode { identity, decode_grid, decode_metrics, same_metrics }

def:pub decode_recovery(raw: any, run_id: str = "") -> RecoveryResult {
    data = object_value(raw);
    actual_id = identity(data, "run_id"); identity(data, "fault_id");
    if run_id and actual_id != run_id { raise ValueError("Recovery result belongs to another run."); }
    outcome = text(data, "outcome"); mode = text(data, "execution_mode");
    if outcome not in ["no_action", "recovered", "partial", "infeasible", "failed"] or mode not in ["none", "primary_ai", "backup_ai", "deterministic"] { raise ValueError("Unknown recovery outcome or execution mode."); }
    identity(data, "incident_summary");
    for key in ["proposal_count", "revision_count", "elapsed_ms"] {
        if not Number.isSafeInteger(integer(data, key)) { raise ValueError("Invalid recovery count."); }
    }
    if integer(data, "revision_count") > integer(data, "proposal_count") { raise ValueError("Invalid proposal/revision counts."); }
    if "failure_reason" not in data or (data["failure_reason"] is not None and not isinstance(data["failure_reason"], str)) { raise ValueError("Invalid recovery failure reason."); }
    decode_metrics(data["before_metrics"]); after = decode_metrics(data["after_metrics"]);
    actions = array(data, "applied_actions"); seen: list[str] = [];
    for action in actions {
        row = object_value(action); kind = text(row, "action_type"); target = identity(row, "target_id");
        if kind not in ["SHED_LOAD", "CLOSE_SWITCH"] or target in seen { raise ValueError("Invalid committed action."); }
        seen.append(target);
    }
    if bool(actions) != (mode != "none") { raise ValueError("Committed actions and execution mode disagree."); }
    if outcome in ["recovered", "partial"] and not actions { raise ValueError("A recovery outcome requires committed actions."); }
    if outcome == "recovered" and after.unmet_kw != 0 { raise ValueError("Recovered result still has unmet demand."); }
    if outcome == "partial" and (after.unmet_kw <= 0 or after.critical_preserved_pct != 100) { raise ValueError("Partial recovery has inconsistent measured service."); }
    return data as RecoveryResult;
}

def sequence_of(item: AgentEvent) -> int { return item.sequence; }

def:pub decode_events(raw: any, run_id: str = "") -> list[AgentEvent] {
    if not isinstance(raw, list) { raise ValueError("Missing ordered agent events."); }
    items: list[AgentEvent] = []; actual_id = run_id;
    for value in raw {
        row = object_value(value); identity(row, "run_id");
        if not actual_id { actual_id = text(row, "run_id"); }
        if text(row, "run_id") != actual_id { raise ValueError("Agent events belong to different runs."); }
        if integer(row, "sequence") < 1 or not Number.isSafeInteger(row["sequence"]) { raise ValueError("Invalid event sequence."); }
        if text(row, "actor") not in ["monitor", "planner", "validator", "simulation", "auditor", "system"] or text(row, "kind") not in ["observation", "proposal", "validation", "revision", "application", "fallback", "audit", "failure"] or text(row, "outcome") not in ["info", "accepted", "rejected", "applied", "error"] { raise ValueError("Unknown agent event state."); }
        identity(row, "summary"); text(row, "evidence");
        items.append(row as AgentEvent);
    }
    ordered: list[AgentEvent] = [];
    for item in sorted(items, key=sequence_of) {
        if ordered and ordered[-1].sequence == item.sequence {
            previous = ordered[-1];
            if previous.actor != item.actor or previous.kind != item.kind or previous.outcome != item.outcome or previous.summary != item.summary or previous.evidence != item.evidence { raise ValueError("Conflicting duplicate agent event."); }
            continue;
        }
        if item.sequence != len(ordered) + 1 { raise ValueError("Incomplete ordered event history."); }
        ordered.append(item);
    }
    return ordered;
}

def:pub check_run_evidence(result: RecoveryResult, events: list[AgentEvent]) -> None {
    if not events or events[0].run_id != result.run_id { raise ValueError("Run evidence is unavailable."); }
    applied = [item for item in events if str(item.actor) == "simulation" and str(item.kind) == "application" and str(item.outcome) == "applied"];
    accepted = [item for item in events if str(item.actor) == "validator" and str(item.outcome) == "accepted"];
    if bool(result.applied_actions) != bool(applied) or (applied and not accepted) { raise ValueError("Committed result is missing matching validation/application evidence."); }
}

def:pub decode_triage(raw: any, fault_id: str) -> TriageResult {
    data = object_value(raw); run_id = identity(data, "run_id");
    if text(data, "fault_id") != fault_id or text(data, "status") not in ["applied", "already_applied", "exhausted", "stale", "provider_failed", "budget_exhausted", "fallback_failed"] { raise ValueError("Unexpected recovery response."); }
    before = decode_grid(data["before_state"]); after = decode_grid(data["after_state"]);
    result = decode_recovery(data["recovery_result"], run_id);
    if result.fault_id != fault_id or fault_id not in before.active_fault_ids or not same_metrics(result.before_metrics, before.metrics) or not same_metrics(result.after_metrics, after.metrics) { raise ValueError("Recovery evidence does not match its grid snapshots."); }
    if (text(data, "status") == "applied") != bool(result.applied_actions) { raise ValueError("Triage status and committed actions disagree."); }
    return data as TriageResult;
}
