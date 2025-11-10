/**
 * File Scanner Proactive Action
 *
 * Scans for files matching entities extracted from input.
 */
import type { ProactiveAction, ActionContext, FileScanResult } from '../../types/proactive-actions.js';
/**
 * File Scanner Action
 */
export declare class FileScannerAction implements ProactiveAction {
    readonly name = "file_scan";
    /**
     * Check if should run
     */
    shouldRun(context: ActionContext): boolean;
    /**
     * Execute file scan
     */
    execute(context: ActionContext): Promise<FileScanResult>;
}
//# sourceMappingURL=file-scanner.d.ts.map