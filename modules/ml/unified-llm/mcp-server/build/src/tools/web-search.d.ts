/**
 * Web Search Tools for MCP Server
 *
 * Provides tools to search the web for:
 * - NixOS configurations and examples
 * - Package information and news
 * - Bug reports and issues
 * - Features and enhancements
 * - Technical documentation
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
 * Execute web search using curl and DuckDuckGo's HTML API
 */
export declare function handleWebSearch(args: WebSearchArgs): Promise<{
    success: boolean;
    results: {
        query: string;
        search_type: "github" | "general" | "nixos" | "stackoverflow" | "reddit";
        instant_answer: any;
        related_topics: any;
        web_results: string[];
        sources: {
            name: any;
            url: any;
        }[];
    };
    message: string;
    error?: undefined;
} | {
    success: boolean;
    error: any;
    message: string;
    results?: undefined;
}>;
/**
 * Search NixOS packages and options
 */
export declare function handleNixSearch(args: NixSearchArgs): Promise<{
    success: boolean;
    channel: "stable" | "unstable";
    type: "options" | "packages";
    query: string;
    results: {
        path: string;
        name: any;
        version: any;
        description: any;
    }[];
    search_url: string;
    message?: undefined;
    note?: undefined;
    error?: undefined;
} | {
    success: boolean;
    channel: "stable" | "unstable";
    type: "options" | "packages";
    query: string;
    results: never[];
    search_url: string;
    message: string;
    note: string;
    error?: undefined;
} | {
    success: boolean;
    error: any;
    message: string;
    channel?: undefined;
    type?: undefined;
    query?: undefined;
    results?: undefined;
    search_url?: undefined;
    note?: undefined;
}>;
/**
 * Search GitHub using their API
 */
export declare function handleGithubSearch(args: GithubSearchArgs): Promise<{
    success: boolean;
    query: string;
    type: "code" | "issues" | "repositories";
    total_count: any;
    results: any;
    error?: undefined;
    message?: undefined;
} | {
    success: boolean;
    error: any;
    message: string;
    query?: undefined;
    type?: undefined;
    total_count?: undefined;
    results?: undefined;
}>;
/**
 * Search tech news sources
 */
export declare function handleTechNewsSearch(args: TechNewsArgs): Promise<any>;
/**
 * Search NixOS Discourse
 */
export declare function handleDiscourseSearch(args: {
    query: string;
    category?: string;
}): Promise<{
    success: boolean;
    query: string;
    category: string;
    results: any;
    total_results: any;
    error?: undefined;
    message?: undefined;
} | {
    success: boolean;
    error: any;
    message: string;
    query?: undefined;
    category?: undefined;
    results?: undefined;
    total_results?: undefined;
}>;
/**
 * Search Stack Overflow
 */
export declare function handleStackOverflowSearch(args: {
    query: string;
    tags?: string[];
    sort?: string;
}): Promise<{
    success: boolean;
    query: string;
    tags: string[];
    results: any;
    total_results: any;
    error?: undefined;
    message?: undefined;
} | {
    success: boolean;
    error: any;
    message: string;
    query?: undefined;
    tags?: undefined;
    results?: undefined;
    total_results?: undefined;
}>;
//# sourceMappingURL=web-search.d.ts.map