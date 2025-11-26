// Knowledge Management Tools for MCP

import type { Tool } from "@modelcontextprotocol/sdk/types.js";

export const knowledgeTools: Tool[] = [
  {
    name: "create_session",
    description: "Create a new knowledge session to organize your work. Sessions help group related knowledge entries together.",
    defer_loading: true,
    inputSchema: {
      type: "object",
      properties: {
        summary: {
          type: "string",
          description: "Optional brief summary of what this session is about",
        },
        metadata: {
          type: "object",
          description: "Optional metadata (project name, tags, etc.)",
        },
      },
    },
  },
  {
    name: "save_knowledge",
    description: "Save important information to the knowledge base. This could be an insight, code snippet, decision, or reference that you want to remember.",
    defer_loading: true,
    input_examples: [
      {
        content: "The project uses flake.nix for package management with nixos-rebuild for system configuration",
        type: "insight",
        tags: ["nixos", "architecture"],
        priority: "high"
      },
      {
        content: "function processData(input) { return input.map(x => x * 2); }",
        type: "code",
        tags: ["javascript", "data-processing"]
      }
    ],
    inputSchema: {
      type: "object",
      properties: {
        content: {
          type: "string",
          description: "The knowledge content to save",
        },
        type: {
          type: "string",
          enum: ["insight", "code", "decision", "reference", "question", "answer"],
          description: "Type of knowledge entry",
        },
        session_id: {
          type: "string",
          description: "Optional session ID. If not provided, creates a new session automatically.",
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional tags for categorization (e.g., ['rust', 'performance'])",
        },
        priority: {
          type: "string",
          enum: ["low", "medium", "high"],
          description: "Priority level (default: medium)",
        },
        metadata: {
          type: "object",
          description: "Optional additional metadata",
        },
      },
      required: ["content", "type"],
    },
  },
  {
    name: "search_knowledge",
    description: "Search the knowledge base using full-text search. Finds relevant entries based on content and tags.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query (supports boolean operators: AND, OR, NOT)",
        },
        session_id: {
          type: "string",
          description: "Optional: limit search to specific session",
        },
        entry_type: {
          type: "string",
          enum: ["insight", "code", "decision", "reference", "question", "answer"],
          description: "Optional: filter by entry type",
        },
        limit: {
          type: "number",
          description: "Maximum number of results (default: 10, max: 50)",
        },
      },
      required: ["query"],
    },
  },
  {
    name: "load_session",
    description: "Load a previous knowledge session to restore context. Returns all entries from that session.",
    defer_loading: true,
    inputSchema: {
      type: "object",
      properties: {
        session_id: {
          type: "string",
          description: "Session ID to load",
        },
      },
      required: ["session_id"],
    },
  },
  {
    name: "list_sessions",
    description: "List recent knowledge sessions. Shows your work history organized by session.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Number of sessions to return (default: 20)",
        },
        offset: {
          type: "number",
          description: "Offset for pagination (default: 0)",
        },
      },
    },
  },
  {
    name: "get_recent_knowledge",
    description: "Get the most recent knowledge entries, optionally filtered by session.",
    defer_loading: true,
    allowed_callers: ["code_execution_20250825"],
    inputSchema: {
      type: "object",
      properties: {
        session_id: {
          type: "string",
          description: "Optional: filter by session ID",
        },
        limit: {
          type: "number",
          description: "Number of entries to return (default: 20)",
        },
      },
    },
  },
];