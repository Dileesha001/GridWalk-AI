"""Reusable dashboard panel and honest empty states for the layout milestone."""

def:pub ShellPanel(eyebrow: str, title: str, badge: str, children: any = None) -> JsxElement {
    return <section className="panel" aria-label={title}>
        <div className="panel-heading"><div><p className="eyebrow">{eyebrow}</p><h2>{title}</h2></div><span className="tag">{badge}</span></div>
        {children}
    </section>;
}

def:pub EmptyState(title: str, description: str) -> JsxElement {
    return <div className="empty-state"><div className="empty-symbol" aria-hidden="true"><span></span><span></span><span></span><span></span></div><h3>{title}</h3><p>{description}</p></div>;
}
