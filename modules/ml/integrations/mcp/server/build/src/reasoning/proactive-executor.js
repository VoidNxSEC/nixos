/**
 * Proactive Action Executor
 *
 * Coordinates parallel execution of proactive actions with timeout enforcement.
 */
import { FileScannerAction } from './actions/file-scanner.js';
import { DirectoryListerAction } from './actions/directory-lister.js';
import { GitHistoryAction } from './actions/git-history.js';
/**
 * Proactive Action Executor
 */
export class ProactiveExecutor {
    actions;
    DEFAULT_TIMEOUT = 2000; // 2 seconds
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
    async executeActions(enrichedContext, projectRoot, timeout = this.DEFAULT_TIMEOUT) {
        const startTime = Date.now();
        const actionContext = {
            enrichedContext,
            projectRoot,
            timeout,
        };
        // Filter actions that should run
        const applicableActions = this.actions.filter(action => action.shouldRun(actionContext));
        // Execute actions in parallel with timeout
        const results = await Promise.all(applicableActions.map(action => this.executeWithTimeout(action, actionContext)));
        // Calculate statistics
        const successCount = results.filter(r => r.status === 'success').length;
        const errorCount = results.filter(r => r.status === 'error').length;
        const timeoutCount = results.filter(r => r.status === 'timeout').length;
        return {
            actions: results,
            totalDuration: Date.now() - startTime,
            successCount,
            errorCount,
            timeoutCount,
        };
    }
    /**
     * Execute action with timeout enforcement
     */
    async executeWithTimeout(action, context) {
        const timeoutPromise = new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    action: action.name,
                    status: 'timeout',
                    data: {},
                    duration: context.timeout,
                    error: 'Action timeout exceeded',
                });
            }, context.timeout);
        });
        try {
            const result = await Promise.race([
                action.execute(context),
                timeoutPromise,
            ]);
            return result;
        }
        catch (error) {
            return {
                action: action.name,
                status: 'error',
                data: {},
                duration: context.timeout,
                error: error.message,
            };
        }
    }
    /**
     * Register custom action
     */
    registerAction(action) {
        this.actions.push(action);
    }
    /**
     * Get registered actions
     */
    getActions() {
        return [...this.actions];
    }
}
//# sourceMappingURL=proactive-executor.js.map