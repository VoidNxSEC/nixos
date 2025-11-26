/**
 * Plan Executor
 * 
 * Executes plans with checkpoint/resume capability and parallel execution.
 */

import type {
  ExecutionPlan,
  TaskStep,
  PlanExecutionResult,
  PlanningContext,
  PlanCheckpoint,
} from '../../types/planning.js';
import { DependencyResolver } from './dependency-resolver.js';

/**
 * Plan Executor
 */
export class PlanExecutor {
  private dependencyResolver: DependencyResolver;

  constructor() {
    this.dependencyResolver = new DependencyResolver();
  }

  /**
   * Execute plan with automatic ordering and parallel execution
   */
  public async executePlan(
    plan: ExecutionPlan,
    context: PlanningContext,
    checkpoint?: PlanCheckpoint
  ): Promise<PlanExecutionResult> {
    const startTime = Date.now();
    plan.status = 'running';
    plan.startedAt = startTime;

    const completedSteps: TaskStep[] = [];
    const failedSteps: TaskStep[] = [];
    const skippedSteps: TaskStep[] = [];

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
      const groups = this.dependencyResolver.findParallelGroups(
        plan.steps.filter(s => s.status === 'pending')
      );

      // Execute groups sequentially, steps within groups in parallel
      for (const group of groups) {
        const results = await Promise.allSettled(
          group.map(step => this.executeStep(step, context))
        );

        // Process results
        results.forEach((result, index) => {
          const step = group[index];
          
          if (result.status === 'fulfilled') {
            step.status = 'completed';
            step.result = result.value;
            completedSteps.push(step);
          } else {
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
    } catch (error: any) {
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
  private async executeStep(step: TaskStep, context: PlanningContext): Promise<any> {
    const startTime = Date.now();
    step.status = 'running';

    try {
      // Simulate step execution (in real implementation, call step executors)
      await this.delay(step.estimatedDuration);
      
      step.actualDuration = Date.now() - startTime;
      return { success: true, step: step.id };
    } catch (error: any) {
      step.actualDuration = Date.now() - startTime;
      throw error;
    }
  }

  /**
   * Create checkpoint
   */
  public createCheckpoint(plan: ExecutionPlan): PlanCheckpoint {
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
  private restoreFromCheckpoint(plan: ExecutionPlan, checkpoint: PlanCheckpoint): void {
    for (const step of plan.steps) {
      if (checkpoint.completedSteps.includes(step.id)) {
        step.status = 'completed';
      } else if (checkpoint.failedSteps.includes(step.id)) {
        step.status = 'failed';
      }
    }
  }

  /**
   * Pause plan execution
   */
  public pausePlan(plan: ExecutionPlan): PlanCheckpoint {
    plan.status = 'paused';
    return this.createCheckpoint(plan);
  }

  /**
   * Resume plan execution
   */
  public async resumePlan(
    plan: ExecutionPlan,
    context: PlanningContext,
    checkpoint: PlanCheckpoint
  ): Promise<PlanExecutionResult> {
    return this.executePlan(plan, context, checkpoint);
  }

  /**
   * Delay helper
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}