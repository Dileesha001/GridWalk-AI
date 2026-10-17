"""GridWalk AI full-stack entry point."""

cl {
    import from .client.Dashboard { Dashboard }

    def:pub app -> JsxElement {
        return <Dashboard/>;
    }
}
