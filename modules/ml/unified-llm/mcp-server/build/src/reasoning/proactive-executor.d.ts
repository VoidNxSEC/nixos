/**
 * Proactive Action Executor
 *
 * Coordinates parallel execution of proactive actions with timeout enforcement.
 */
import type { ProactiveAction, BatchActionResult } from '../types/proactive-actions.js';
import type { EnrichedContext } from '../types/context-inference.js';
/**
 * Proactive Action Executor
 */
export declare class ProactiveExecutor {
    private actions;
    private readonly DEFAULT_TIMEOUT;
    constructor();
    /**
     * Execute all applicable proactive actions
     */
    executeActions(enrichedContext: EnrichedContext, projectRoot: string, timeout?: number): Promise<BatchActionResult>;
    /**
     * Execute action with timeout enforcement
     */
    private executeWithTimeout;
    /**
     * Register custom action
     */
    registerAction(action: ProactiveAction): void;
    /**
     * Get registered actions
     */
    getActions(): ProactiveAction[];
}
//# sourceMappingURL=proactive-executor.d.ts.map