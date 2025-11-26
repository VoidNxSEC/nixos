/**
 * Multi-Step Planner
 *
 * Main coordinator for automatic task decomposition and execution.
 */
import type { PlanningContext, ExecutionPlan, PlanExecutionResult, PlanCheckpoint } from '../types/planning.js';
/**
 * Multi-Step Planner
 */
export declare class MultiStepPlanner {
    private planGenerator;
    private planExecutor;
    private dependencyResolver;
    constructor();
    /**
     * Plan and execute task
     */
    planAndExecute(context: PlanningContext): Promise<PlanExecutionResult>;
    /**
     * Generate plan only (without execution)
     */
    generatePlan(context: PlanningContext): ExecutionPlan;
    /**
     * Execute existing plan
     */
    executePlan(plan: ExecutionPlan, context: PlanningContext): Promise<PlanExecutionResult>;
    /**
     * Pause plan
     */
    pausePlan(plan: ExecutionPlan): PlanCheckpoint;
    /**
     * Resume plan
     */
    resumePlan(plan: ExecutionPlan, context: PlanningContext, checkpoint: PlanCheckpoint): Promise<PlanExecutionResult>;
}
//# sourceMappingURL=multi-step-planner.d.ts.map