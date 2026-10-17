"""GridWalk AI full-stack entry point."""

import agents.events;
import agents.orchestration;

cl {
    import from .client.Dashboard { Dashboard }

    def:pub app -> JsxElement {
        return <Dashboard/>;
    }
}
