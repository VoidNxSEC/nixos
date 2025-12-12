/**
 * Context Manager
 *
 * Coordinates all context inference components to provide
 * enriched context for tool execution.
 */
import type { SQLiteKnowledgeDatabase } from '../knowledge/database.js';
import type { EnrichedContext, ProjectState } from '../types/context-inference.js';
import type { BatchActionResult } from '../types/proactive-actions.js';
/**
 * Context Manager
 */
export declare class ContextManager {
    private inputAnalyzer;
    private stateTracker;
    private database;
    private proactiveExecutor;
    constructor(projectRoot: string, database: SQLiteKnowledgeDatabase);
    /**
     * Analyze input and enrich with context
     */
    enrichContext(userInput: string): Promise<EnrichedContext>;
    /**
     * Find relevant knowledge from database
     */
    private findRelevantKnowledge;
    /**
     * Calculate context quality score
     */
    private calculateQuality;
    /**
     * Analyze input, enrich context, and execute proactive actions
     */
    enrichContextWithActions(userInput: string): Promise<{
        context: EnrichedContext;
        actions: BatchActionResult;
    }>;
    /**
     * Refresh project state
     */
    refreshState(): ProjectState;
}
//# sourceMappingURL=context-manager.d.ts.map