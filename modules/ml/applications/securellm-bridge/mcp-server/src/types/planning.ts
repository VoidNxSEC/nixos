/**
 * Multi-Step Planning Types
 * 
 * Types for automatic task decomposition with dependency resolution
 * and checkpoint/resume capability.
 */

import type { EnrichedContext } from './context-inference.js';
import type { BatchActionResult } from './proactive-actions.js';

/**
 * Task step status
 */
export type StepStatus = 'pending' | 'running' | 'completed' | 'failed' | 'skipped' | 'blocked';

/**
 * Task step priority
 */
export type StepPriority = 'critical' | 'high' | 'normal' | 'low';

/**
 * Individual task step
 */
export interface TaskStep {
  /** Unique step identifier */
  id: string;
  /** Step name */
  name: string;
  /** Step description */
  description: string;
  /** Step status */
  status: StepStatus;
  /** Step priority */
  priority: StepPriority;
  /** Dependencies (step IDs that must complete first) */
  dependencies: string[];
  /** Estimated duration in ms */
  estimatedDuration: number;
  /** Actual duration in ms (when completed) */
  actualDuration?: number;
  /** Step metadata */
  metadata: Record<string, any>;
  /** Error message if failed */
  error?: string;
  /** Result data */
  result?: any;
}

/**
 * Execution plan
 */
export interface ExecutionPlan {
  /** Plan ID */
  id: string;
  /** Plan name */
  name: string;
  /** All steps in plan */
  steps: TaskStep[];
  /** Total estimated duration */
  estimatedDuration: number;
  /** Current step index */
  currentStep: number;
  /** Plan status */
  status: 'pending' | 'running' | 'completed' | 'failed' | 'paused';
  /** Created timestamp */
  createdAt: number;
  /** Started timestamp */
  startedAt?: number;
  /** Completed timestamp */
  completedAt?: number;
}

/**
 * Plan execution result
 */
export interface PlanExecutionResult {
  /** Plan that was executed */
  plan: ExecutionPlan;
  /** Completed steps */
  completedSteps: TaskStep[];
  /** Failed steps */
  failedSteps: TaskStep[];
  /** Skipped steps */
  skippedSteps: TaskStep[];
  /** Total duration */
  totalDuration: number;
  /** Success rate */
  successRate: number;
}

/**
 * Planning context
 */
export interface PlanningContext {
  /** User input */
  userInput: string;
  /** Enriched context */
  enrichedContext: EnrichedContext;
  /** Proactive action results */
  actionResults: BatchActionResult;
  /** Project root */
  projectRoot: string;
}

/**
 * Checkpoint data for resume
 */
export interface PlanCheckpoint {
  /** Plan ID */
  planId: string;
  /** Completed step IDs */
  completedSteps: string[];
  /** Failed step IDs */
  failedSteps: string[];
  /** Checkpoint timestamp */
  timestamp: number;
  /** Checkpoint metadata */
  metadata: Record<string, any>;
}

/**
 * Step executor interface
 */
export interface StepExecutor {
  /** Can this executor handle this step? */
  canExecute(step: TaskStep): boolean;
  /** Execute the step */
  execute(step: TaskStep, context: PlanningContext): Promise<any>;
}