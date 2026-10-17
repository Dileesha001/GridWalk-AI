"""Manual live typed provider probe; never applies a recovery plan."""
import from agents.monitor { inspect_grid }
import from agents.planner { propose_plan, propose_backup_plan }
import from grid.fixture { FAULT_LINE_A_H }
import from grid.simulation { inject_fault, reset_simulation, get_grid_state }
import from grid.validation { validate_plan }
import from os { getenv }
import from sys { argv }

with entry:__main__ {
    provider = argv[1] if len(argv) > 1 else "primary";
    if provider not in ["primary", "backup"] { raise ValueError("Choose primary or backup"); }
    reset_simulation();
    observed = inject_fault(FAULT_LINE_A_H);
    try {
        facts = inspect_grid();
        plan = propose_plan(facts) if provider == "primary" else propose_backup_plan(facts);
        validation = validate_plan(plan);
        print(f"provider={provider}; typed_plan=True; validator_accepted={validation.accepted}; actions={len(plan.actions)}");
        assert get_grid_state().revision == observed.revision;
    } except Exception as error {
        detail = str(error);
        for variable in ["GOOGLE_API_KEY", "GROQ_API_KEY"] {
            key = getenv(variable, "");
            if key { detail = detail.replace(key, "[REDACTED]"); }
        }
        print(f"provider={provider}; typed_plan=False; error={type(error).__name__}; detail={detail[:1200]}");
        raise RuntimeError("Live typed provider probe failed; grid was not modified by a plan") from None;
    } finally { reset_simulation(); }
}
