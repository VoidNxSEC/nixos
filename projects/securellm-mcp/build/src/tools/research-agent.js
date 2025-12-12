/**
 * Research Agent Tool for MCP
 *
 * Provides deep multi-source research with:
 * - Parallel source querying
 * - Credibility scoring
 * - Fact-checking
 * - Actionable recommendations
 */
import { deepResearch } from "../intelligence/deep-research.js";
/**
 * Research Agent tool definition for MCP
 */
export const researchAgentTool = {
    name: "research_agent",
    description: "Deep multi-source research with fact-checking and credibility scoring. Use this to verify information, find best practices, and reduce hallucinations by grounding responses in real sources.",
    defer_loading: true,
    input_examples: [
        {
            query: "NixOS nvidia driver configuration",
            depth: "deep",
            require_official_source: true,
        },
        {
            query: "flake input override",
            depth: "quick",
        },
        {
            query: "home-manager vs system configuration",
            depth: "standard",
            max_sources: 10,
        },
    ],
    inputSchema: {
        type: "object",
        properties: {
            query: {
                type: "string",
                description: "Research query - be specific for better results",
            },
            depth: {
                type: "string",
                enum: ["quick", "standard", "deep"],
                description: "Research depth: quick (2 sources, fast), standard (4 sources), deep (7+ sources, thorough)",
                default: "standard",
            },
            require_official_source: {
                type: "boolean",
                description: "Require verification from official NixOS documentation",
                default: false,
            },
            max_sources: {
                type: "number",
                description: "Maximum number of sources to return (default: 5)",
                default: 5,
            },
        },
        required: ["query"],
    },
};
/**
 * Handle research_agent tool call
 */
export async function handleResearchAgent(args) {
    const { query, depth = "standard", require_official_source = false, max_sources = 5 } = args;
    try {
        const result = await deepResearch.research(query, {
            depth,
            requireOfficialSource: require_official_source,
            maxSources: max_sources,
        });
        // Format response
        const response = formatResearchResponse(result);
        return {
            content: [
                {
                    type: "text",
                    text: JSON.stringify(response, null, 2),
                },
            ],
        };
    }
    catch (error) {
        return {
            content: [
                {
                    type: "text",
                    text: JSON.stringify({
                        success: false,
                        error: error.message,
                        query,
                    }, null, 2),
                },
            ],
            isError: true,
        };
    }
}
/**
 * Format research result for MCP response
 */
function formatResearchResponse(result) {
    return {
        success: true,
        query: result.query,
        confidence: result.confidence,
        confidence_label: getConfidenceLabel(result.confidence),
        // Main findings
        consensus: result.consensus,
        // Sources with details
        sources: result.sources.map(s => ({
            source: s.source,
            title: s.title,
            url: s.url,
            credibility: s.credibility,
            credibility_label: getCredibilityLabel(s.credibility),
        })),
        // Verification status
        fact_check: {
            verified: result.factCheck.verified,
            official_source: result.factCheck.officialSource,
            confidence: result.factCheck.confidence,
            notes: result.factCheck.notes,
        },
        // Conflicts if any
        conflicts: result.conflicts.length > 0 ? result.conflicts : null,
        // Actionable items
        recommendations: result.recommendations,
        // Metadata
        search_duration_ms: result.searchDuration,
        source_count: result.sources.length,
    };
}
/**
 * Get human-readable confidence label
 */
function getConfidenceLabel(confidence) {
    if (confidence >= 0.9)
        return "very_high";
    if (confidence >= 0.7)
        return "high";
    if (confidence >= 0.5)
        return "medium";
    if (confidence >= 0.3)
        return "low";
    return "very_low";
}
/**
 * Get human-readable credibility label
 */
function getCredibilityLabel(credibility) {
    if (credibility >= 0.9)
        return "authoritative";
    if (credibility >= 0.7)
        return "reliable";
    if (credibility >= 0.5)
        return "moderate";
    return "unverified";
}
//# sourceMappingURL=research-agent.js.map