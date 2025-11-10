/**
 * Context Manager
 *
 * Coordinates all context inference components to provide
 * enriched context for tool execution.
 */
import { InputAnalyzer } from './input-analyzer.js';
import { ProjectStateTracker } from './project-state-tracker.js';
import { ProactiveExecutor } from './proactive-executor.js';
/**
 * Context Manager
 */
export class ContextManager {
    inputAnalyzer;
    stateTracker;
    database;
    proactiveExecutor;
    constructor(projectRoot, database) {
        this.inputAnalyzer = new InputAnalyzer();
        this.stateTracker = new ProjectStateTracker(projectRoot);
        this.database = database;
        this.proactiveExecutor = new ProactiveExecutor();
    }
    /**
     * Analyze input and enrich with context
     */
    async enrichContext(userInput) {
        // Analyze input
        const inputAnalysis = this.inputAnalyzer.analyze(userInput);
        // Get project state
        const projectState = this.stateTracker.getState();
        // Get relevant patterns
        const patterns = this.database.getPatterns(undefined, 5);
        // Get relevant knowledge
        const relevantKnowledge = await this.findRelevantKnowledge(inputAnalysis);
        // Calculate context quality
        const quality = this.calculateQuality(inputAnalysis, projectState);
        return {
            input: inputAnalysis,
            project: projectState,
            patterns,
            relevantKnowledge,
            quality,
        };
    }
    /**
     * Find relevant knowledge from database
     */
    async findRelevantKnowledge(input) {
        // Simple relevance scoring based on entities and topics
        const searchTerms = [
            ...input.entities.map(e => e.value),
            ...input.topics.flatMap(t => t.keywords),
        ];
        const results = [];
        // Query knowledge database (simplified)
        // In real implementation, use FTS5 or better search
        for (const term of searchTerms.slice(0, 5)) {
            try {
                const knowledge = await this.database.searchKnowledge({ query: term, limit: 3 });
                for (const item of knowledge) {
                    results.push({ id: item.entry.id, score: 0.5 });
                }
            }
            catch {
                // Ignore errors
            }
        }
        return results.slice(0, 10);
    }
    /**
     * Calculate context quality score
     */
    calculateQuality(input, project) {
        let score = 0;
        // Intent confidence
        if (input.intentConfidence === 'high')
            score += 0.3;
        else if (input.intentConfidence === 'medium')
            score += 0.2;
        else
            score += 0.1;
        // Entity extraction
        score += Math.min(input.entities.length * 0.1, 0.3);
        // Topic relevance
        score += Math.min(input.topics.length * 0.1, 0.2);
        // Project state availability
        if (project.git)
            score += 0.1;
        if (project.build)
            score += 0.1;
        return Math.min(score, 1.0);
    }
    /**
     * Analyze input, enrich context, and execute proactive actions
     */
    async enrichContextWithActions(userInput) {
        // Get enriched context
        const context = await this.enrichContext(userInput);
        // Execute proactive actions
        const actions = await this.proactiveExecutor.executeActions(context, this.stateTracker['projectRoot']);
        return { context, actions };
    }
    /**
     * Refresh project state
     */
    refreshState() {
        return this.stateTracker.refresh();
    }
}
//# sourceMappingURL=context-manager.js.map