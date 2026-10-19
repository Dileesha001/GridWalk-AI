impl Dashboard.inspect(identity: str) -> None {
    selected = identity;
    browser: any = window;
    browser.document.getElementById("component-inspection").open = True;
    browser.document.getElementById("topology-component").focus();
}

impl Dashboard.choose_scenario(identity: str) -> None {
    if busy or previewMode or (liveGrid and len(liveGrid.active_fault_ids) > 0) { return; }
    scenario = identity;
}

impl Dashboard.switch_mode(preview: bool) -> None {
    if lockRef.current { return; }
    previewMode = preview;
    if not preview { operate("read"); }
}

impl Dashboard.operate(operation: str) -> None {
    if lockRef.current or (operation != "read" and (previewMode or uncertain or liveGrid is None)) { return; }
    if operation == "inject" and liveGrid and len(liveGrid.active_fault_ids) > 0 { return; }
    if operation == "recover" and (not liveGrid or not liveGrid.active_fault_ids or (recovery and str(recovery.outcome) not in ["failed", "infeasible"])) { return; }
    lockRef.current = True;
    epochRef.current = (epochRef.current or 0) + 1;
    request_id = epochRef.current;
    busy = True; error = "";
    recovering = operation == "recover";
    phase = "Loading live grid…" if operation == "read" else "Injecting the selected fault…" if operation == "inject" else "Recovery requested · awaiting server result…" if recovering else "Resetting the simulation…";
    if recovering { recovery = None; agentEvents = []; }
    try {
        completed: RecoveryResult | None = None;
        events: list[AgentEvent] = [];
        expected_generation = liveGrid.generation_id if liveGrid else "";
        expected_revision = -1;
        if operation == "inject" { await inject_live_fault(scenario); }
        elif operation == "reset" { await reset_live_grid(); }
        elif operation == "recover" and liveGrid {
            triage = await run_live_recovery(
                liveGrid.active_fault_ids[0], liveGrid.generation_id,
                liveGrid.revision
            );
            if triage.before_state.generation_id != expected_generation or triage.after_state.generation_id != expected_generation { raise ValueError("The grid was reset during this recovery. Refresh the current state."); }
            completed = triage.recovery_result;
            expected_revision = triage.after_state.revision;
            expected_generation = triage.after_state.generation_id;
        }
        confirmed = await read_live_grid();
        if operation == "read" {
            expected_generation = confirmed.generation_id;
            events = await read_agent_events();
            if events { completed = await read_recovery_result(events[0].run_id); }
        } elif completed { events = await read_agent_events(completed.run_id); }
        if completed {
            check_run_evidence(completed, events);
            if confirmed.generation_id != expected_generation or (expected_revision >= 0 and confirmed.revision != expected_revision) or completed.fault_id not in confirmed.active_fault_ids or not same_metrics(completed.after_metrics, confirmed.metrics) { raise ValueError("Recovery evidence is from a different grid state. Refresh to confirm the current state."); }
            # Reconfirm after event/result reads so a reset cannot restore old evidence.
            latest = await read_live_grid();
            if latest.generation_id != confirmed.generation_id or latest.revision != confirmed.revision { raise ValueError("The grid changed while recovery evidence was loading. Refresh the current state."); }
            confirmed = latest;
        }
        if not mountedRef.current or epochRef.current != request_id { return; }
        liveGrid = confirmed;
        recovery = completed;
        agentEvents = events;
        uncertain = False;
        phase = "Live state confirmed · revision " + str(confirmed.revision);
    } except Exception as failure {
        if not mountedRef.current or epochRef.current != request_id { return; }
        uncertain = True;
        error = "Could not complete the request. " + str(failure);
        phase = "Live state unconfirmed · refresh to reconnect";
    } finally {
        if mountedRef.current and epochRef.current == request_id {
            lockRef.current = False;
            busy = False;
            recovering = False;
        }
    }
}
