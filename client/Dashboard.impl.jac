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
    lockRef.current = True;
    epochRef.current = (epochRef.current or 0) + 1;
    request_id = epochRef.current;
    busy = True; error = "";
    phase = "Loading live grid…" if operation == "read" else "Injecting the selected fault…" if operation == "inject" else "Resetting the simulation…";
    try {
        if operation == "inject" { await inject_live_fault(scenario); }
        elif operation == "reset" { await reset_live_grid(); }
        confirmed = await read_live_grid();
        if not mountedRef.current or epochRef.current != request_id { return; }
        liveGrid = confirmed;
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
        }
    }
}
