#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ListToolsRequestSchema,
  ReadResourceRequestSchema,
  ErrorCode,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";
import { exec } from "child_process";
import { promisify } from "util";
import * as fs from "fs/promises";
import { createKnowledgeDatabase } from "./knowledge/database.js";
import { knowledgeTools } from "./tools/knowledge.js";
import type { KnowledgeDatabase, CreateSessionInput, SaveKnowledgeInput, SearchKnowledgeInput } from "./types/knowledge.js";
import * as path from "path";

const execAsync = promisify(exec);

const PROJECT_ROOT = process.env.PROJECT_ROOT || process.cwd();
const KNOWLEDGE_DB_PATH = process.env.KNOWLEDGE_DB_PATH || path.join(PROJECT_ROOT, "knowledge.db");
const ENABLE_KNOWLEDGE = process.env.ENABLE_KNOWLEDGE !== 'false';

interface ProviderTestArgs {
  provider: string;
  prompt: string;
  model?: string;
}

interface SecurityAuditArgs {
  config_file: string;
}

interface RateLimitCheckArgs {
  provider: string;
}

interface BuildAndTestArgs {
  test_type: "unit" | "integration" | "all";
}

interface ProviderConfigValidateArgs {
  provider: string;
  config_data: string;
}

interface CryptoKeyGenerateArgs {
  key_type: "server" | "client";
  output_path: string;
}

class SecureLLMBridgeMCPServer {
  private server: Server;
  private db: KnowledgeDatabase | null = null;

  constructor() {
    this.server = new Server(
      {
        name: "securellm-bridge",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
          resources: {},
        },
      }
    );

    this.setupToolHandlers();
    this.setupResourceHandlers();
    
    // Initialize knowledge database if enabled
    if (ENABLE_KNOWLEDGE) {
      this.initKnowledge();
    }
    
    this.server.onerror = (error) => console.error("[MCP Error]", error);
    process.on("SIGINT", async () => {
      if (this.db) {
        this.db.close();
      }
      await this.server.close();
      process.exit(0);
    });
  }

  private initKnowledge() {
    try {
      this.db = createKnowledgeDatabase(KNOWLEDGE_DB_PATH);
      console.error('[Knowledge] Database initialized at:', KNOWLEDGE_DB_PATH);
    } catch (error) {
      console.error('[Knowledge] Failed to initialize:', error);
      this.db = null;
    }
  }

  private setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: "provider_test",
          description: "Test LLM provider connectivity with a sample query",
          inputSchema: {
            type: "object",
            properties: {
              provider: {
                type: "string",
                description: "Provider name (deepseek, openai, anthropic, ollama)",
                enum: ["deepseek", "openai", "anthropic", "ollama"],
              },
              prompt: {
                type: "string",
                description: "Test prompt to send to the provider",
              },
              model: {
                type: "string",
                description: "Model name (optional, uses default if not specified)",
              },
            },
            required: ["provider", "prompt"],
          },
        },
        {
          name: "security_audit",
          description: "Run security checks on project configuration",
          inputSchema: {
            type: "object",
            properties: {
              config_file: {
                type: "string",
                description: "Path to configuration file to audit",
              },
            },
            required: ["config_file"],
          },
        },
        {
          name: "rate_limit_check",
          description: "Check current rate limit status for a provider",
          inputSchema: {
            type: "object",
            properties: {
              provider: {
                type: "string",
                description: "Provider name to check",
                enum: ["deepseek", "openai", "anthropic", "ollama"],
              },
            },
            required: ["provider"],
          },
        },
        {
          name: "build_and_test",
          description: "Build the project and run tests",
          inputSchema: {
            type: "object",
            properties: {
              test_type: {
                type: "string",
                description: "Type of tests to run",
                enum: ["unit", "integration", "all"],
              },
            },
            required: ["test_type"],
          },
        },
        {
          name: "provider_config_validate",
          description: "Validate provider configuration format",
          inputSchema: {
            type: "object",
            properties: {
              provider: {
                type: "string",
                description: "Provider name",
              },
              config_data: {
                type: "string",
                description: "Configuration data in TOML format",
              },
            },
            required: ["provider", "config_data"],
          },
        },
        {
          name: "crypto_key_generate",
          description: "Generate TLS certificates and keys for secure communication",
          inputSchema: {
            type: "object",
            properties: {
              key_type: {
                type: "string",
                description: "Type of key to generate",
                enum: ["server", "client"],
              },
              output_path: {
                type: "string",
                description: "Directory path where keys should be saved",
              },
            },
            required: ["key_type", "output_path"],
          },
        },
        // Add knowledge tools if enabled
        ...(ENABLE_KNOWLEDGE && this.db ? knowledgeTools : []),
      ],
    }));

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      try {
        const { name, arguments: args } = request.params;

        switch (name) {
          case "provider_test":
            return await this.handleProviderTest(args as unknown as ProviderTestArgs);
          case "security_audit":
            return await this.handleSecurityAudit(args as unknown as SecurityAuditArgs);
          case "rate_limit_check":
            return await this.handleRateLimitCheck(args as unknown as RateLimitCheckArgs);
          case "build_and_test":
            return await this.handleBuildAndTest(args as unknown as BuildAndTestArgs);
          case "provider_config_validate":
            return await this.handleProviderConfigValidate(args as unknown as ProviderConfigValidateArgs);
          case "crypto_key_generate":
            return await this.handleCryptoKeyGenerate(args as unknown as CryptoKeyGenerateArgs);
          case "create_session":
            return await this.handleCreateSession(args);
          case "save_knowledge":
            return await this.handleSaveKnowledge(args);
          case "search_knowledge":
            return await this.handleSearchKnowledge(args);
          case "load_session":
            return await this.handleLoadSession(args);
          case "list_sessions":
            return await this.handleListSessions(args);
          case "get_recent_knowledge":
            return await this.handleGetRecentKnowledge(args);
          default:
            throw new McpError(
              ErrorCode.MethodNotFound,
              `Unknown tool: ${name}`
            );
        }
      } catch (error) {
        if (error instanceof McpError) throw error;
        throw new McpError(
          ErrorCode.InternalError,
          `Tool execution failed: ${error}`
        );
      }
    });
  }

  private setupResourceHandlers() {
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
      resources: [
        {
          uri: "config://current",
          name: "Current Configuration",
          description: "Current SecureLLM Bridge configuration",
          mimeType: "application/toml",
        },
        {
          uri: "logs://audit",
          name: "Audit Logs",
          description: "Recent audit log entries",
          mimeType: "application/json",
        },
        {
          uri: "metrics://usage",
          name: "Usage Metrics",
          description: "Provider usage statistics",
          mimeType: "application/json",
        },
        {
          uri: "docs://api",
          name: "API Documentation",
          description: "API documentation and examples",
          mimeType: "text/markdown",
        },
      ],
    }));

    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const { uri } = request.params;

      try {
        switch (uri) {
          case "config://current":
            return await this.readCurrentConfig();
          case "logs://audit":
            return await this.readAuditLogs();
          case "metrics://usage":
            return await this.readUsageMetrics();
          case "docs://api":
            return await this.readApiDocs();
          default:
            throw new McpError(
              ErrorCode.InvalidRequest,
              `Unknown resource: ${uri}`
            );
        }
      } catch (error) {
        if (error instanceof McpError) throw error;
        throw new McpError(
          ErrorCode.InternalError,
          `Failed to read resource: ${error}`
        );
      }
    });
  }

  private async handleProviderTest(args: ProviderTestArgs) {
    const { provider, prompt, model } = args;
    
    const testScript = `
      cd "${PROJECT_ROOT}" && \
      cargo run --bin securellm -- test ${provider} --prompt "${prompt.replace(/"/g, '\\"')}"${model ? ` --model ${model}` : ''}
    `;

    try {
      const { stdout, stderr } = await execAsync(testScript, {
        cwd: PROJECT_ROOT,
        timeout: 30000,
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              provider,
              model: model || "default",
              prompt,
              status: "success",
              output: stdout,
              stderr: stderr || null,
            }, null, 2),
          },
        ],
      };
    } catch (error: any) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              provider,
              status: "error",
              error: error.message,
              stderr: error.stderr,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  private async handleSecurityAudit(args: SecurityAuditArgs) {
    const { config_file } = args;
    const configPath = path.resolve(PROJECT_ROOT, config_file);

    try {
      const configContent = await fs.readFile(configPath, "utf-8");
      
      const issues: string[] = [];
      const warnings: string[] = [];
      const recommendations: string[] = [];

      // Check for hardcoded secrets
      if (configContent.match(/sk-[a-zA-Z0-9]{32,}/)) {
        issues.push("⚠️ CRITICAL: Hardcoded API keys detected in configuration");
      }

      // Check TLS configuration
      if (configContent.includes('enabled = false') && configContent.includes('[security.tls]')) {
        warnings.push("TLS is disabled - only use for development");
      }

      // Check rate limiting
      if (!configContent.includes('[security.rate_limit]')) {
        warnings.push("Rate limiting not configured");
      }

      // Check audit logging
      if (!configContent.includes('[security.audit]')) {
        recommendations.push("Consider enabling audit logging for production");
      }

      // Check for environment variable usage
      if (!configContent.includes('${') && configContent.includes('api_key')) {
        recommendations.push("Use environment variables for API keys instead of hardcoding");
      }

      const result = {
        config_file,
        status: issues.length > 0 ? "failed" : warnings.length > 0 ? "warning" : "passed",
        issues,
        warnings,
        recommendations,
        summary: `Found ${issues.length} critical issues, ${warnings.length} warnings, ${recommendations.length} recommendations`,
      };

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    } catch (error: any) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              error: error.message,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  private async handleRateLimitCheck(args: RateLimitCheckArgs) {
    const { provider } = args;

    // This is a mock implementation - in production, this would query actual rate limit state
    const rateLimits: Record<string, any> = {
      deepseek: {
        requests_per_minute: 60,
        burst_size: 10,
        current_usage: 0,
        reset_time: new Date(Date.now() + 60000).toISOString(),
      },
      openai: {
        requests_per_minute: 3500,
        burst_size: 100,
        current_usage: 0,
        reset_time: new Date(Date.now() + 60000).toISOString(),
      },
      anthropic: {
        requests_per_minute: 50,
        burst_size: 5,
        current_usage: 0,
        reset_time: new Date(Date.now() + 60000).toISOString(),
      },
      ollama: {
        requests_per_minute: -1, // unlimited
        burst_size: -1,
        current_usage: 0,
        reset_time: null,
      },
    };

    const result = {
      provider,
      ...rateLimits[provider],
      remaining: rateLimits[provider].requests_per_minute - rateLimits[provider].current_usage,
      status: "ok",
    };

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  private async handleBuildAndTest(args: BuildAndTestArgs) {
    const { test_type } = args;

    let testCommand = "";
    switch (test_type) {
      case "unit":
        testCommand = "cargo test --lib";
        break;
      case "integration":
        testCommand = "cargo test --test '*'";
        break;
      case "all":
        testCommand = "cargo test";
        break;
    }

    const buildScript = `
      cd "${PROJECT_ROOT}" && \
      cargo build && \
      ${testCommand}
    `;

    try {
      const { stdout, stderr } = await execAsync(buildScript, {
        cwd: PROJECT_ROOT,
        timeout: 120000,
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              test_type,
              status: "success",
              output: stdout,
              stderr: stderr || null,
            }, null, 2),
          },
        ],
      };
    } catch (error: any) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              test_type,
              status: "error",
              error: error.message,
              stderr: error.stderr,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  private async handleProviderConfigValidate(args: ProviderConfigValidateArgs) {
    const { provider, config_data } = args;

    const issues: string[] = [];
    const warnings: string[] = [];

    // Basic TOML validation
    if (!config_data.trim().startsWith("[providers.")) {
      issues.push("Configuration must start with [providers.PROVIDER_NAME]");
    }

    // Check required fields
    const requiredFields = ["enabled", "api_key", "base_url"];
    for (const field of requiredFields) {
      if (!config_data.includes(field)) {
        issues.push(`Missing required field: ${field}`);
      }
    }

    // Check for security issues
    if (config_data.match(/api_key\s*=\s*"sk-/)) {
      warnings.push("API key appears to be hardcoded - use environment variables");
    }

    const result = {
      provider,
      status: issues.length > 0 ? "invalid" : warnings.length > 0 ? "valid_with_warnings" : "valid",
      issues,
      warnings,
    };

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  private async handleCryptoKeyGenerate(args: CryptoKeyGenerateArgs) {
    const { key_type, output_path } = args;

    const outputDir = path.resolve(PROJECT_ROOT, output_path);
    
    try {
      await fs.mkdir(outputDir, { recursive: true });

      let certCommand = "";
      if (key_type === "server") {
        certCommand = `
          openssl req -x509 -newkey rsa:4096 -keyout "${outputDir}/server.key" \
            -out "${outputDir}/server.crt" -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Org/CN=securellm-server"
        `;
      } else {
        certCommand = `
          openssl req -x509 -newkey rsa:4096 -keyout "${outputDir}/client.key" \
            -out "${outputDir}/client.crt" -days 365 -nodes \
            -subj "/C=US/ST=State/L=City/O=Org/CN=securellm-client"
        `;
      }

      await execAsync(certCommand);

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              key_type,
              output_path: outputDir,
              files: {
                certificate: `${key_type}.crt`,
                private_key: `${key_type}.key`,
              },
              status: "success",
              message: `Generated ${key_type} TLS certificate and key`,
            }, null, 2),
          },
        ],
      };
    } catch (error: any) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              error: error.message,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  private async readCurrentConfig() {
    try {
      const configPath = path.resolve(PROJECT_ROOT, "config.toml");
      const content = await fs.readFile(configPath, "utf-8");

      return {
        contents: [
          {
            uri: "config://current",
            mimeType: "application/toml",
            text: content,
          },
        ],
      };
    } catch (error) {
      return {
        contents: [
          {
            uri: "config://current",
            mimeType: "text/plain",
            text: "Configuration file not found",
          },
        ],
      };
    }
  }

  private async readAuditLogs() {
    // Mock audit log data - in production this would read from actual log files
    const mockLogs = [
      {
        timestamp: new Date().toISOString(),
        request_id: "req_001",
        provider: "deepseek",
        model: "deepseek-chat",
        status: "success",
        duration_ms: 738,
        tokens: { prompt: 126, completion: 748 },
      },
    ];

    return {
      contents: [
        {
          uri: "logs://audit",
          mimeType: "application/json",
          text: JSON.stringify(mockLogs, null, 2),
        },
      ],
    };
  }

  private async readUsageMetrics() {
    // Mock usage metrics - in production this would aggregate real data
    const mockMetrics = {
      providers: {
        deepseek: { requests: 10, errors: 0, avg_latency_ms: 750 },
        openai: { requests: 0, errors: 0, avg_latency_ms: 0 },
        anthropic: { requests: 0, errors: 0, avg_latency_ms: 0 },
        ollama: { requests: 0, errors: 0, avg_latency_ms: 0 },
      },
      total_requests: 10,
      total_errors: 0,
      uptime_seconds: 3600,
    };

    return {
      contents: [
        {
          uri: "metrics://usage",
          mimeType: "application/json",
          text: JSON.stringify(mockMetrics, null, 2),
        },
      ],
    };
  }

  // ===== KNOWLEDGE MANAGEMENT HANDLERS =====

  private async handleCreateSession(args: any) {
    if (!this.db) {
      return {
        content: [{ type: "text", text: "Knowledge database not available" }],
        isError: true
      };
    }
    
    try {
      const session = await this.db.createSession(args as CreateSessionInput);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ session, message: "Session created successfully" }, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleSaveKnowledge(args: any) {
    if (!this.db) {
      return {
        content: [{ type: "text", text: "Knowledge database not available" }],
        isError: true
      };
    }
    
    try {
      const entry = await this.db.saveKnowledge(args as SaveKnowledgeInput);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ entry, message: "Knowledge saved successfully" }, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleSearchKnowledge(args: any) {
    if (!this.db) {
      return {
        content: [{ type: "text", text: "Knowledge database not available" }],
        isError: true
      };
    }
    
    try {
      const results = await this.db.searchKnowledge(args as SearchKnowledgeInput);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ results, count: results.length }, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleLoadSession(args: any) {
    if (!this.db) {
      return {
        content: [{ type: "text", text: "Knowledge database not available" }],
        isError: true
      };
    }
    
    try {
      const session = await this.db.getSession(args.session_id);
      if (!session) {
        return {
          content: [{ type: "text", text: "Session not found" }],
          isError: true
        };
      }
      
      const entries = await this.db.getRecentKnowledge(args.session_id, 100);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ session, entries, count: entries.length }, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleListSessions(args: any) {
    if (!this.db) {
      return {
        content: [{ type: "text", text: "Knowledge database not available" }],
        isError: true
      };
    }
    
    try {
      const sessions = await this.db.listSessions(args.limit || 20, args.offset || 0);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ sessions, count: sessions.length }, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleGetRecentKnowledge(args: any) {
    if (!this.db) {
      return {
        content: [{ type: "text", text: "Knowledge database not available" }],
        isError: true
      };
    }
    
    try {
      const entries = await this.db.getRecentKnowledge(args.session_id, args.limit || 20);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({ entries, count: entries.length }, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async readApiDocs() {
    const docs = `# SecureLLM Bridge API Documentation

## Provider Testing
Test provider connectivity with sample queries.

## Security Auditing
Run security checks on configuration files to identify potential issues.

## Rate Limiting
Check current rate limit status for each provider.

## Build & Test
Build the project and run test suites.

## Configuration Validation
Validate provider configuration format and completeness.

## TLS Key Generation
Generate server and client TLS certificates for secure communication.
`;

    return {
      contents: [
        {
          uri: "docs://api",
          mimeType: "text/markdown",
          text: docs,
        },
      ],
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("SecureLLM Bridge MCP server running on stdio");
  }
}

const server = new SecureLLMBridgeMCPServer();
server.run().catch(console.error);
