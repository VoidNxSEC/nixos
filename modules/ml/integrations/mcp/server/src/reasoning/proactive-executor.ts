/**
 * Proactive Action Executor
 * 
 * Coordinates parallel execution of proactive actions with timeout enforcement.
 */

import type {
  ProactiveAction,
  ActionContext,
  ProactiveActionResult,
  BatchActionResult,
} from '../types/proactive-actions.js';
import type { EnrichedContext } from '../types/context-inference.js';
import { FileScannerAction } from './actions/file-scanner.js';
import { DirectoryListerAction } from './actions/directory-lister.js';
import { GitHistoryAction } from './actions/git-history.js';

/**
 * Proactive Action Executor
 */
export class ProactiveExecutor {
  private actions: ProactiveAction[];
  private readonly DEFAULT_TIMEOUT = 2000; // 2 seconds

  constructor() {
    // Register all proactive actions
    this.actions = [
      new FileScannerAction(),
      new DirectoryListerAction(),
      new GitHistoryAction(),
    ];
  }

  /**
   * Execute all applicable proactive actions
   */
  public async executeActions(
    enrichedContext: EnrichedContext,
    projectRoot: string,
    timeout: number = this.DEFAULT_TIMEOUT
  ): Promise<BatchActionResult> {
    const startTime = Date.now();
    
    const actionContext: ActionContext = {
      enrichedContext,
      projectRoot,
      timeout,
    };

    // Filter actions that should run
    const applicableActions = this.actions.filter(action => action.shouldRun(actionContext));

    // Execute actions in parallel with timeout
    const results = await Promise.all(
      applicableActions.map(action => this.executeWithTimeout(action, actionContext))
    );

    // Calculate statistics
    const successCount = results.filter(r => r.status === 'success').length;
    const errorCount = results.filter(r => r.status === 'error').length;
    const timeoutCount = results.filter(r => r.status === 'timeout').length;

    return {
      actions: results as ProactiveActionResult[],
      totalDuration: Date.now() - startTime,
      successCount,
      errorCount,
      timeoutCount,
    };
  }

  /**
   * Execute action with timeout enforcement
   */
  private async executeWithTimeout(
    action: ProactiveAction,
    context: ActionContext
  ): Promise<ProactiveActionResult> {
    const timeoutPromise = new Promise<ProactiveActionResult>((resolve) => {
      setTimeout(() => {
        resolve({
          action: action.name,
          status: 'timeout',
          data: {},
          duration: context.timeout,
          error: 'Action timeout exceeded',
        } as any);
      }, context.timeout);
    });

    try {
      const result = await Promise.race([
        action.execute(context),
        timeoutPromise,
      ]);

      return result as ProactiveActionResult;
    } catch (error: any) {
      return {
        action: action.name,
        status: 'error',
        data: {},
        duration: context.timeout,
        error: error.message,
      } as any;
    }
  }

  /**
   * Register custom action
   */
  public registerAction(action: ProactiveAction): void {
    this.actions.push(action);
  }

  /**
   * Get registered actions
   */
  public getActions(): ProactiveAction[] {
    return [...this.actions];
  }
}