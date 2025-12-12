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
import { GuideManager } from "./resources/guides.js";
import * as path from "path";
import { SmartRateLimiter } from "./middleware/rate-limiter.js";
import { RATE_LIMIT_CONFIGS } from "./config/index.js";
import { PackageDiagnoseTool, packageDiagnoseSchema } from "./tools/package-diagnose.js";
import { PackageDownloadTool, packageDownloadSchema } from "./tools/package-download.js";
import { PackageConfigureTool, packageConfigureSchema } from "./tools/package-configure.js";
import { detectProjectRoot } from "./utils/project-detection.js";
import { detectNixOSHost } from "./utils/host-detection.js";
import {
  emergencyTools,
  handleEmergencyStatus,
  handleEmergencyAbort,
  handleEmergencyCooldown,
  handleEmergencyNuke,
  handleEmergencySwap,
  handleSystemHealthCheck,
  handleSafeRebuildCheck,
} from "./tools/emergency/index.js";
import {
  laptopDefenseTools,
  handleThermalCheck,
  handleRebuildSafetyCheck,
  handleThermalForensics,
  handleThermalWarroom,
  handleLaptopVerdict,
  handleFullInvestigation,
  handleForceCooldown,
  handleResetPerformance,
} from "./tools/laptop-defense/index.js";
import {
  webSearchTools,
  handleWebSearch,
  handleNixSearch,
  handleGithubSearch,
  handleTechNewsSearch,
  handleDiscourseSearch,
  handleStackOverflowSearch,
} from "./tools/web-search.js";
import {
  researchAgentTool,
  handleResearchAgent,
} from "./tools/research-agent.js";

const execAsync = promisify(exec);

// Legacy constants for backward compatibility - will be overridden by auto-detection
const PROJECT_ROOT = process.env.PROJECT_ROOT || process.cwd();
const KNOWLEDGE_DB_PATH = process.env.KNOWLEDGE_DB_PATH ||
  path.join(process.env.HOME || process.env.USERPROFILE || ".", ".local/share/securellm/knowledge.db");
const ENABLE_KNOWLEDGE = process.env.ENABLE_KNOWLEDGE !== 'false';

// Provider API keys from environment (loaded from SOPS-decrypted secrets)
const API_KEYS = {
  anthropic: process.env.ANTHROPIC_API_KEY || "",
  openai: process.env.OPENAI_API_KEY || "",
  deepseek: process.env.DEEPSEEK_API_KEY || "",
  gemini: process.env.GEMINI_API_KEY || "",
  openrouter: process.env.OPENROUTER_API_KEY || "",
  groq: process.env.GROQ_API_KEY || "",
  mistral: process.env.MISTRAL_API_KEY || "",
  nvidia: process.env.NVIDIA_API_KEY || "",
  replicate: process.env.REPLICATE_API_TOKEN || "",
};

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
  private guideManager: GuideManager;
  private rateLimiter: SmartRateLimiter;
  private packageDiagnose!: PackageDiagnoseTool;
  private packageDownload!: PackageDownloadTool;
  private packageConfigure!: PackageConfigureTool;
  private projectRoot: string = PROJECT_ROOT;
  private hostname: string = "default";

  constructor() {
    // Initialize smart rate limiter for API protection
    // Convert Record to Map for SmartRateLimiter
    const configMap = new Map(Object.entries(RATE_LIMIT_CONFIGS));
    this.rateLimiter = new SmartRateLimiter(configMap);
    this.guideManager = new GuideManager();

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

    this.server.onerror = (error) => console.error("[MCP Error]", error);
    process.on("SIGINT", async () => {
      if (this.db) {
        this.db.close();
      }
      await this.server.close();
      process.exit(0);
    });
  }

  /**
   * Initialize async resources (PROJECT_ROOT, hostname, knowledge DB)
   * Must be called before starting the server
   */
  async initialize(): Promise<void> {
    try {
      // Detect project root
      const rootDetection = await detectProjectRoot();
      this.projectRoot = rootDetection.projectRoot;
      console.error(
        `[MCP] Project root detected: ${this.projectRoot} (method: ${rootDetection.method}${rootDetection.flakeFound ? ", flake.nix found" : ""
        })`
      );

      // Log available API keys (masked)
      const availableKeys = Object.entries(API_KEYS)
        .filter(([_, key]) => key.length > 0)
        .map(([name, key]) => `${name}(${key.substring(0, 8)}...)`);
      if (availableKeys.length > 0) {
        console.error(`[MCP] Available API keys: ${availableKeys.join(", ")}`);
      } else {
        console.error(`[MCP] Warning: No API keys loaded. Provider tools will fail.`);
      }

      // Detect NixOS hostname
      if (rootDetection.flakeFound) {
        try {
          const hostDetection = await detectNixOSHost(this.projectRoot);
          this.hostname = hostDetection.hostname;
          if (hostDetection.warnings.length > 0) {
            console.warn("Host detection warnings:");
            hostDetection.warnings.forEach((w) => console.warn(`  ${w}`));
          }
        } catch (error) {
          console.warn(
            `Failed to detect NixOS host: ${error}. Using default hostname.`
          );
          this.hostname = "default";
        }
      } else {
        console.warn(
          "No flake.nix found. Using default hostname. Package tools may not work correctly."
        );
        this.hostname = "default";
      }

      // Initialize package tools with detected values
      this.packageDiagnose = new PackageDiagnoseTool(
        this.projectRoot,
        this.hostname
      );
      this.packageDownload = new PackageDownloadTool(this.projectRoot);
      this.packageConfigure = new PackageConfigureTool(this.projectRoot);

      // Initialize knowledge database if enabled
      if (ENABLE_KNOWLEDGE) {
        this.initKnowledge();
      }

      console.error("MCP Server initialization complete.");
    } catch (error) {
      console.error("Failed to initialize MCP server:", error);
      throw error;
    }
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
          description: "Test LLM provider connectivity",
          defer_loading: true,
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
          description: "Audit project configuration security",
          defer_loading: true,
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
          description: "Check provider rate limit status",
          defer_loading: true,
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
          description: "Build project and run tests",
          defer_loading: true,
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
          description: "Validate provider config format",
          defer_loading: true,
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
          description: "Generate TLS certificates and keys",
          defer_loading: true,
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
        {
          name: "rate_limiter_status",
          description: "Get rate limiter status for all providers",
          defer_loading: true,
          allowed_callers: ["code_execution_20250825"],
          inputSchema: {
            type: "object",
            properties: {},
          },
        },
        {
          name: "package_diagnose",
          description: "Diagnose package configuration issues",
          defer_loading: true,
          inputSchema: {
            type: "object",
            properties: {
              package_path: {
                type: "string",
                description: "Path to the package .nix file",
              },
              package_type: {
                type: "string",
                enum: ["tar", "deb", "js"],
                description: "Type of package system",
              },
              build_test: {
                type: "boolean",
                description: "Whether to perform a test build",
                default: true,
              },
            },
            required: ["package_path", "package_type"],
          },
        },
        {
          name: "package_download",
          description: "Download package from GitHub/npm/URL with automatic hash calculation",
          defer_loading: true,
          inputSchema: {
            type: "object",
            properties: {
              package_name: {
                type: "string",
                description: "Name of the package",
              },
              package_type: {
                type: "string",
                enum: ["tar", "deb", "js"],
                description: "Type of package system",
              },
              source: {
                type: "object",
                properties: {
                  type: {
                    type: "string",
                    enum: ["github_release", "npm", "url"],
                    description: "Source type",
                  },
                  url: {
                    type: "string",
                    description: "Direct URL (for type: url)",
                  },
                  github: {
                    type: "object",
                    properties: {
                      repo: { type: "string" },
                      tag: { type: "string" },
                      asset_pattern: { type: "string" },
                    },
                    required: ["repo"],
                  },
                  npm: {
                    type: "object",
                    properties: {
                      package: { type: "string" },
                      version: { type: "string" },
                    },
                    required: ["package"],
                  },
                },
                required: ["type"],
              },
            },
            required: ["package_name", "package_type", "source"],
          },
        },
        {
          name: "package_configure",
          description: "Generate Nix package configuration from downloaded file",
          defer_loading: true,
          inputSchema: {
            type: "object",
            properties: {
              package_name: {
                type: "string",
                description: "Name of the package",
              },
              package_type: {
                type: "string",
                enum: ["tar", "deb", "js"],
                description: "Type of package system",
              },
              storage_file: {
                type: "string",
                description: "Path to downloaded file in storage",
              },
              sha256: {
                type: "string",
                description: "SHA256 hash of the file",
              },
              options: {
                type: "object",
                properties: {
                  method: {
                    type: "string",
                    enum: ["auto", "native", "fhs"],
                  },
                  sandbox: { type: "boolean" },
                  audit: { type: "boolean" },
                  executable: { type: "string" },
                  npm_flags: {
                    type: "array",
                    items: { type: "string" },
                  },
                },
              },
            },
            required: ["package_name", "package_type", "storage_file", "sha256"],
          },
        },
        // Add knowledge tools if enabled
        ...(ENABLE_KNOWLEDGE && this.db ? knowledgeTools : []),
        // Add Emergency Framework tools
        ...emergencyTools,
        // Add Laptop Defense Framework tools
        ...laptopDefenseTools,
        // Add Web Search tools
        ...webSearchTools,
        // Add Research Agent tool
        researchAgentTool,
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
          case "rate_limiter_status":
            return await this.handleRateLimiterStatus();
          case "package_diagnose":
            return await this.handlePackageDiagnose(args);
          case "package_download":
            return await this.handlePackageDownload(args);
          case "package_configure":
            return await this.handlePackageConfigure(args);
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

          // Emergency Framework handlers
          case "emergency_status":
            return await this.handleEmergencyStatus();
          case "emergency_abort":
            return await this.handleEmergencyAbort(args);
          case "emergency_cooldown":
            return await this.handleEmergencyCooldown();
          case "emergency_nuke":
            return await this.handleEmergencyNuke(args);
          case "emergency_swap":
            return await this.handleEmergencySwap();
          case "system_health_check":
            return await this.handleSystemHealthCheck(args);
          case "safe_rebuild_check":
            return await this.handleSafeRebuildCheck();

          // Laptop Defense handlers
          case "thermal_check":
            return await this.handleThermalCheck(args);
          case "rebuild_safety_check":
            return await this.handleRebuildSafetyCheck();
          case "thermal_forensics":
            return await this.handleThermalForensics(args);
          case "thermal_warroom":
            return await this.handleThermalWarroom(args);
          case "laptop_verdict":
            return await this.handleLaptopVerdict(args);
          case "full_investigation":
            return await this.handleFullInvestigation();
          case "force_cooldown":
            return await this.handleForceCooldown();
          case "reset_performance":
            return await this.handleResetPerformance();

          // Web Search handlers
          case "web_search":
            return await this.handleWebSearch(args);
          case "nix_search":
            return await this.handleNixSearch(args);
          case "github_search":
            return await this.handleGithubSearch(args);
          case "tech_news_search":
            return await this.handleTechNewsSearch(args);
          case "nixos_discourse_search":
            return await this.handleDiscourseSearch(args);
          case "stackoverflow_search":
            return await this.handleStackOverflowSearch(args);

          // Research Agent handler
          case "research_agent":
            return await handleResearchAgent(args as any);

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
        // Handle guide/skill/prompt resources
        if (uri.startsWith('guide://')) {
          const name = uri.replace('guide://', '');
          const content = await this.guideManager.loadGuide(name);
          return {
            contents: [{
              uri,
              mimeType: "text/markdown",
              text: content,
            }],
          };
        }

        if (uri.startsWith('skill://')) {
          const name = uri.replace('skill://', '');
          const content = await this.guideManager.loadSkill(name);
          return {
            contents: [{
              uri,
              mimeType: "text/markdown",
              text: content,
            }],
          };
        }

        if (uri.startsWith('prompt://')) {
          const name = uri.replace('prompt://', '');
          const content = await this.guideManager.loadPrompt(name);
          return {
            contents: [{
              uri,
              mimeType: "text/markdown",
              text: content,
            }],
          };
        }

        // Handle existing resources
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

    try {
      // Wrap API call with rate limiter
      const result = await this.rateLimiter.execute(provider, async () => {
        const testScript = `
          cd "${PROJECT_ROOT}" && \
          cargo run --bin securellm -- test ${provider} --prompt "${prompt.replace(/"/g, '\\"')}"${model ? ` --model ${model}` : ''}
        `;

        const { stdout, stderr } = await execAsync(testScript, {
          cwd: PROJECT_ROOT,
          timeout: 30000,
        });

        return { stdout, stderr, success: true };
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
              output: result.stdout,
              stderr: result.stderr || null,
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
              errorType: error.constructor.name,
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

    try {
      // Wrap build operations with rate limiter to prevent spam
      const result = await this.rateLimiter.execute('build', async () => {
        const buildScript = `
          cd "${PROJECT_ROOT}" && \
          cargo build && \
          ${testCommand}
        `;

        const { stdout, stderr } = await execAsync(buildScript, {
          cwd: PROJECT_ROOT,
          timeout: 120000,
        });

        return { stdout, stderr, success: true };
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              test_type,
              status: "success",
              output: result.stdout,
              stderr: result.stderr || null,
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
              errorType: error.constructor.name,
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
      // Wrap crypto operations with rate limiter (expensive operations)
      const result = await this.rateLimiter.execute('crypto', async () => {
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
        return { success: true };
      });

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
              errorType: error.constructor.name,
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

  private async handleRateLimiterStatus() {
    try {
      const allMetrics = this.rateLimiter.getAllMetrics();
      const status: Record<string, any> = {};

      for (const [provider, metrics] of allMetrics.entries()) {
        const queueStatus = this.rateLimiter.getQueueStatus(provider);
        status[provider] = {
          performance: {
            totalRequests: metrics.totalRequests,
            successRate: metrics.totalRequests > 0
              ? `${((metrics.successfulRequests / metrics.totalRequests) * 100).toFixed(2)}%`
              : '0%',
            requestsPerMinute: metrics.requestsPerMinute.toFixed(1),
            retriedRequests: metrics.retriedRequests,
            averageRetries: metrics.retriedRequests > 0
              ? (metrics.totalRetries / metrics.retriedRequests).toFixed(1)
              : '0',
          },
          latency: {
            average: `${metrics.averageLatency.toFixed(0)}ms`,
            p50: `${metrics.latencyPercentiles.p50}ms`,
            p95: `${metrics.latencyPercentiles.p95}ms`,
            p99: `${metrics.latencyPercentiles.p99}ms`,
            max: `${metrics.latencyPercentiles.max}ms`,
          },
          errors: {
            total: metrics.failedRequests,
            byCategory: metrics.errorsByCategory,
            circuitBreakerTrips: metrics.circuitBreakerActivations,
          },
          queue: {
            current: queueStatus || { queueLength: 0, processing: false },
            averageLength: metrics.queueMetrics.averageQueueLength.toFixed(1),
            maxLength: metrics.queueMetrics.maxQueueLength,
            averageWaitTime: metrics.totalRequests > 0
              ? `${(metrics.queueMetrics.totalTimeInQueue / metrics.totalRequests).toFixed(0)}ms`
              : '0ms',
          },
          timeWindow: {
            duration: `${(metrics.timeWindow.durationMs / 1000).toFixed(0)}s`,
            since: new Date(metrics.timeWindow.startTime).toISOString(),
          },
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              success: true,
              timestamp: new Date().toISOString(),
              providers: status,
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
              success: false,
              error: error.message,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  // ===== PACKAGE DEBUGGER HANDLERS =====

  private async handlePackageDiagnose(args: any) {
    try {
      const result = await this.packageDiagnose.diagnose(args);

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
              success: false,
              error: error.message,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  private async handlePackageDownload(args: any) {
    try {
      const result = await this.packageDownload.download(args);

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
              success: false,
              error: error.message,
            }, null, 2),
          },
        ],
        isError: true,
      };
    }
  }

  private async handlePackageConfigure(args: any) {
    try {
      const result = await this.packageConfigure.configure(args);

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
              success: false,
              error: error.message,
            }, null, 2),
          },
        ],
        isError: true,
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

  // ===== EMERGENCY FRAMEWORK HANDLERS =====

  private async handleEmergencyStatus() {
    try {
      const result = await handleEmergencyStatus();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleEmergencyAbort(args: any) {
    try {
      const result = await handleEmergencyAbort(args.force || false);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleEmergencyCooldown() {
    try {
      const result = await handleEmergencyCooldown();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleEmergencyNuke(args: any) {
    try {
      const result = await handleEmergencyNuke(args.confirm || false);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleEmergencySwap() {
    try {
      const result = await handleEmergencySwap();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleSystemHealthCheck(args: any) {
    try {
      const result = await handleSystemHealthCheck(args.detailed || false);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleSafeRebuildCheck() {
    try {
      const result = await handleSafeRebuildCheck();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  // ===== LAPTOP DEFENSE HANDLERS =====

  private async handleThermalCheck(args: any) {
    try {
      const result = await handleThermalCheck(args.max_temp || 75);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleRebuildSafetyCheck() {
    try {
      const result = await handleRebuildSafetyCheck();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleThermalForensics(args: any) {
    try {
      const result = await handleThermalForensics(args.duration || 180, args.skip_rebuild || false);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleThermalWarroom(args: any) {
    try {
      const result = await handleThermalWarroom(args.duration || 60);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleLaptopVerdict(args: any) {
    try {
      const result = await handleLaptopVerdict(args.evidence_dir);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleFullInvestigation() {
    try {
      const result = await handleFullInvestigation();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleForceCooldown() {
    try {
      const result = await handleForceCooldown();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleResetPerformance() {
    try {
      const result = await handleResetPerformance();
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  // ===== WEB SEARCH HANDLERS =====

  private async handleWebSearch(args: any) {
    try {
      const result = await handleWebSearch(args);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleNixSearch(args: any) {
    try {
      const result = await handleNixSearch(args);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleGithubSearch(args: any) {
    try {
      const result = await handleGithubSearch(args);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleTechNewsSearch(args: any) {
    try {
      const result = await handleTechNewsSearch(args);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleDiscourseSearch(args: any) {
    try {
      const result = await handleDiscourseSearch(args);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  private async handleStackOverflowSearch(args: any) {
    try {
      const result = await handleStackOverflowSearch(args);
      return {
        content: [{
          type: "text",
          text: JSON.stringify(result, null, 2)
        }]
      };
    } catch (error: any) {
      return {
        content: [{ type: "text", text: JSON.stringify({ error: error.message }, null, 2) }],
        isError: true
      };
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("SecureLLM Bridge MCP server running on stdio");
  }
}

// Main entry point
async function main() {
  const server = new SecureLLMBridgeMCPServer();

  try {
    // Initialize async resources (project root, hostname, knowledge DB)
    await server.initialize();

    // Start MCP server
    await server.run();
  } catch (error) {
    console.error("Failed to start MCP server:", error);
    process.exit(1);
  }
}

main();
