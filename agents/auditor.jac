"""Factual incident account from the validator and committed graph state."""

import from shared.contracts { GraphState, RecoveryAction, RecoveryActionType, ValidationResult }


def factual_incident_summary(
    fault_id: str, before: GraphState, after: GraphState,
    applied_actions: list[RecoveryAction]
) -> str {
    fault_evidence: list[str] = [];
    for line in before.lines {
        if line.physically_faulted {
            fault_evidence.append(f"line {line.line_id} is physically faulted");
        }
    }
    for source in before.sources {
        if source.status == "derated" {
            fault_evidence.append(
                f"source {source.bus_id} is derated to {source.capacity_kw:.1f} kW"
            );
        }
    }
    cause_text = "; ".join(fault_evidence) if len(fault_evidence) > 0 else "fault recorded in the grid";
    actions: list[str] = [];
    for action in applied_actions {
        if action.action_type == RecoveryActionType.CLOSE_SWITCH {
            actions.append(f"closed switch {action.target_id}");
        } elif action.action_type == RecoveryActionType.SHED_LOAD {
            actions.append(f"shed load {action.target_id}");
        }
    }
    action_text = ", ".join(actions) if len(actions) > 0 else "no actions";
    critical = after.metrics.critical_preserved_pct;
    critical_text = f"{critical:.1f}%" if critical is not None else "not applicable";
    return (
        f"Simulated fault {fault_id}: {cause_text}. The fault remains active. " +
        f"The validated plan {action_text}. " +
        f"Served demand changed from {before.metrics.served_kw:.1f} to " +
        f"{after.metrics.served_kw:.1f} kW. Critical demand preserved: " +
        f"{critical_text}. Residual unmet demand: {after.metrics.unmet_kw:.1f} kW."
    );
}


walker IncidentAuditor {
    has fault_id: str;
    has before: GraphState;
    has after: GraphState;
    has applied_actions: list[RecoveryAction];
    has validation: ValidationResult;
    has reports: list[str] = [];

    can inspect_commit with Root entry {
        if not self.validation.accepted or self.validation.candidate is None {
            raise ValueError("Auditor requires an accepted validation with candidate evidence");
        }
        if (
            self.validation.checked_generation_id != self.before.generation_id or
            self.validation.checked_revision != self.before.revision
        ) {
            raise ValueError("Auditor validation evidence is from another snapshot");
        }
        if (
            self.before.generation_id != self.after.generation_id or
            self.after.revision <= self.before.revision or
            self.fault_id not in self.after.active_fault_ids
        ) {
            raise ValueError("Auditor requires the committed state for this fault");
        }
        report factual_incident_summary(
            self.fault_id, self.before, self.after, self.applied_actions
        );
    }
}


def audit_incident(
    fault_id: str, before: GraphState, after: GraphState,
    applied_actions: list[RecoveryAction], validation: ValidationResult
) -> str {
    audited = root spawn IncidentAuditor(
        fault_id=fault_id, before=before, after=after,
        applied_actions=applied_actions, validation=validation
    );
    if len(audited.reports) != 1 {
        raise ValueError("Auditor did not produce one factual summary");
    }
    return audited.reports[0];
}
