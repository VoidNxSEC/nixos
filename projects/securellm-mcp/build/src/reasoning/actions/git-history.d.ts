/**
 * Git History Proactive Action
 *
 * Retrieves recent git history when relevant to user's query.
 */
import type { ProactiveAction, ActionContext, GitHistoryResult } from '../../types/proactive-actions.js';
/**
 * Git History Action
 */
export declare class GitHistoryAction implements ProactiveAction {
    readonly name = "git_history";
    /**
     * Check if should run
     */
    shouldRun(context: ActionContext): boolean;
    /**
     * Execute git history retrieval
     */
    execute(context: ActionContext): Promise<GitHistoryResult>;
}
//# sourceMappingURL=git-history.d.ts.map