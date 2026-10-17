"""Deterministic recovery proposal for the fixed twelve-bus simulation fixture.

The proposal is never authoritative. Callers must validate it again against the
current graph and apply it only through apply_approved_plan.
"""

import from grid.graph { Grid }
import from grid.fixture { fixture_lines, fixture_loads, fault_scenario }
import from grid.validation { validate_plan }
import from shared.contracts { GraphState, RecoveryAction, RecoveryActionType, RecoveryPlan }


def _switch_choices(grid: Grid) -> list[list[str]] {
    choices: list[list[str]] = [[]];
    available = sorted([
        line.switch_id for line in fixture_lines(grid)
        if not line.switch_closed and not line.physically_faulted
    ]);
    for switch_id in available {
        additions: list[list[str]] = [];
        for choice in choices {
            additions.append(choice + [switch_id]);
        }
        choices.extend(additions);
    }
    return choices;
}


def _shed_choices(grid: Grid) -> list[list[str]] {
    choices: list[list[str]] = [[]];
    available = sorted([
        load.bus_id for load in fixture_loads(grid)
        if load.tier > 1 and not load.deliberately_shed
    ]);
    for load_id in available {
        additions: list[list[str]] = [];
        for choice in choices {
            additions.append(choice + [load_id]);
        }
        choices.extend(additions);
    }
    return choices;
}


def _plan(grid: Grid, switches: list[str], sheds: list[str]) -> RecoveryPlan {
    actions: list[RecoveryAction] = [];
    for switch_id in switches {
        actions.append(RecoveryAction(
            action_type=RecoveryActionType.CLOSE_SWITCH, target_id=switch_id
        ));
    }
    for load_id in sheds {
        actions.append(RecoveryAction(
            action_type=RecoveryActionType.SHED_LOAD, target_id=load_id
        ));
    }
    affected_source_id: str | None = None;
    scenario = fault_scenario(grid.active_fault_id);
    if scenario is not None and len(scenario.source_capacities_kw) > 0 {
        affected_source_id = sorted(scenario.source_capacities_kw)[0];
    }
    return RecoveryPlan(
        fault_id=grid.active_fault_id, grid_generation_id=grid.generation_id,
        grid_revision=grid.revision, actions=actions,
        explanation="Deterministic fixture proposal; requires current-state validation before application.",
        affected_source_id=affected_source_id
    );
}


"""Propose for the observed snapshot, or None if stale or infeasible."""
def generate_fallback_plan(observed: GraphState) -> RecoveryPlan | None {
    grids = [root -->[?:Grid]];
    if len(grids) != 1 { return None; }
    grid = grids[0];
    if grid.active_fault_id == "" or grid.allocation_committed { return None; }
    if (
        grid.grid_id != observed.grid_id or
        grid.generation_id != observed.generation_id or
        grid.revision != observed.revision or
        observed.active_fault_ids != [grid.active_fault_id]
    ) { return None; }
    generation_id = grid.generation_id;
    revision = grid.revision;
    fault_id = grid.active_fault_id;

    best: RecoveryPlan | None = None;
    best_served_kw = -1.0;
    best_shed_kw = 0.0;
    best_action_count = 0;
    shed_choices = _shed_choices(grid);
    # Three normally open ties and five noncritical loads yield at most 256
    # proposals for the committed fixture. IDs and subset order are stable.
    for switches in _switch_choices(grid) {
        for sheds in shed_choices {
            if len(switches) + len(sheds) == 0 { continue; }
            candidate = _plan(grid, switches, sheds);
            checked = validate_plan(candidate);
            if not checked.accepted or checked.candidate_metrics is None { continue; }
            metrics = checked.candidate_metrics;
            count = len(candidate.actions);
            if (
                best is None or
                metrics.served_kw > best_served_kw + 0.000001 or
                (abs(metrics.served_kw - best_served_kw) <= 0.000001 and
                 (metrics.shed_kw < best_shed_kw - 0.000001 or
                  (abs(metrics.shed_kw - best_shed_kw) <= 0.000001 and count < best_action_count)))
            ) {
                best = candidate;
                best_served_kw = metrics.served_kw;
                best_shed_kw = metrics.shed_kw;
                best_action_count = count;
            }
        }
    }
    if grid.generation_id != generation_id or grid.revision != revision or grid.active_fault_id != fault_id {
        return None;
    }
    return best;
}
