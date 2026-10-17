"""Typed AI proposals from factual Monitor observations.

The model proposes actions only. The server stamps fault and version fields
from the observed GraphState; Member 1's validator decides feasibility.
"""

import from agents.monitor { MonitorFacts, inspect_grid }
import from dotenv { load_dotenv }
import from shared.contracts { RecoveryAction, RecoveryPlan }

obj PlannerDraft {
    has actions: list[RecoveryAction];
    has explanation: str;
}
sem PlannerDraft = "Unvalidated recovery intentions, never an approved allocation or applied graph change.";
sem PlannerDraft.actions = "Ordered SHED_LOAD actions targeting load bus IDs and CLOSE_SWITCH actions targeting switch IDs from the supplied graph only. Use an empty list if no supported action is defensible.";
sem PlannerDraft.explanation = "Briefly explain the observed fault and why the proposed actions may help; state uncertainty and never claim restored service or approval.";

def draft_recovery(facts: MonitorFacts) -> PlannerDraft by llm(temperature=0.2);
sem draft_recovery = "Propose a response to this fictional microgrid incident using only observed facts. A physical line fault cannot be repaired by closing its switch. Do not deliberately shed Tier 1 loads. Prefer Tier 3 shedding before Tier 2 when shedding is needed. Source and line capacity, route feasibility, and final service are determined later by deterministic validation. Do not invent IDs, arithmetic results, or applied outcomes.";
sem draft_recovery.facts = "Monitor observations and authoritative GraphState. Read source capacities, load demand and tiers, switch states, physical line faults, and stable bus/switch IDs before proposing actions. A backup source with spare capacity may still lack a feasible route.";

walker TriagePlanner {
    has facts: MonitorFacts;
    has reports: list[RecoveryPlan] = [];

    can propose with Root entry {
        if not self.facts.incident_detected or len(self.facts.graph_state.active_fault_ids) != 1 {
            raise ValueError("Planner requires one active fault in a complete Monitor snapshot");
        }
        draft = draft_recovery(self.facts);
        report RecoveryPlan(
            fault_id=self.facts.graph_state.active_fault_ids[0],
            grid_generation_id=self.facts.graph_state.generation_id,
            grid_revision=self.facts.graph_state.revision,
            actions=draft.actions,
            explanation=draft.explanation,
            affected_source_id=(
                self.facts.derated_source_ids[0]
                if len(self.facts.derated_source_ids) == 1 else None
            )
        );
    }
}

def propose_plan(facts: MonitorFacts) -> RecoveryPlan {
    load_dotenv(dotenv_path=".env", override=False);
    result = root spawn TriagePlanner(facts=facts);
    if len(result.reports) != 1 {
        raise ValueError("Planner produced no single typed recovery plan");
    }
    return result.reports[0];
}

def propose_current_plan() -> RecoveryPlan {
    return propose_plan(inspect_grid());
}
