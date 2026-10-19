"""Real event persistence and incident projection using fixed test proposals."""
import from agents.orchestration { _run_triage_with_planner, _finalize_triage, TriageStatus }
import from agents.events { get_agent_events, get_recovery_result }
import from scripts.recovery_ui_fixture { fixture_proposal }
import from grid.simulation { reset_simulation, get_grid_state }
import from shared.contracts { ExecutionMode, RecoveryOutcome, AgentEventKind, AgentEventOutcome }
import from time { perf_counter }
import from uuid { uuid4 }

test "line recovery persists ordered rejection revision application and audit evidence" {
    reset_simulation();
    triage = _run_triage_with_planner("FAULT-LINE-A-H", fixture_proposal);
    assert triage.status == TriageStatus.APPLIED;
    run = _finalize_triage(triage, str(uuid4()), perf_counter(), ExecutionMode.DETERMINISTIC);
    assert run.recovery_result is not None;
    assert run.recovery_result.execution_mode == ExecutionMode.DETERMINISTIC;
    events = get_agent_events(run.run_id);
    assert len(events) == 8;
    assert [item.sequence for item in events] == list(range(1, 9));
    assert all([item.run_id == run.run_id for item in events]);
    assert events[2].outcome == AgentEventOutcome.REJECTED;
    assert events[3].kind == AgentEventKind.REVISION;
    assert events[6].kind == AgentEventKind.APPLICATION;
    assert events[7].kind == AgentEventKind.AUDIT;
    stored = get_recovery_result(run.run_id);
    assert stored is not None and stored.run_id == run.run_id;
    assert stored.after_metrics.served_kw == get_grid_state().metrics.served_kw;
    assert get_agent_events()[0].run_id == run.run_id;
    reset_simulation();
    assert get_agent_events() == [];
    assert len(get_agent_events(run.run_id)) == 8;
}

test "partial source recovery reports only committed actions and actual metrics" {
    reset_simulation();
    triage = _run_triage_with_planner("FAULT-SOURCE-A", fixture_proposal);
    assert triage.status == TriageStatus.APPLIED;
    run = _finalize_triage(triage, str(uuid4()), perf_counter(), ExecutionMode.DETERMINISTIC);
    result = run.recovery_result;
    assert result is not None and result.outcome == RecoveryOutcome.PARTIAL;
    assert result.after_metrics.critical_preserved_pct == 100.0;
    assert result.after_metrics.shed_kw == 25.0;
    assert len(result.applied_actions) == 2;
    assert "fault remains active" in result.incident_summary;
    duplicate = _run_triage_with_planner("FAULT-SOURCE-A", fixture_proposal);
    no_action = _finalize_triage(duplicate, str(uuid4()), perf_counter(), ExecutionMode.DETERMINISTIC);
    assert no_action.recovery_result is not None;
    assert no_action.recovery_result.outcome == RecoveryOutcome.NO_ACTION;
    assert no_action.recovery_result.execution_mode == ExecutionMode.NONE;
    assert no_action.recovery_result.applied_actions == [];
    assert not any([item.kind == AgentEventKind.APPLICATION for item in get_agent_events(no_action.run_id)]);
}

test "exhausted shortage preserves unmet critical demand with no applied event" {
    reset_simulation();
    triage = _run_triage_with_planner("FAULT-INSUFFICIENT-BACKUP", fixture_proposal);
    assert triage.status == TriageStatus.EXHAUSTED;
    run = _finalize_triage(triage, str(uuid4()), perf_counter(), ExecutionMode.DETERMINISTIC);
    result = run.recovery_result;
    assert result is not None and result.outcome == RecoveryOutcome.INFEASIBLE;
    assert result.execution_mode == ExecutionMode.NONE and result.applied_actions == [];
    assert result.after_metrics.served_kw == result.before_metrics.served_kw;
    assert result.after_metrics.critical_preserved_pct < 100.0;
    assert not any([item.kind == AgentEventKind.APPLICATION for item in get_agent_events(run.run_id)]);
    assert get_recovery_result("UNKNOWN-RUN") is None;
    assert get_agent_events("UNKNOWN-RUN") == [];
}
