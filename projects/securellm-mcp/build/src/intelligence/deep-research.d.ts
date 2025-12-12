/**
 * Deep Research Intelligence Module
 *
 * Provides multi-source parallel research with:
 * - Cross-reference validation
 * - Source credibility scoring
 * - Fact-checking against official sources
 * - Consensus detection
 */
export interface SourceResult {
    source: "github" | "stackoverflow" | "nixos_wiki" | "discourse" | "official_docs" | "reddit" | "hackernews";
    url: string;
    title: string;
    content: string;
    credibility: number;
    timestamp: string;
    relevance: number;
}
export interface Conflict {
    topic: string;
    sources: string[];
    positions: string[];
}
export interface FactCheckResult {
    verified: boolean;
    officialSource: string | null;
    confidence: number;
    notes: string[];
}
export interface ResearchResult {
    query: string;
    confidence: number;
    sources: SourceResult[];
    consensus: string | null;
    conflicts: Conflict[];
    factCheck: FactCheckResult;
    searchDuration: number;
    recommendations: string[];
}
/**
 * Deep Research Engine
 */
export declare class DeepResearchEngine {
    private cache;
    private readonly CACHE_TTL;
    /**
     * Perform deep multi-source research
     */
    research(query: string, options?: {
        depth?: "quick" | "standard" | "deep";
        requireOfficialSource?: boolean;
        maxSources?: number;
    }): Promise<ResearchResult>;
    /**
     * Get sources to search based on depth
     */
    private getSourcesForDepth;
    /**
     * Search a single source using native fetch
     */
    private searchSource;
    /**
     * Score and rank results by relevance
     */
    private scoreResults;
    /**
     * Detect consensus among sources
     */
    private detectConsensus;
    /**
     * Detect conflicts between sources
     */
    private detectConflicts;
    /**
     * Fact check against official sources
     */
    private factCheck;
    /**
     * Calculate overall confidence score
     */
    private calculateConfidence;
    /**
     * Generate recommendations based on research
     */
    private generateRecommendations;
}
export declare const deepResearch: DeepResearchEngine;
//# sourceMappingURL=deep-research.d.ts.map