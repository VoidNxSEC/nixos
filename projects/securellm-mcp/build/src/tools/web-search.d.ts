/**
 * Web Search Tools for MCP Server
 *
 * Enhanced version with:
 * - Native fetch (no curl dependency)
 * - Intelligent formatted outputs
 * - Actionable summaries
 * - Source credibility indicators
 */
export interface WebSearchArgs {
    query: string;
    search_type?: "general" | "nixos" | "github" | "stackoverflow" | "reddit";
    limit?: number;
}
export interface NixSearchArgs {
    package_name?: string;
    query?: string;
    channel?: "stable" | "unstable";
    type?: "packages" | "options";
}
export interface GithubSearchArgs {
    query: string;
    type?: "repositories" | "issues" | "code";
    language?: string;
    sort?: "stars" | "updated" | "relevance";
}
export interface TechNewsArgs {
    topic: string;
    source?: "hackernews" | "reddit" | "lobsters" | "all";
    time_range?: "day" | "week" | "month";
}
/**
 * Web search tool schemas for MCP
 */
export declare const webSearchTools: ({
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            search_type: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            limit: {
                type: string;
                description: string;
                default: number;
            };
            package_name?: undefined;
            channel?: undefined;
            type?: undefined;
            language?: undefined;
            sort?: undefined;
            topic?: undefined;
            source?: undefined;
            time_range?: undefined;
            category?: undefined;
            tags?: undefined;
        };
        required: string[];
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            package_name: {
                type: string;
                description: string;
            };
            query: {
                type: string;
                description: string;
            };
            channel: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            type: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            search_type?: undefined;
            limit?: undefined;
            language?: undefined;
            sort?: undefined;
            topic?: undefined;
            source?: undefined;
            time_range?: undefined;
            category?: undefined;
            tags?: undefined;
        };
        required?: undefined;
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            type: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            language: {
                type: string;
                description: string;
            };
            sort: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            search_type?: undefined;
            limit?: undefined;
            package_name?: undefined;
            channel?: undefined;
            topic?: undefined;
            source?: undefined;
            time_range?: undefined;
            category?: undefined;
            tags?: undefined;
        };
        required: string[];
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            topic: {
                type: string;
                description: string;
            };
            source: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            time_range: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            query?: undefined;
            search_type?: undefined;
            limit?: undefined;
            package_name?: undefined;
            channel?: undefined;
            type?: undefined;
            language?: undefined;
            sort?: undefined;
            category?: undefined;
            tags?: undefined;
        };
        required: string[];
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            category: {
                type: string;
                description: string;
            };
            search_type?: undefined;
            limit?: undefined;
            package_name?: undefined;
            channel?: undefined;
            type?: undefined;
            language?: undefined;
            sort?: undefined;
            topic?: undefined;
            source?: undefined;
            time_range?: undefined;
            tags?: undefined;
        };
        required: string[];
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            tags: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            sort: {
                type: string;
                enum: string[];
                description: string;
                default: string;
            };
            search_type?: undefined;
            limit?: undefined;
            package_name?: undefined;
            channel?: undefined;
            type?: undefined;
            language?: undefined;
            topic?: undefined;
            source?: undefined;
            time_range?: undefined;
            category?: undefined;
        };
        required: string[];
    };
})[];
/**
 * Execute web search using native fetch
 */
export declare function handleWebSearch(args: WebSearchArgs): Promise<{
    success: boolean;
    query: string;
    source: string;
    summary: string;
    result_count: number;
    results: any[];
    quick_answer: any;
    top_urls: any[];
} | {
    success: boolean;
    error: any;
    message: string;
    suggestion: string;
}>;
/**
 * Search GitHub using native fetch
 */
export declare function handleGithubSearch(args: GithubSearchArgs): Promise<{
    success: boolean;
    query: string;
    source: string;
    summary: string;
    result_count: number;
    results: any[];
    quick_answer: any;
    top_urls: any[];
} | {
    success: boolean;
    error: any;
    message: string;
}>;
/**
 * Search NixOS packages using nix command (local) or fallback URL
 */
export declare function handleNixSearch(args: NixSearchArgs): Promise<{
    success: boolean;
    query: string;
    source: string;
    summary: string;
    result_count: number;
    results: any[];
    quick_answer: any;
    top_urls: any[];
} | {
    success: boolean;
    query: string;
    source: string;
    message: string;
    search_url: string;
    quick_action: string;
    error?: undefined;
} | {
    success: boolean;
    error: any;
    message: string;
    query?: undefined;
    source?: undefined;
    search_url?: undefined;
    quick_action?: undefined;
}>;
/**
 * Search tech news using native fetch
 */
export declare function handleTechNewsSearch(args: TechNewsArgs): Promise<{
    success: boolean;
    query: string;
    source: string;
    summary: string;
    result_count: number;
    results: any[];
    quick_answer: any;
    top_urls: any[];
} | {
    success: boolean;
    error: any;
    message: string;
}>;
/**
 * Search NixOS Discourse using native fetch
 */
export declare function handleDiscourseSearch(args: {
    query: string;
    category?: string;
}): Promise<{
    success: boolean;
    query: string;
    source: string;
    summary: string;
    result_count: number;
    results: any[];
    quick_answer: any;
    top_urls: any[];
} | {
    success: boolean;
    error: any;
    message: string;
}>;
/**
 * Search Stack Overflow using native fetch
 */
export declare function handleStackOverflowSearch(args: {
    query: string;
    tags?: string[];
    sort?: string;
}): Promise<{
    success: boolean;
    query: string;
    source: string;
    summary: string;
    result_count: number;
    results: any[];
    quick_answer: any;
    top_urls: any[];
} | {
    success: boolean;
    error: any;
    message: string;
}>;
//# sourceMappingURL=web-search.d.ts.map