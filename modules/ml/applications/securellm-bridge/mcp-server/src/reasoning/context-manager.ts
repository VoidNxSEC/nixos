/**
 * Context Manager
 * 
 * Coordinates all context inference components to provide
 * enriched context for tool execution.
 */

import { InputAnalyzer } from './input-analyzer.js';
import { ProjectStateTracker } from './project-state-tracker.js';
import { ProactiveExecutor } from './proactive-executor.js';
import type { SQLiteKnowledgeDatabase } from '../knowledge/database.js';
import type { EnrichedContext, InputAnalysis, ProjectState } from '../types/context-inference.js';
import type { BatchActionResult } from '../types/proactive-actions.js';

/**
 * Context Manager
 */
export class ContextManager {
  private inputAnalyzer: InputAnalyzer;
  private stateTracker: ProjectStateTracker;
  private database: SQLiteKnowledgeDatabase;
  private proactiveExecutor: ProactiveExecutor;

  constructor(projectRoot: string, database: SQLiteKnowledgeDatabase) {
    this.inputAnalyzer = new InputAnalyzer();
    this.stateTracker = new ProjectStateTracker(projectRoot);
    this.database = database;
    this.proactiveExecutor = new ProactiveExecutor();
  }

  /**
   * Analyze input and enrich with context
   */
  public async enrichContext(userInput: string): Promise<EnrichedContext> {
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
  private async findRelevantKnowledge(input: InputAnalysis): Promise<Array<{ id: number; score: number }>> {
    // Simple relevance scoring based on entities and topics
    const searchTerms = [
      ...input.entities.map(e => e.value),
      ...input.topics.flatMap(t => t.keywords),
    ];

    const results: Array<{ id: number; score: number }> = [];

    // Query knowledge database (simplified)
    // In real implementation, use FTS5 or better search
    for (const term of searchTerms.slice(0, 5)) {
      try {
        const knowledge = await this.database.searchKnowledge({ query: term, limit: 3 });
        for (const item of knowledge) {
          results.push({ id: item.entry.id, score: 0.5 });
        }
      } catch {
        // Ignore errors
      }
    }

    return results.slice(0, 10);
  }

  /**
   * Calculate context quality score
   */
  private calculateQuality(input: InputAnalysis, project: ProjectState): number {
    let score = 0;

    // Intent confidence
    if (input.intentConfidence === 'high') score += 0.3;
    else if (input.intentConfidence === 'medium') score += 0.2;
    else score += 0.1;

    // Entity extraction
    score += Math.min(input.entities.length * 0.1, 0.3);

    // Topic relevance
    score += Math.min(input.topics.length * 0.1, 0.2);

    // Project state availability
    if (project.git) score += 0.1;
    if (project.build) score += 0.1;

    return Math.min(score, 1.0);
  }

  /**
   * Analyze input, enrich context, and execute proactive actions
   */
  public async enrichContextWithActions(userInput: string): Promise<{
    context: EnrichedContext;
    actions: BatchActionResult;
  }> {
    // Get enriched context
    const context = await this.enrichContext(userInput);

    // Execute proactive actions
    const actions = await this.proactiveExecutor.executeActions(
      context,
      this.stateTracker['projectRoot']
    );

    return { context, actions };
  }

  /**
   * Refresh project state
   */
  public refreshState(): ProjectState {
    return this.stateTracker.refresh();
  }
}