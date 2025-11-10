/**
 * Plan Executor
 *
 * Executes plans with checkpoint/resume capability and parallel execution.
 */
import { DependencyResolver } from './dependency-resolver.js';
/**
 * Plan Executor
 */
export class PlanExecutor {
    dependencyResolver;
    constructor() {
        this.dependencyResolver = new DependencyResolver();
    }
    /**
     * Execute plan with automatic ordering and parallel execution
     */
    async executePlan(plan, context, checkpoint) {
        const startTime = Date.now();
        plan.status = 'running';
        plan.startedAt = startTime;
        const completedSteps = [];
        const failedSteps = [];
        const skippedSteps = [];
        try {
            // Restore from checkpoint if provided
            if (checkpoint) {
                this.restoreFromCheckpoint(plan, checkpoint);
            }
            // Check for circular dependencies
            if (this.dependencyResolver.hasCircularDependencies(plan.steps)) {
                throw new Error('Circular dependencies detected in plan');
            }
            // Get parallel execution groups
            const groups = this.dependencyResolver.findParallelGroups(plan.steps.filter(s => s.status === 'pending'));
            // Execute groups sequentially, steps within groups in parallel
            for (const group of groups) {
                const results = await Promise.allSettled(group.map(step => this.executeStep(step, context)));
                // Process results
                results.forEach((result, index) => {
                    const step = group[index];
                    if (result.status === 'fulfilled') {
                        step.status = 'completed';
                        step.result = result.value;
                        completedSteps.push(step);
                    }
                    else {
                        step.status = 'failed';
                        step.error = result.reason.message;
                        failedSteps.push(step);
                    }
                });
                // Stop if critical step failed
                const criticalFailed = failedSteps.some(s => s.priority === 'critical');
                if (criticalFailed) {
                    // Mark remaining as skipped
                    const remaining = plan.steps.filter(s => s.status === 'pending');
                    remaining.forEach(s => {
                        s.status = 'skipped';
                        skippedSteps.push(s);
                    });
                    break;
                }
            }
            plan.status = failedSteps.length > 0 ? 'failed' : 'completed';
        }
        catch (error) {
            plan.status = 'failed';
        }
        plan.completedAt = Date.now();
        return {
            plan,
            completedSteps,
            failedSteps,
            skippedSteps,
            totalDuration: Date.now() - startTime,
            successRate: completedSteps.length / plan.steps.length,
        };
    }
    /**
     * Execute single step
     */
    async executeStep(step, context) {
        const startTime = Date.now();
        step.status = 'running';
        try {
            // Simulate step execution (in real implementation, call step executors)
            await this.delay(step.estimatedDuration);
            step.actualDuration = Date.now() - startTime;
            return { success: true, step: step.id };
        }
        catch (error) {
            step.actualDuration = Date.now() - startTime;
            throw error;
        }
    }
    /**
     * Create checkpoint
     */
    createCheckpoint(plan) {
        return {
            planId: plan.id,
            completedSteps: plan.steps.filter(s => s.status === 'completed').map(s => s.id),
            failedSteps: plan.steps.filter(s => s.status === 'failed').map(s => s.id),
            timestamp: Date.now(),
            metadata: {},
        };
    }
    /**
     * Restore from checkpoint
     */
    restoreFromCheckpoint(plan, checkpoint) {
        for (const step of plan.steps) {
            if (checkpoint.completedSteps.includes(step.id)) {
                step.status = 'completed';
            }
            else if (checkpoint.failedSteps.includes(step.id)) {
                step.status = 'failed';
            }
        }
    }
    /**
     * Pause plan execution
     */
    pausePlan(plan) {
        plan.status = 'paused';
        return this.createCheckpoint(plan);
    }
    /**
     * Resume plan execution
     */
    async resumePlan(plan, context, checkpoint) {
        return this.executePlan(plan, context, checkpoint);
    }
    /**
     * Delay helper
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}
//# sourceMappingURL=plan-executor.js.map