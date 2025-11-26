/**
 * Proactive Action Types
 *
 * Types for actions that execute automatically before asking user questions
 * to gather relevant context and reduce friction.
 */
import type { EnrichedContext } from './context-inference.js';
/**
 * Proactive action result status
 */
export type ActionStatus = 'success' | 'error' | 'timeout' | 'skipped';
/**
 * Base proactive action result
 */
export interface ActionResult {
    /** Action identifier */
    action: string;
    /** Execution status */
    status: ActionStatus;
    /** Result data */
    data: any;
    /** Execution duration in ms */
    duration: number;
    /** Error message if failed */
    error?: string;
}
/**
 * File scanning result
 */
export interface FileScanResult extends ActionResult {
    action: 'file_scan';
    data: {
        /** Matching files */
        files: string[];
        /** Search pattern used */
        pattern: string;
        /** Total files scanned */
        totalScanned: number;
    };
}
/**
 * Directory listing result
 */
export interface DirectoryListResult extends ActionResult {
    action: 'directory_list';
    data: {
        /** Directory entries */
        entries: Array<{
            name: string;
            type: 'file' | 'dir';
            size: number;
        }>;
        /** Total entries */
        total: number;
        /** Directory path */
        path: string;
    };
}
/**
 * Git history result
 */
export interface GitHistoryResult extends ActionResult {
    action: 'git_history';
    data: {
        /** Recent commits */
        commits: Array<{
            hash: string;
            message: string;
            author: string;
            date: string;
        }>;
        /** Files in commits */
        files: string[];
        /** Date range */
        range: {
            from: string;
            to: string;
        };
    };
}
/**
 * Package search result
 */
export interface PackageSearchResult extends ActionResult {
    action: 'package_search';
    data: {
        /** Found packages */
        packages: Array<{
            name: string;
            version: string;
            description?: string;
        }>;
        /** Search query */
        query: string;
        /** Package manager */
        manager: 'npm' | 'cargo' | 'cabal' | 'nix';
    };
}
/**
 * Function search result
 */
export interface FunctionSearchResult extends ActionResult {
    action: 'function_search';
    data: {
        /** Found functions */
        functions: Array<{
            name: string;
            file: string;
            line: number;
            signature?: string;
        }>;
        /** Search pattern */
        pattern: string;
    };
}
/**
 * Build validation result
 */
export interface BuildValidationResult extends ActionResult {
    action: 'build_validation';
    data: {
        /** Is build valid */
        valid: boolean;
        /** Validation errors */
        errors: string[];
        /** Validation warnings */
        warnings: string[];
    };
}
/**
 * Union type of all action results
 */
export type ProactiveActionResult = FileScanResult | DirectoryListResult | GitHistoryResult | PackageSearchResult | FunctionSearchResult | BuildValidationResult;
/**
 * Proactive action execution context
 */
export interface ActionContext {
    /** Enriched context from Phase 1.1 */
    enrichedContext: EnrichedContext;
    /** Project root */
    projectRoot: string;
    /** Timeout in milliseconds */
    timeout: number;
}
/**
 * Proactive action executor interface
 */
export interface ProactiveAction {
    /** Action identifier */
    name: string;
    /** Should this action run for this context? */
    shouldRun(context: ActionContext): boolean;
    /** Execute the action */
    execute(context: ActionContext): Promise<ActionResult>;
}
/**
 * Batch execution result
 */
export interface BatchActionResult {
    /** All executed actions */
    actions: ProactiveActionResult[];
    /** Total execution time */
    totalDuration: number;
    /** Success count */
    successCount: number;
    /** Error count */
    errorCount: number;
    /** Timeout count */
    timeoutCount: number;
}
//# sourceMappingURL=proactive-actions.d.ts.map