"""Typed AI proposals from factual Monitor observations.

The model proposes actions only. The server stamps fault and version fields
from the observed GraphState; Member 1's validator decides feasibility.
"""

import from agents.monitor { MonitorFacts, inspect_grid }
import from dotenv { load_dotenv }
import from jaclang.byllm.lib { Model, ModelPool }
import from shared.contracts { RecoveryAction, RecoveryActionType, RecoveryPlan }

glob PRIMARY_MODEL: str = "gemini/gemini-3.8-flash";
glob BACKUP_MODEL: str = "groq/openai/gpt-oss-120b";
glob REQUEST_TIMEOUT_SECONDS: float = 15.0;
glob _env_loaded: bool = load_dotenv(dotenv_path=".env", override=False);
glob primary_llm: ModelPool = ModelPool(
    models=[Model(model_name=PRIMARY_MODEL)],
    strategy="fallback", num_retries=0, timeout=REQUEST_TIMEOUT_SECONDS
);
glob backup_llm: ModelPool = ModelPool(
    models=[Model(model_name=BACKUP_MODEL)],
    strategy="fallback", num_retries=0, timeout=REQUEST_TIMEOUT_SECONDS
);

obj PlannerDraft {
    has action_types: list[RecoveryActionType];
    has target_ids: list[str];
    has explanation: str;
}
sem PlannerDraft = "Unvalidated recovery intentions, never an approved allocation or applied graph change.";
sem PlannerDraft.action_types = "Ordered action names chosen only from the RecoveryActionType enum: SHED_LOAD or CLOSE_SWITCH. Each entry pairs with the target ID at the same position. Use an empty list if no supported action is defensible.";
sem PlannerDraft.target_ids = "Ordered stable target IDs paired one-for-one with action_types. SHED_LOAD uses load bus IDs; CLOSE_SWITCH uses switch IDs. Both lists must have the same length.";
sem PlannerDraft.explanation = "Briefly explain the observed fault and why the proposed actions may help; state uncertainty and never claim restored service or approval.";

def draft_recovery(facts: MonitorFacts, rejection_feedback: str) -> PlannerDraft by primary_llm(temperature=0.2, max_output_retries=0);
sem draft_recovery = "Propose a response to this fictional microgrid incident using only observed facts. If rejection feedback is present, revise the previous proposal to address those specific validator reasons rather than repeating it. The only supported actions are SHED_LOAD and CLOSE_SWITCH. A physically faulted line is already nonconducting; do not propose opening its switch, and closing it cannot repair the fault. Do not deliberately shed Tier 1 loads. Prefer Tier 3 shedding before Tier 2 when shedding is needed. Source and line capacity, route feasibility, and final service are determined later by deterministic validation. Do not invent IDs, arithmetic results, or applied outcomes.";
sem draft_recovery.facts = "Monitor observations and authoritative GraphState. Read source capacities, load demand and tiers, switch states, physical line faults, and stable bus/switch IDs before proposing actions. A backup source with spare capacity may still lack a feasible route.";
sem draft_recovery.rejection_feedback = "Empty on the first proposal. On revision, factual reasons from deterministic validation and the previous action list; address these reasons without claiming approval.";

def draft_backup_recovery(facts: MonitorFacts, rejection_feedback: str) -> PlannerDraft by backup_llm(temperature=0.2, max_output_retries=0);
sem draft_backup_recovery = "Independently propose typed recovery intentions for the fictional fault from the observed graph. This is a backup provider call, not a validated or applied result. Use only supported SHED_LOAD load bus IDs and CLOSE_SWITCH switch IDs. Never shed Tier 1 loads or treat a faulted line as repaired. Address any specific validator rejection feedback. Deterministic code judges all capacity and route constraints later.";
sem draft_backup_recovery.facts = "Current Monitor observations and authoritative GraphState, including physical faults, source capability, line and switch IDs, loads, and tiers.";
sem draft_backup_recovery.rejection_feedback = "Empty for the first backup proposal; otherwise factual rejection reasons and prior actions to revise.";

walker TriagePlanner {
    has facts: MonitorFacts;
    has rejection_feedback: str = "";
    has use_backup: bool = False;
    has reports: list[RecoveryPlan] = [];

    can propose with Root entry {
        if not self.facts.incident_detected or len(self.facts.graph_state.active_fault_ids) != 1 {
            raise ValueError("Planner requires one active fault in a complete Monitor snapshot");
        }
        draft = draft_backup_recovery(self.facts, self.rejection_feedback) if self.use_backup else draft_recovery(self.facts, self.rejection_feedback);
        if len(draft.action_types) != len(draft.target_ids) {
            raise ValueError("Planner returned mismatched action and target lists");
        }
        actions: list[RecoveryAction] = [];
        for index in range(len(draft.action_types)) {
            action_type = draft.action_types[index];
            if action_type == RecoveryActionType.SHED_LOAD {
                actions.append(RecoveryAction(
                    action_type=RecoveryActionType.SHED_LOAD,
                    target_id=draft.target_ids[index]
                ));
            } elif action_type == RecoveryActionType.CLOSE_SWITCH {
                actions.append(RecoveryAction(
                    action_type=RecoveryActionType.CLOSE_SWITCH,
                    target_id=draft.target_ids[index]
                ));
            } else {
                raise ValueError(f"Planner returned unsupported action type: {action_type}");
            }
        }
        report RecoveryPlan(
            fault_id=self.facts.graph_state.active_fault_ids[0],
            grid_generation_id=self.facts.graph_state.generation_id,
            grid_revision=self.facts.graph_state.revision,
            actions=actions,
            explanation=draft.explanation,
            affected_source_id=(
                self.facts.derated_source_ids[0]
                if len(self.facts.derated_source_ids) == 1 else None
            )
        );
    }
}

def propose_plan(facts: MonitorFacts, rejection_feedback: str = "") -> RecoveryPlan {
    result = root spawn TriagePlanner(facts=facts, rejection_feedback=rejection_feedback);
    if len(result.reports) != 1 {
        raise ValueError("Planner produced no single typed recovery plan");
    }
    return result.reports[0];
}

def propose_backup_plan(facts: MonitorFacts, rejection_feedback: str = "") -> RecoveryPlan {
    result = root spawn TriagePlanner(
        facts=facts, rejection_feedback=rejection_feedback, use_backup=True
    );
    if len(result.reports) != 1 {
        raise ValueError("Backup Planner produced no single typed recovery plan");
    }
    return result.reports[0];
}

def propose_current_plan() -> RecoveryPlan {
    return propose_plan(inspect_grid());
}
