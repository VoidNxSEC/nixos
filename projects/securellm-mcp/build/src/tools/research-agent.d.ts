/**
 * Research Agent Tool for MCP
 *
 * Provides deep multi-source research with:
 * - Parallel source querying
 * - Credibility scoring
 * - Fact-checking
 * - Actionable recommendations
 */
export interface ResearchAgentArgs {
    query: string;
    depth?: "quick" | "standard" | "deep";
    require_official_source?: boolean;
    max_sources?: number;
}
/**
 * Research Agent tool definition for MCP
 */
export declare const researchAgentTool: {
    name: string;
    description: string;
    defer_loading: boolean;
    input_examples: ({
        query: string;
        depth: string;
        require_official_source: boolean;
        max_sources?: undefined;
    } | {
        query: string;
        depth: string;
        require_official_source?: undefined;
        max_sources?: undefined;
    } | {
        query: string;
        depth: string;
        max_sources: number;
        require_official_source?: undefined;
    })[];
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            depth: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            require_official_source: {
                type: string;
                description: string;
                default: boolean;
            };
            max_sources: {
                type: string;
                description: string;
                default: number;
            };
        };
        required: string[];
    };
};
/**
 * Handle research_agent tool call
 */
export declare function handleResearchAgent(args: ResearchAgentArgs): Promise<{
    content: Array<{
        type: string;
        text: string;
    }>;
    isError?: boolean;
}>;
//# sourceMappingURL=research-agent.d.ts.map