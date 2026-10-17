"""Shared typed projections for graph state and recovery handoffs.

Member 1 owns the graph projection and deterministic validator/application.
Member 2 owns recovery actions, plans, events, and run results. These objects
carry data across modules; persistent graph entities live in grid/graph.jac.
"""

obj SourceView {
    has bus_id: str;
    has label: str;
    has capacity_kw: float;
    has dispatched_kw: float;
    has is_backup: bool;
    has status: str;
}

obj LoadView {
    has bus_id: str;
    has label: str;
    has demand_kw: float;
    has tier: int;
    has served_kw: float;
    has deliberately_shed: bool;
    has status: str;
}

obj LineView {
    has line_id: str;
    has from_bus_id: str;
    has to_bus_id: str;
    has switch_id: str;
    has capacity_kw: float;
    has switch_closed: bool;
    has physically_faulted: bool;
    has conducting: bool;
    has transfer_kw: float;
}

obj GridMetrics {
    has total_demand_kw: float;
    has served_kw: float;
    has unmet_kw: float;
    has shed_kw: float;
    has available_capacity_kw: float;
    has dispatched_kw: float;
    has critical_preserved_pct: float | None;
    has active_fault_count: int;
}

obj GraphState {
    has grid_id: str;
    has generation_id: str;
    has revision: int;
    has active_fault_ids: list[str];
    has sources: list[SourceView];
    has loads: list[LoadView];
    has lines: list[LineView];
    has metrics: GridMetrics;
}


enum RecoveryActionType: str {
    SHED_LOAD = "SHED_LOAD",
    CLOSE_SWITCH = "CLOSE_SWITCH"
}
sem RecoveryActionType.SHED_LOAD = "Deliberately disconnect one non-critical whole load, identified by load bus ID.";
sem RecoveryActionType.CLOSE_SWITCH = "Close a healthy physical line's switch, identified by switch ID; this does not repair a fault.";

obj RecoveryAction {
    has action_type: RecoveryActionType;
    has target_id: str;
}
sem RecoveryAction = "One proposed switching or load-shedding action; deterministic code decides whether it is valid.";
sem RecoveryAction.action_type = "Choose only a supported recovery action.";
sem RecoveryAction.target_id = "Use a stable LOAD-* bus ID for SHED_LOAD or SW-* switch ID for CLOSE_SWITCH, never a display label.";

obj RecoveryPlan {
    has fault_id: str;
    has grid_generation_id: str;
    has grid_revision: int;
    has actions: list[RecoveryAction];
    has explanation: str;
    has affected_source_id: str | None = None;
}
sem RecoveryPlan = "A proposed response to the current simulated grid fault, not an approved or applied change.";
sem RecoveryPlan.fault_id = "The active fault scenario ID from the supplied graph state.";
sem RecoveryPlan.grid_generation_id = "Copy the opaque generation ID from the supplied graph state; a reset creates a new generation.";
sem RecoveryPlan.grid_revision = "The graph revision observed when this plan was proposed; stale revisions are rejected.";
sem RecoveryPlan.actions = "Ordered intended actions only. No action changes the graph until deterministic validation and application succeed.";
sem RecoveryPlan.explanation = "A concise rationale grounded in the supplied fault and graph facts, without claiming an unverified result.";
sem RecoveryPlan.affected_source_id = "Stable source bus ID when the fault affects a source, otherwise null.";

obj CandidateAllocationView {
    has source_dispatch_kw: dict[str, float];
    has served_load_kw: dict[str, float];
    has line_transfer_kw: dict[str, float];
    has unserved_load_ids: list[str];
    has deliberately_shed_ids: list[str];
}

obj ValidationResult {
    has accepted: bool;
    has checked_generation_id: str;
    has checked_revision: int;
    has reasons: list[str];
    has candidate: CandidateAllocationView | None = None;
    has candidate_metrics: GridMetrics | None = None;
}

enum ExecutionMode: str {
    NONE = "none",
    PRIMARY_AI = "primary_ai",
    BACKUP_AI = "backup_ai",
    DETERMINISTIC = "deterministic"
}

enum RecoveryOutcome: str {
    NO_ACTION = "no_action",
    RECOVERED = "recovered",
    PARTIAL = "partial",
    INFEASIBLE = "infeasible",
    FAILED = "failed"
}

enum AgentActor: str {
    MONITOR = "monitor",
    PLANNER = "planner",
    VALIDATOR = "validator",
    SIMULATION = "simulation",
    AUDITOR = "auditor",
    SYSTEM = "system"
}

enum AgentEventKind: str {
    OBSERVATION = "observation",
    PROPOSAL = "proposal",
    VALIDATION = "validation",
    REVISION = "revision",
    APPLICATION = "application",
    FALLBACK = "fallback",
    AUDIT = "audit",
    FAILURE = "failure"
}

enum AgentEventOutcome: str {
    INFO = "info",
    ACCEPTED = "accepted",
    REJECTED = "rejected",
    APPLIED = "applied",
    ERROR = "error"
}

obj AgentEvent {
    has run_id: str;
    has sequence: int;
    has actor: AgentActor;
    has kind: AgentEventKind;
    has outcome: AgentEventOutcome;
    has summary: str;
    has evidence: str = "";
}

obj RecoveryResult {
    has run_id: str;
    has fault_id: str;
    has outcome: RecoveryOutcome;
    has execution_mode: ExecutionMode;
    has applied_actions: list[RecoveryAction];
    has before_metrics: GridMetrics;
    has after_metrics: GridMetrics;
    has incident_summary: str;
    has proposal_count: int;
    has revision_count: int;
    has elapsed_ms: int;
    has failure_reason: str | None = None;
}
