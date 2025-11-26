/**
 * Input Analyzer
 *
 * Analyzes user input to extract intent, entities, and topics.
 * Uses keyword matching and pattern recognition.
 */
import type { InputAnalysis } from '../types/context-inference.js';
/**
 * Input Analyzer
 */
export declare class InputAnalyzer {
    /**
     * Analyze user input
     */
    analyze(text: string): InputAnalysis;
    /**
     * Classify intent from text
     */
    private classifyIntent;
    /**
     * Calculate intent confidence
     */
    private calculateIntentConfidence;
    /**
     * Extract entities from text
     */
    private extractEntities;
    /**
     * Extract topics from text
     */
    private extractTopics;
}
//# sourceMappingURL=input-analyzer.d.ts.map