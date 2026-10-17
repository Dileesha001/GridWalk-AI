"""GridWalk AI full-stack entry point."""

# Explicit registration for the raw-fetch client transport boundary.
import from grid.simulation { get_grid_state, inject_fault, reset_simulation }

cl {
    import from .client.Dashboard { Dashboard }

    def:pub app -> JsxElement {
        return <Dashboard/>;
    }
}
