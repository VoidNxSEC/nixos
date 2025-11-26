/**
 * Multi-Step Planner
 *
 * Main coordinator for automatic task decomposition and execution.
 */
import { PlanGenerator } from './planning/plan-generator.js';
import { PlanExecutor } from './planning/plan-executor.js';
import { DependencyResolver } from './planning/dependency-resolver.js';
/**
 * Multi-Step Planner
 */
export class MultiStepPlanner {
    planGenerator;
    planExecutor;
    dependencyResolver;
    constructor() {
        this.planGenerator = new PlanGenerator();
        this.planExecutor = new PlanExecutor();
        this.dependencyResolver = new DependencyResolver();
    }
    /**
     * Plan and execute task
     */
    async planAndExecute(context) {
        // Generate execution plan
        const plan = this.planGenerator.generatePlan(context);
        // Execute plan
        const result = await this.planExecutor.executePlan(plan, context);
        return result;
    }
    /**
     * Generate plan only (without execution)
     */
    generatePlan(context) {
        return this.planGenerator.generatePlan(context);
    }
    /**
     * Execute existing plan
     */
    async executePlan(plan, context) {
        return this.planExecutor.executePlan(plan, context);
    }
    /**
     * Pause plan
     */
    pausePlan(plan) {
        return this.planExecutor.pausePlan(plan);
    }
    /**
     * Resume plan
     */
    async resumePlan(plan, context, checkpoint) {
        return this.planExecutor.resumePlan(plan, context, checkpoint);
    }
}
//# sourceMappingURL=multi-step-planner.js.map