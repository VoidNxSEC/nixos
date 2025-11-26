/**
 * Plan Executor
 *
 * Executes plans with checkpoint/resume capability and parallel execution.
 */
import type { ExecutionPlan, PlanExecutionResult, PlanningContext, PlanCheckpoint } from '../../types/planning.js';
/**
 * Plan Executor
 */
export declare class PlanExecutor {
    private dependencyResolver;
    constructor();
    /**
     * Execute plan with automatic ordering and parallel execution
     */
    executePlan(plan: ExecutionPlan, context: PlanningContext, checkpoint?: PlanCheckpoint): Promise<PlanExecutionResult>;
    /**
     * Execute single step
     */
    private executeStep;
    /**
     * Create checkpoint
     */
    createCheckpoint(plan: ExecutionPlan): PlanCheckpoint;
    /**
     * Restore from checkpoint
     */
    private restoreFromCheckpoint;
    /**
     * Pause plan execution
     */
    pausePlan(plan: ExecutionPlan): PlanCheckpoint;
    /**
     * Resume plan execution
     */
    resumePlan(plan: ExecutionPlan, context: PlanningContext, checkpoint: PlanCheckpoint): Promise<PlanExecutionResult>;
    /**
     * Delay helper
     */
    private delay;
}
//# sourceMappingURL=plan-executor.d.ts.map