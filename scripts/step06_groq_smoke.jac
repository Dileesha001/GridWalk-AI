"""Manual Groq backup smoke against the real line-fault fixture."""

import from agents.monitor { inspect_grid }
import from agents.planner { propose_backup_plan }
import from grid.fixture { FAULT_LINE_A_H }
import from grid.simulation { get_grid_state, inject_fault, reset_simulation }
import from grid.validation { validate_plan }

with entry:__main__ {
    reset_simulation();
    observed = inject_fault(FAULT_LINE_A_H);
    facts = inspect_grid();
    plan = propose_backup_plan(facts);
    validation = validate_plan(plan);
    after = get_grid_state();

    print(f"fault={plan.fault_id}; provider=groq; model=openai/gpt-oss-120b");
    print(f"actions={[(action.action_type, action.target_id) for action in plan.actions]}");
    print(f"validator_accepted={validation.accepted}; reasons={validation.reasons}");
    print(f"revision={observed.revision}->{after.revision}");
}
