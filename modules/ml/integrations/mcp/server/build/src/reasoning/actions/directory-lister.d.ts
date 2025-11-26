/**
 * Directory Lister Proactive Action
 *
 * Lists directory contents when user asks about directories.
 */
import type { ProactiveAction, ActionContext, DirectoryListResult } from '../../types/proactive-actions.js';
/**
 * Directory Lister Action
 */
export declare class DirectoryListerAction implements ProactiveAction {
    readonly name = "directory_list";
    /**
     * Check if should run
     */
    shouldRun(context: ActionContext): boolean;
    /**
     * Execute directory listing
     */
    execute(context: ActionContext): Promise<DirectoryListResult>;
}
//# sourceMappingURL=directory-lister.d.ts.map