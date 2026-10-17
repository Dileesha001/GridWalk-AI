"""Compact display formatting; never used to calculate simulation outcomes."""
def:pub number(value: float) -> str {
    return f"{value:.1f}".replace(".0", "");
}
