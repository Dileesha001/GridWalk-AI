"""Local verification entry with fixed proposals; never a live AI demo or deployment."""
import from grid.simulation { get_grid_state, inject_fault, reset_simulation }
import from agents.events { get_agent_events, get_recovery_result }
import from scripts.recovery_ui_fixture { run_triage }

cl {
    import from .client.Dashboard { Dashboard }
    def:pub app -> JsxElement { return <Dashboard/>; }
}
