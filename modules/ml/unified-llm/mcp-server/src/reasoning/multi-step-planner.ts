/**
 * Multi-Step Planner
 * 
 * Main coordinator for automatic task decomposition and execution.
 */

import type {
  PlanningContext,
  ExecutionPlan,
  PlanExecutionResult,
  PlanCheckpoint,
} from '../types/planning.js';
import { PlanGenerator } from './planning/plan-generator.js';
import { PlanExecutor } from './planning/plan-executor.js';
import { DependencyResolver } from './planning/dependency-resolver.js';

/**
 * Multi-Step Planner
 */
export class MultiStepPlanner {
  private planGenerator: PlanGenerator;
  private planExecutor: PlanExecutor;
  private dependencyResolver: DependencyResolver;

  constructor() {
    this.planGenerator = new PlanGenerator();
    this.planExecutor = new PlanExecutor();
    this.dependencyResolver = new DependencyResolver();
  }

  /**
   * Plan and execute task
   */
  public async planAndExecute(context: PlanningContext): Promise<PlanExecutionResult> {
    // Generate execution plan
    const plan = this.planGenerator.generatePlan(context);

    // Execute plan
    const result = await this.planExecutor.executePlan(plan, context);

    return result;
  }

  /**
   * Generate plan only (without execution)
   */
  public generatePlan(context: PlanningContext): ExecutionPlan {
    return this.planGenerator.generatePlan(context);
  }

  /**
   * Execute existing plan
   */
  public async executePlan(
    plan: ExecutionPlan,
    context: PlanningContext
  ): Promise<PlanExecutionResult> {
    return this.planExecutor.executePlan(plan, context);
  }

  /**
   * Pause plan
   */
  public pausePlan(plan: ExecutionPlan): PlanCheckpoint {
    return this.planExecutor.pausePlan(plan);
  }

  /**
   * Resume plan
   */
  public async resumePlan(
    plan: ExecutionPlan,
    context: PlanningContext,
    checkpoint: PlanCheckpoint
  ): Promise<PlanExecutionResult> {
    return this.planExecutor.resumePlan(plan, context, checkpoint);
  }
}