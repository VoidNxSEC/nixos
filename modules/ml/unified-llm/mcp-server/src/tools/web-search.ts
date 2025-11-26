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

import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

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
export const webSearchTools = [
  {
    name: "web_search",
    description: "Search the web for configurations, news, features, issues, and bug reports. Uses DuckDuckGo for privacy-focused searches.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    input_examples: [
      {
        query: "nixos flake configuration examples",
        search_type: "nixos"
      },
      {
        query: "thermal throttling laptop linux",
        search_type: "general",
        limit: 5
      }
    ],
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query",
        },
        search_type: {
          type: "string",
          enum: ["general", "nixos", "github", "stackoverflow", "reddit"],
          description: "Type of search to perform (default: general)",
          default: "general",
        },
        limit: {
          type: "number",
          description: "Maximum number of results to return (default: 10)",
          default: 10,
        },
      },
      required: ["query"],
    },
  },
  {
    name: "nix_search",
    description: "Search NixOS packages and options on search.nixos.org. Find package configurations, versions, and documentation.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    input_examples: [
      {
        package_name: "firefox",
        channel: "unstable",
        type: "packages"
      },
      {
        query: "networking firewall",
        type: "options",
        channel: "stable"
      }
    ],
    inputSchema: {
      type: "object",
      properties: {
        package_name: {
          type: "string",
          description: "Specific package name to search for",
        },
        query: {
          type: "string",
          description: "General search query",
        },
        channel: {
          type: "string",
          enum: ["stable", "unstable"],
          description: "NixOS channel to search (default: unstable)",
          default: "unstable",
        },
        type: {
          type: "string",
          enum: ["packages", "options"],
          description: "Search type (default: packages)",
          default: "packages",
        },
      },
    },
  },
  {
    name: "github_search",
    description: "Search GitHub for repositories, issues, and code. Find NixOS configurations, bug reports, and implementation examples.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    input_examples: [
      {
        query: "nixos configuration thermal management",
        type: "repositories",
        language: "nix",
        sort: "stars"
      },
      {
        query: "nvidia drivers thermal throttling",
        type: "issues",
        sort: "updated"
      }
    ],
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "GitHub search query",
        },
        type: {
          type: "string",
          enum: ["repositories", "issues", "code"],
          description: "Type of GitHub content to search (default: repositories)",
          default: "repositories",
        },
        language: {
          type: "string",
          description: "Filter by programming language (e.g., 'nix', 'python')",
        },
        sort: {
          type: "string",
          enum: ["stars", "updated", "relevance"],
          description: "Sort results by (default: relevance)",
          default: "relevance",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "tech_news_search",
    description: "Search tech news sources (Hacker News, Reddit, Lobsters) for discussions about packages, features, and issues.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    input_examples: [
      {
        topic: "NixOS 24.11 release",
        source: "all",
        time_range: "week"
      },
      {
        topic: "nvidia drivers linux",
        source: "reddit",
        time_range: "month"
      }
    ],
    inputSchema: {
      type: "object",
      properties: {
        topic: {
          type: "string",
          description: "Topic to search for (e.g., 'NixOS 24.11', 'nvidia drivers')",
        },
        source: {
          type: "string",
          enum: ["hackernews", "reddit", "lobsters", "all"],
          description: "News source to search (default: all)",
          default: "all",
        },
        time_range: {
          type: "string",
          enum: ["day", "week", "month"],
          description: "Time range for search (default: week)",
          default: "week",
        },
      },
      required: ["topic"],
    },
  },
  {
    name: "nixos_discourse_search",
    description: "Search NixOS Discourse forum for community discussions, solutions, and best practices.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query for Discourse",
        },
        category: {
          type: "string",
          description: "Filter by category (e.g., 'Help', 'Development')",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "stackoverflow_search",
    description: "Search Stack Overflow for technical solutions and code examples related to NixOS and related technologies.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Stack Overflow search query",
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Filter by tags (e.g., ['nixos', 'nix'])",
        },
        sort: {
          type: "string",
          enum: ["relevance", "votes", "activity", "creation"],
          description: "Sort results by (default: relevance)",
          default: "relevance",
        },
      },
      required: ["query"],
    },
  },
];

/**
 * Execute web search using curl and DuckDuckGo's HTML API
 */
export async function handleWebSearch(args: WebSearchArgs) {
  const { query, search_type = "general", limit = 10 } = args;

  try {
    let searchQuery = query;
    
    // Add site-specific filters based on search type
    switch (search_type) {
      case "nixos":
        searchQuery = `${query} site:nixos.org OR site:discourse.nixos.org OR site:nixos.wiki`;
        break;
      case "github":
        searchQuery = `${query} site:github.com`;
        break;
      case "stackoverflow":
        searchQuery = `${query} site:stackoverflow.com`;
        break;
      case "reddit":
        searchQuery = `${query} site:reddit.com/r/nixos OR site:reddit.com/r/nix`;
        break;
    }

    // Use DuckDuckGo's instant answer API (simpler than scraping HTML)
    const encodedQuery = encodeURIComponent(searchQuery);
    const ddgUrl = `https://api.duckduckgo.com/?q=${encodedQuery}&format=json&no_html=1&skip_disambig=1`;

    const { stdout } = await execAsync(
      `curl -s -L "${ddgUrl}" --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"`
    );

    const data = JSON.parse(stdout);
    
    // Also get web results using lite.duckduckgo.com (text-only interface)
    const liteUrl = `https://lite.duckduckgo.com/lite/?q=${encodedQuery}`;
    const { stdout: htmlResults } = await execAsync(
      `curl -s -L "${liteUrl}" --user-agent "Mozilla/5.0 (X11; Linux x86_64)" | grep -oP '(?<=href=")[^"]+(?=")' | grep '^http' | head -${limit}`
    );

    const results = {
      query: searchQuery,
      search_type,
      instant_answer: data.AbstractText || data.Answer || null,
      related_topics: data.RelatedTopics?.slice(0, 5).map((t: any) => ({
        text: t.Text,
        url: t.FirstURL,
      })) || [],
      web_results: htmlResults.trim().split('\n').filter((url: string) => url.length > 0),
      sources: data.AbstractSource ? [
        {
          name: data.AbstractSource,
          url: data.AbstractURL,
        }
      ] : [],
    };

    return {
      success: true,
      results,
      message: `Found ${results.web_results.length} results for "${query}"`,
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      message: "Web search failed",
    };
  }
}

/**
 * Search NixOS packages and options
 */
export async function handleNixSearch(args: NixSearchArgs) {
  const { package_name, query, channel = "unstable", type = "packages" } = args;

  try {
    const searchTerm = package_name || query;
    if (!searchTerm) {
      throw new Error("Either package_name or query must be provided");
    }

    // Use nix search command if available, fallback to API
    try {
      const nixChannel = channel === "stable" ? "nixpkgs" : "nixpkgs/nixos-unstable";
      const { stdout } = await execAsync(
        `nix search ${nixChannel} ${searchTerm} --json 2>/dev/null || echo '{}'`,
        { timeout: 15000 }
      );

      const nixResults = JSON.parse(stdout);
      
      return {
        success: true,
        channel,
        type,
        query: searchTerm,
        results: Object.entries(nixResults).map(([path, info]: [string, any]) => ({
          path,
          name: info.pname || path.split('.').pop(),
          version: info.version,
          description: info.description,
        })),
        search_url: `https://search.nixos.org/${type}?channel=${channel === "stable" ? "24.05" : "unstable"}&query=${encodeURIComponent(searchTerm)}`,
      };
    } catch (nixError) {
      // Fallback to web scraping search.nixos.org
      const searchUrl = `https://search.nixos.org/${type}?channel=${channel === "stable" ? "24.05" : "unstable"}&query=${encodeURIComponent(searchTerm)}`;
      
      return {
        success: true,
        channel,
        type,
        query: searchTerm,
        results: [],
        search_url: searchUrl,
        message: "Using web interface - visit the URL for results",
        note: "Install 'nix' command for better search results",
      };
    }
  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      message: "NixOS search failed",
    };
  }
}

/**
 * Search GitHub using their API
 */
export async function handleGithubSearch(args: GithubSearchArgs) {
  const { query, type = "repositories", language, sort = "relevance" } = args;

  try {
    let searchQuery = query;
    if (language) {
      searchQuery += ` language:${language}`;
    }

    const encodedQuery = encodeURIComponent(searchQuery);
    const apiUrl = `https://api.github.com/search/${type}?q=${encodedQuery}&sort=${sort}&per_page=10`;

    const { stdout } = await execAsync(
      `curl -s -H "Accept: application/vnd.github.v3+json" "${apiUrl}"`
    );

    const data = JSON.parse(stdout);

    if (data.items) {
      return {
        success: true,
        query,
        type,
        total_count: data.total_count,
        results: data.items.map((item: any) => {
          if (type === "repositories") {
            return {
              name: item.full_name,
              description: item.description,
              url: item.html_url,
              stars: item.stargazers_count,
              language: item.language,
              updated: item.updated_at,
            };
          } else if (type === "issues") {
            return {
              title: item.title,
              url: item.html_url,
              state: item.state,
              labels: item.labels?.map((l: any) => l.name) || [],
              created: item.created_at,
              updated: item.updated_at,
            };
          } else {
            return {
              path: item.path,
              repository: item.repository?.full_name,
              url: item.html_url,
            };
          }
        }),
      };
    }

    return {
      success: false,
      error: data.message || "Unknown error",
      message: "GitHub search failed",
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      message: "GitHub search failed",
    };
  }
}

/**
 * Search tech news sources
 */
export async function handleTechNewsSearch(args: TechNewsArgs) {
  const { topic, source = "all", time_range = "week" } = args;

  try {
    const results: any = {
      topic,
      source,
      time_range,
      sources: [],
    };

    // Search Hacker News via Algolia API
    if (source === "hackernews" || source === "all") {
      const timeFilter = time_range === "day" ? "created_at_i>$" + (Date.now() / 1000 - 86400) :
                         time_range === "week" ? "created_at_i>" + (Date.now() / 1000 - 604800) :
                         "created_at_i>" + (Date.now() / 1000 - 2592000);
      
      const hnUrl = `https://hn.algolia.com/api/v1/search?query=${encodeURIComponent(topic)}&tags=story&numericFilters=${timeFilter}`;
      
      try {
        const { stdout: hnData } = await execAsync(`curl -s "${hnUrl}"`);
        const hn = JSON.parse(hnData);
        
        results.sources.push({
          name: "Hacker News",
          results: hn.hits?.slice(0, 5).map((hit: any) => ({
            title: hit.title,
            url: hit.url || `https://news.ycombinator.com/item?id=${hit.objectID}`,
            points: hit.points,
            comments: hit.num_comments,
            created: new Date(hit.created_at).toISOString(),
          })) || [],
        });
      } catch (e) {
        console.error("HN search failed:", e);
      }
    }

    // Search Reddit via pushshift/reddit API
    if (source === "reddit" || source === "all") {
      const subreddits = "nixos,nix,linux";
      const redditQuery = `${topic} subreddit:${subreddits}`;
      const redditUrl = `https://www.reddit.com/search.json?q=${encodeURIComponent(redditQuery)}&limit=5&sort=relevance`;
      
      try {
        const { stdout: redditData } = await execAsync(
          `curl -s -H "User-Agent: Mozilla/5.0" "${redditUrl}"`
        );
        const reddit = JSON.parse(redditData);
        
        results.sources.push({
          name: "Reddit",
          results: reddit.data?.children?.map((child: any) => ({
            title: child.data.title,
            url: `https://reddit.com${child.data.permalink}`,
            subreddit: child.data.subreddit,
            score: child.data.score,
            comments: child.data.num_comments,
            created: new Date(child.data.created_utc * 1000).toISOString(),
          })) || [],
        });
      } catch (e) {
        console.error("Reddit search failed:", e);
      }
    }

    return {
      success: true,
      ...results,
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      message: "Tech news search failed",
    };
  }
}

/**
 * Search NixOS Discourse
 */
export async function handleDiscourseSearch(args: { query: string; category?: string }) {
  const { query, category } = args;

  try {
    let searchUrl = `https://discourse.nixos.org/search.json?q=${encodeURIComponent(query)}`;
    if (category) {
      searchUrl += `&category=${encodeURIComponent(category)}`;
    }

    const { stdout } = await execAsync(`curl -s "${searchUrl}"`);
    const data = JSON.parse(stdout);

    return {
      success: true,
      query,
      category: category || "all",
      results: data.posts?.slice(0, 10).map((post: any) => ({
        title: post.blurb,
        url: `https://discourse.nixos.org/t/${post.topic_id}/${post.post_number}`,
        username: post.username,
        likes: post.like_count,
        created: post.created_at,
      })) || [],
      total_results: data.posts?.length || 0,
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      message: "Discourse search failed",
    };
  }
}

/**
 * Search Stack Overflow
 */
export async function handleStackOverflowSearch(args: { query: string; tags?: string[]; sort?: string }) {
  const { query, tags, sort = "relevance" } = args;

  try {
    let searchQuery = query;
    if (tags && tags.length > 0) {
      searchQuery += ` [${tags.join("] [")}]`;
    }

    const apiUrl = `https://api.stackexchange.com/2.3/search/advanced?order=desc&sort=${sort}&q=${encodeURIComponent(searchQuery)}&site=stackoverflow`;

    const { stdout } = await execAsync(`curl -s "${apiUrl}"`);
    const data = JSON.parse(stdout);

    return {
      success: true,
      query,
      tags: tags || [],
      results: data.items?.slice(0, 10).map((item: any) => ({
        title: item.title,
        url: item.link,
        score: item.score,
        answer_count: item.answer_count,
        is_answered: item.is_answered,
        view_count: item.view_count,
        tags: item.tags,
        created: new Date(item.creation_date * 1000).toISOString(),
      })) || [],
      total_results: data.items?.length || 0,
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message,
      message: "Stack Overflow search failed",
    };
  }
}