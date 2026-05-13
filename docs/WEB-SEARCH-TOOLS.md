# Web Search Tools for MCP Server

Comprehensive web search capabilities for finding NixOS configurations, package information, bug reports, features, and community discussions.

## Overview

The MCP server now includes 6 specialized web search tools that help you research:
- **Configurations & Examples**: Find real-world NixOS configurations and implementation patterns
- **Package Information**: Search for packages, versions, and options
- **Bug Reports & Issues**: Track down known issues and their solutions
- **Features & News**: Stay updated on latest developments
- **Community Discussions**: Access community knowledge from multiple sources

## Available Tools

### 1. `web_search` - General Web Search

Privacy-focused web search using DuckDuckGo. Supports specialized search types for different contexts.

**Parameters:**
- `query` (required): Search query
- `search_type` (optional): One of:
  - `general` - General web search (default)
  - `nixos` - Limit to NixOS-related sites
  - `github` - Search GitHub repositories
  - `stackoverflow` - Search Stack Overflow
  - `reddit` - Search NixOS subreddits
- `limit` (optional): Max results (default: 10)

**Example Usage:**
```typescript
{
  "query": "NixOS flake configuration examples",
  "search_type": "nixos",
  "limit": 5
}
```

**Use Cases:**
- Find configuration examples for specific features
- Research best practices and patterns
- Locate troubleshooting guides
- Discover recent discussions

---

### 2. `nix_search` - NixOS Packages & Options

Search the official NixOS package and option database. Integrates with `nix search` command when available.

**Parameters:**
- `package_name` (optional): Specific package to search
- `query` (optional): General search term
- `channel` (optional): `stable` or `unstable` (default: unstable)
- `type` (optional): `packages` or `options` (default: packages)

**Example Usage:**
```typescript
// Search for a package
{
  "package_name": "nvidia-docker",
  "channel": "unstable"
}

// Search for options
{
  "query": "networking.firewall",
  "type": "options"
}
```

**Use Cases:**
- Find package versions and descriptions
- Locate NixOS configuration options
- Check package availability in different channels
- Verify package attributes and metadata

---

### 3. `github_search` - GitHub Search

Search GitHub for repositories, issues, and code snippets using GitHub's API.

**Parameters:**
- `query` (required): GitHub search query
- `type` (optional): `repositories`, `issues`, or `code` (default: repositories)
- `language` (optional): Filter by language (e.g., "nix", "python")
- `sort` (optional): `stars`, `updated`, or `relevance` (default: relevance)

**Example Usage:**
```typescript
// Find popular NixOS configurations
{
  "query": "nixos configuration",
  "type": "repositories",
  "language": "nix",
  "sort": "stars"
}

// Search for issues
{
  "query": "nvidia driver nixos",
  "type": "issues"
}

// Find code examples
{
  "query": "buildPythonPackage override",
  "type": "code",
  "language": "nix"
}
```

**Use Cases:**
- Find popular NixOS configurations
- Track down bug reports and their fixes
- Discover implementation examples
- Monitor project activity

---

### 4. `tech_news_search` - Tech News & Discussions

Search tech news aggregators for discussions about packages, features, and issues.

**Parameters:**
- `topic` (required): Topic to search for
- `source` (optional): `hackernews`, `reddit`, `lobsters`, or `all` (default: all)
- `time_range` (optional): `day`, `week`, or `month` (default: week)

**Example Usage:**
```typescript
{
  "topic": "NixOS 24.11 release",
  "source": "all",
  "time_range": "week"
}
```

**Sources:**
- **Hacker News**: Technical discussions and announcements
- **Reddit**: r/nixos, r/nix community discussions
- **Lobsters**: Programming community discussions (future)

**Use Cases:**
- Stay updated on new releases
- Find community reactions to features
- Discover emerging issues
- Learn about performance improvements

---

### 5. `nixos_discourse_search` - NixOS Forum

Search the official NixOS Discourse forum for community solutions and discussions.

**Parameters:**
- `query` (required): Search query
- `category` (optional): Filter by category (e.g., "Help", "Development")

**Example Usage:**
```typescript
{
  "query": "docker nvidia support",
  "category": "Help"
}
```

**Use Cases:**
- Find solutions to common problems
- Access community best practices
- Learn from expert answers
- Follow feature discussions

---

### 6. `stackoverflow_search` - Stack Overflow

Search Stack Overflow for technical solutions and code examples.

**Parameters:**
- `query` (required): Search query
- `tags` (optional): Filter by tags (e.g., ["nixos", "nix"])
- `sort` (optional): `relevance`, `votes`, `activity`, or `creation` (default: relevance)

**Example Usage:**
```typescript
{
  "query": "override python package nixos",
  "tags": ["nixos", "nix"],
  "sort": "votes"
}
```

**Use Cases:**
- Find technical solutions
- Get code examples
- Access expert answers
- Solve specific problems

---

## Common Use Cases

### 1. Researching Package Configuration

**Scenario:** You want to configure a complex package like NVIDIA drivers.

**Approach:**
```typescript
// Step 1: Search official docs
nix_search({ query: "nvidia", type: "options" })

// Step 2: Find community configs
github_search({ 
  query: "nvidia configuration.nix", 
  type: "code",
  language: "nix" 
})

// Step 3: Check for issues
github_search({ 
  query: "nvidia driver nixos", 
  type: "issues" 
})

// Step 4: Read discussions
nixos_discourse_search({ query: "nvidia driver setup" })
```

### 2. Troubleshooting Build Failures

**Scenario:** Package build is failing with an obscure error.

**Approach:**
```typescript
// Step 1: Search for the error
web_search({ 
  query: "error message here nixos", 
  search_type: "nixos" 
})

// Step 2: Check GitHub issues
github_search({ 
  query: "error message package-name", 
  type: "issues" 
})

// Step 3: Search Stack Overflow
stackoverflow_search({ 
  query: "error message", 
  tags: ["nixos"] 
})
```

### 3. Finding Implementation Examples

**Scenario:** You need to implement a custom derivation.

**Approach:**
```typescript
// Step 1: Find similar packages
github_search({ 
  query: "similar-package nixos", 
  type: "code",
  language: "nix" 
})

// Step 2: Search for tutorials
web_search({ 
  query: "custom derivation tutorial nixos" 
})

// Step 3: Check official examples
nix_search({ package_name: "similar-package" })
```

### 4. Staying Updated

**Scenario:** Track new features and changes in NixOS.

**Approach:**
```typescript
// Step 1: Check recent news
tech_news_search({ 
  topic: "nixos", 
  time_range: "week" 
})

// Step 2: Monitor GitHub activity
github_search({ 
  query: "nixos", 
  type: "repositories",
  sort: "updated" 
})

// Step 3: Read forum discussions
nixos_discourse_search({ query: "announcement" })
```

---

## Best Practices

### 1. Search Strategy

- **Start Broad, Then Narrow**: Begin with general searches, then refine based on results
- **Use Multiple Sources**: Cross-reference information from different tools
- **Check Dates**: Prioritize recent information for fast-moving topics
- **Verify Solutions**: Test solutions in a safe environment before production

### 2. Query Crafting

- **Be Specific**: Include version numbers and specific error messages
- **Use Quotes**: Exact phrases in quotes for precise matching
- **Combine Terms**: Use relevant keywords together
- **Filter by Time**: Recent results for bug fixes, all-time for stable solutions

### 3. Privacy & Security

- **DuckDuckGo**: All general web searches use privacy-focused DuckDuckGo
- **No Tracking**: No search history is stored by the tools
- **API Limits**: Respects rate limits of external services
- **Local Execution**: All tools run locally on your machine

---

## Technical Details

### Dependencies

All web search functionality uses only standard tools:
- `curl`: HTTP requests
- `grep`, `jq`: Response parsing
- `nix search`: Package search (when available)

No additional packages are required.

### Rate Limiting

- **GitHub API**: 60 requests/hour (unauthenticated)
- **Other APIs**: Best-effort rate limiting
- **Retry Logic**: Automatic retry with backoff

### Error Handling

All tools return structured JSON with:
```typescript
{
  success: boolean,
  results?: any[],
  error?: string,
  message?: string
}
```

### Response Format

Results include:
- **URLs**: Direct links to content
- **Metadata**: Scores, dates, authors
- **Context**: Descriptions and excerpts
- **Source Info**: Where the result came from

---

## Integration with Roo/Claude

These tools are designed to integrate seamlessly with Roo/Claude workflows:

1. **Context Building**: Gather information before making changes
2. **Verification**: Confirm approaches with community examples
3. **Troubleshooting**: Find solutions to errors and issues
4. **Learning**: Discover best practices and patterns

---

## Future Enhancements

Planned improvements:
- [ ] Caching for repeated queries
- [ ] GitHub authentication for higher rate limits
- [ ] Additional sources (Lobsters, Dev.to)
- [ ] Result ranking and deduplication
- [ ] Search history and favorites
- [ ] Semantic search capabilities

---

## Examples

### Example 1: Finding Flake Configuration

```typescript
// Search for flake examples
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "github_search",
  arguments: {
    query: "flake.nix home-manager",
    type: "code",
    language: "nix",
    sort: "stars"
  }
})
```

### Example 2: Researching Package Issues

```typescript
// Check for known issues
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "github_search",
  arguments: {
    query: "nvidia-docker nixos is:issue",
    type: "issues"
  }
})
```

### Example 3: Community Best Practices

```typescript
// Find discussions
await use_mcp_tool({
  server_name: "securellm-bridge",
  tool_name: "nixos_discourse_search",
  arguments: {
    query: "home manager best practices",
    category: "Development"
  }
})
```

---

## Troubleshooting

### Common Issues

**Problem**: No results returned
- **Solution**: Try broader search terms or different search types

**Problem**: Rate limit errors
- **Solution**: Wait a few minutes and retry, or use alternative tools

**Problem**: Outdated results
- **Solution**: Filter by date or use `time_range` parameter

**Problem**: Too many irrelevant results
- **Solution**: Use more specific queries or filter by language/tags

---

## Support

For issues or feature requests:
1. Check existing GitHub issues
2. Search NixOS Discourse
3. Create a new issue with reproduction steps

---

## Related Documentation

- [`docs/MCP-EXTENDED-TOOLS-DESIGN.md`](./MCP-EXTENDED-TOOLS-DESIGN.md) - Tool architecture
- [`modules/ml/unified-llm/mcp-server/README.md`](../modules/ml/unified-llm/mcp-server/README.md) - Server setup
- [`AGENTS.md`](../AGENTS.md) - Agent guidelines