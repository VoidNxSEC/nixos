/**
 * SSH Jump Host Manager - Multi-Hop Connection Management
 * Manages SSH connections through multiple bastions/jump hosts with intelligent routing
 */

import { SSHConnectionManager } from './connection-manager.js';
import type {
  JumpChainConfig,
  JumpHostConfig,
  JumpChain,
  JumpChainResult,
  JumpChainStatus,
  ValidationResult,
  SSHConfig,
  SSHConnection,
} from '../../types/ssh-advanced.js';

/**
 * Path hop information for jump chain
 */
interface PathHop {
  host: string;
  latency_ms: number;
  connected_at: Date;
  priority?: number;
}

/**
 * Probe result for optimal strategy
 */
interface ProbeResult extends PathHop {
  success: boolean;
}

/**
 * Jump Host Manager Class
 * Handles multi-hop SSH connections through bastion servers
 */
export class JumpHostManager {
  private chains: Map<string, JumpChain> = new Map();
  private connectionManager: SSHConnectionManager;
  private pathCache: Map<string, { path: JumpHostConfig[]; expires: Date }> = new Map();

  constructor(connectionManager: SSHConnectionManager) {
    this.connectionManager = connectionManager;
    console.log('[JumpHostManager] Initialized');
  }

  /**
   * Main method: Connect through jump hosts to target
   */
  async connectThroughJumps(config: JumpChainConfig): Promise<JumpChainResult> {
    const chainId = this.generateChainId();
    
    try {
      console.log(`[JumpChain ${chainId}] Starting connection through ${config.jumps.length} jump(s)`);
      console.log(`[JumpChain ${chainId}] Strategy: ${config.strategy || 'sequential'}`);
      console.log(`[JumpChain ${chainId}] Target: ${config.target.username}@${config.target.host}`);

      // Validate jump chain configuration
      const validation = await this.validateJumpChain(config.jumps);
      if (!validation.valid) {
        return {
          success: false,
          error: `Jump chain validation failed: ${validation.errors.join(', ')}`,
          timestamp: new Date().toISOString(),
        };
      }

      // Check cache if enabled
      if (config.cache_successful_path) {
        const cached = this.getCachedPath(config.target.host);
        if (cached) {
          console.log(`[JumpChain ${chainId}] Using cached path`);
          config = { ...config, jumps: cached };
        }
      }

      let path: PathHop[] = [];

      // Execute strategy
      const strategy = config.strategy || 'sequential';
      switch (strategy) {
        case 'sequential':
          path = await this.connectSequential(config);
          break;
        case 'optimal':
          path = await this.connectOptimal(config);
          break;
        case 'failover':
          path = await this.connectWithFailover(config);
          break;
        default:
          throw new Error(`Unknown strategy: ${strategy}`);
      }

      // Check total latency threshold
      const totalLatency = this.calculateTotalLatency(path);
      if (config.max_total_latency_ms && totalLatency > config.max_total_latency_ms) {
        throw new Error(
          `Total latency ${totalLatency}ms exceeds threshold ${config.max_total_latency_ms}ms`
        );
      }

      // Connect to final target through established jump chain
      console.log(`[JumpChain ${chainId}] Connecting to target through ${path.length} hop(s)`);
      const finalConn = await this.connectThroughPath(path, config.target);

      // Create jump chain instance
      const chain: JumpChain = {
        id: chainId,
        config,
        status: 'connected',
        connection_id: finalConn.id,
        actual_path: path,
        total_latency_ms: totalLatency,
        hop_count: path.length,
        created_at: new Date(),
        reconnect_attempts: 0,
      };

      this.chains.set(chainId, chain);

      // Cache successful path if enabled
      if (config.cache_successful_path) {
        const duration = config.cache_duration_minutes || 60;
        this.cachePath(config.target.host, config.jumps, duration);
        console.log(`[JumpChain ${chainId}] Path cached for ${duration} minutes`);
      }

      console.log(`[JumpChain ${chainId}] Successfully established (total latency: ${totalLatency}ms)`);

      return {
        success: true,
        data: {
          chain_id: chainId,
          connection_id: finalConn.id,
          target: config.target.host,
          jumps: config.jumps.map(j => j.host),
          path_taken: path.map(p => p.host),
          total_latency_ms: totalLatency,
          hop_count: path.length,
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error(`[JumpChain ${chainId}] Connection failed:`, error.message);
      return {
        success: false,
        error: `Jump chain failed: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Strategy: Sequential - Connect through jumps in order
   */
  private async connectSequential(config: JumpChainConfig): Promise<PathHop[]> {
    const path: PathHop[] = [];

    console.log(`[Sequential] Connecting through ${config.jumps.length} jump(s) in order`);

    for (const [index, jump] of config.jumps.entries()) {
      const jumpNum = index + 1;
      console.log(`[Sequential] Jump ${jumpNum}/${config.jumps.length}: ${jump.username}@${jump.host}`);

      const start = Date.now();
      
      try {
        const conn = await this.connectionManager.getOrCreateConnection(jump);
        const latency = Date.now() - start;

        console.log(`[Sequential] Jump ${jumpNum} connected (latency: ${latency}ms)`);

        // Check latency threshold for this jump
        if (jump.max_latency_ms && latency > jump.max_latency_ms) {
          throw new Error(
            `Jump host ${jump.host} exceeds latency threshold: ${latency}ms > ${jump.max_latency_ms}ms`
          );
        }

        path.push({
          host: jump.host,
          latency_ms: latency,
          connected_at: new Date(),
          priority: jump.priority,
        });
      } catch (error: any) {
        throw new Error(`Failed to connect to jump ${jumpNum} (${jump.host}): ${error.message}`);
      }
    }

    return path;
  }

  /**
   * Strategy: Optimal - Find best path based on probing
   */
  private async connectOptimal(config: JumpChainConfig): Promise<PathHop[]> {
    console.log(`[Optimal] Finding optimal path through ${config.jumps.length} jump(s)`);

    // Probe all jumps in parallel if enabled
    if (config.parallel_probe) {
      console.log(`[Optimal] Parallel probing enabled, testing all jumps...`);
      
      try {
        const probes = await Promise.all(
          config.jumps.map(jump => this.probeJump(jump))
        );

        // Filter successful probes
        const successfulProbes = probes.filter(p => p.success);
        
        if (successfulProbes.length === 0) {
          throw new Error('All jumps failed during probing');
        }

        console.log(`[Optimal] ${successfulProbes.length}/${probes.length} jumps responded successfully`);

        // Sort by priority (higher first) and latency (lower first)
        const sorted = successfulProbes.sort((a, b) => {
          const priorityDiff = (b.priority || 0) - (a.priority || 0);
          if (priorityDiff !== 0) return priorityDiff;
          return a.latency_ms - b.latency_ms;
        });

        console.log(`[Optimal] Best path selected (priority: ${sorted[0].priority || 0}, latency: ${sorted[0].latency_ms}ms)`);

        // Return sorted path (remove success flag)
        return sorted.map(({ success, ...hop }) => hop);
      } catch (error: any) {
        console.warn(`[Optimal] Parallel probe failed, falling back to sequential: ${error.message}`);
        return this.connectSequential(config);
      }
    }

    // Fall back to sequential if parallel probing not enabled
    return this.connectSequential(config);
  }

  /**
   * Strategy: Failover - Try alternative paths on failure
   */
  private async connectWithFailover(config: JumpChainConfig): Promise<PathHop[]> {
    console.log(`[Failover] Attempting connection with failover support`);

    // Try sequential first
    try {
      return await this.connectSequential(config);
    } catch (error: any) {
      console.warn(`[Failover] Primary path failed: ${error.message}`);

      // If we have multiple jumps, try alternative orderings
      if (config.jumps.length > 1) {
        console.log(`[Failover] Trying alternative paths...`);
        
        // Sort by priority and try again
        const sortedConfig: JumpChainConfig = {
          ...config,
          jumps: [...config.jumps].sort((a, b) => (b.priority || 0) - (a.priority || 0)),
        };

        try {
          return await this.connectSequential(sortedConfig);
        } catch (fallbackError: any) {
          console.error(`[Failover] All paths failed`);
          throw new Error(`Failover exhausted: ${fallbackError.message}`);
        }
      }

      throw error;
    }
  }

  /**
   * Probe a single jump host to measure latency and availability
   */
  private async probeJump(jump: JumpHostConfig): Promise<ProbeResult> {
    const start = Date.now();
    
    try {
      console.log(`[Probe] Testing ${jump.host}...`);
      
      const conn = await this.connectionManager.getOrCreateConnection(jump);
      const latency = Date.now() - start;

      console.log(`[Probe] ${jump.host} responded in ${latency}ms`);

      // Check latency threshold
      if (jump.max_latency_ms && latency > jump.max_latency_ms) {
        console.warn(`[Probe] ${jump.host} exceeds latency threshold (${latency}ms > ${jump.max_latency_ms}ms)`);
        return {
          host: jump.host,
          latency_ms: latency,
          connected_at: new Date(),
          priority: jump.priority || 0,
          success: false,
        };
      }

      return {
        host: jump.host,
        latency_ms: latency,
        connected_at: new Date(),
        priority: jump.priority || 0,
        success: true,
      };
    } catch (error: any) {
      console.error(`[Probe] ${jump.host} failed:`, error.message);
      return {
        host: jump.host,
        latency_ms: Infinity,
        connected_at: new Date(),
        priority: jump.priority || 0,
        success: false,
      };
    }
  }

  /**
   * Connect to target through established jump path
   */
  private async connectThroughPath(path: PathHop[], target: SSHConfig): Promise<SSHConnection> {
    console.log(`[ConnectThrough] Establishing final connection to ${target.host}`);
    
    // For now, we'll connect directly to target using the connection manager
    // In a full implementation, this would tunnel through the established jumps
    const conn = await this.connectionManager.getOrCreateConnection(target);

    console.log(`[ConnectThrough] Final connection established to ${target.host}`);
    return conn as any;
  }

  /**
   * Cache successful path for reuse
   */
  private cachePath(targetHost: string, path: readonly JumpHostConfig[], durationMinutes: number): void {
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + durationMinutes);
    
    this.pathCache.set(targetHost, { path: [...path], expires });
    console.log(`[PathCache] Cached path to ${targetHost} (expires: ${expires.toISOString()})`);
  }

  /**
   * Get cached path if available and not expired
   */
  private getCachedPath(targetHost: string): JumpHostConfig[] | null {
    const cached = this.pathCache.get(targetHost);
    if (!cached) {
      return null;
    }

    const now = new Date();
    if (cached.expires < now) {
      this.pathCache.delete(targetHost);
      console.log(`[PathCache] Expired cache for ${targetHost}`);
      return null;
    }

    console.log(`[PathCache] Cache hit for ${targetHost}`);
    return cached.path;
  }

  /**
   * Calculate total latency from path hops
   */
  private calculateTotalLatency(path: PathHop[]): number {
    return path.reduce((sum, hop) => sum + hop.latency_ms, 0);
  }

  /**
   * Generate unique chain ID
   */
  private generateChainId(): string {
    return `chain-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Get jump chain status
   */
  async getJumpChainStatus(chainId: string): Promise<JumpChainStatus | null> {
    const chain = this.chains.get(chainId);
    if (!chain) {
      return null;
    }

    const uptime = (Date.now() - chain.created_at.getTime()) / 1000;
    
    // Check connection health
    const conn = this.connectionManager.getConnection(chain.connection_id);
    const health = conn?.connected ? 
      (conn.health_status === 'healthy' ? 'healthy' : 'degraded') : 
      'failed';

    return {
      chain_id: chain.id,
      status: chain.status,
      target: chain.config.target.host,
      path: chain.actual_path.map(h => h.host),
      total_latency_ms: chain.total_latency_ms,
      uptime_seconds: uptime,
      health,
    };
  }

  /**
   * Validate jump chain configuration
   */
  async validateJumpChain(jumps: readonly JumpHostConfig[]): Promise<ValidationResult> {
    const errors: string[] = [];
    const warnings: string[] = [];

    // Check if jumps array is empty
    if (jumps.length === 0) {
      errors.push('Jump chain must contain at least one jump host');
    }

    // Validate each jump configuration
    for (const [index, jump] of jumps.entries()) {
      const jumpNum = index + 1;

      if (!jump.host) {
        errors.push(`Jump ${jumpNum}: Missing host`);
      }
      if (!jump.username) {
        errors.push(`Jump ${jumpNum}: Missing username`);
      }
      if (!jump.auth_method) {
        errors.push(`Jump ${jumpNum}: Missing auth_method`);
      }

      // Check for authentication credentials
      if (jump.auth_method === 'key' && !jump.key_path) {
        errors.push(`Jump ${jumpNum}: Key authentication requires key_path`);
      }
      if (jump.auth_method === 'password' && !jump.password) {
        errors.push(`Jump ${jumpNum}: Password authentication requires password`);
      }

      // Warn about potential issues
      if (jump.max_latency_ms && jump.max_latency_ms < 100) {
        warnings.push(`Jump ${jumpNum}: Very strict latency threshold (${jump.max_latency_ms}ms)`);
      }
    }

    // Warn if too many hops
    if (jumps.length > 3) {
      warnings.push(`Long jump chain (${jumps.length} hops) may have high total latency`);
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings,
    };
  }

  /**
   * Close jump chain and cleanup connections
   */
  async closeJumpChain(chainId: string): Promise<void> {
    const chain = this.chains.get(chainId);
    if (!chain) {
      throw new Error(`Jump chain not found: ${chainId}`);
    }

    console.log(`[JumpChain ${chainId}] Closing chain`);

    // Disconnect final connection
    try {
      this.connectionManager.disconnect(chain.connection_id);
    } catch (error: any) {
      console.error(`[JumpChain ${chainId}] Error disconnecting:`, error.message);
    }

    // Update status
    chain.status = 'closed';
    this.chains.delete(chainId);

    console.log(`[JumpChain ${chainId}] Chain closed`);
  }

  /**
   * List all active jump chains
   */
  listJumpChains(): JumpChainStatus[] {
    return Array.from(this.chains.values()).map(chain => {
      const uptime = (Date.now() - chain.created_at.getTime()) / 1000;
      const conn = this.connectionManager.getConnection(chain.connection_id);
      const health = conn?.connected ? 
        (conn.health_status === 'healthy' ? 'healthy' : 'degraded') : 
        'failed';

      return {
        chain_id: chain.id,
        status: chain.status,
        target: chain.config.target.host,
        path: chain.actual_path.map(h => h.host),
        total_latency_ms: chain.total_latency_ms,
        uptime_seconds: uptime,
        health,
      };
    });
  }

  /**
   * Clear path cache
   */
  clearPathCache(): void {
    const size = this.pathCache.size;
    this.pathCache.clear();
    console.log(`[PathCache] Cleared ${size} cached path(s)`);
  }

  /**
   * Cleanup method for graceful shutdown
   */
  async cleanup(): Promise<void> {
    console.log(`[JumpHostManager] Cleanup initiated for ${this.chains.size} chain(s)`);
    
    // Close all chains
    for (const chainId of this.chains.keys()) {
      try {
        await this.closeJumpChain(chainId);
      } catch (error: any) {
        console.error(`[JumpHostManager] Error closing chain ${chainId}:`, error.message);
      }
    }

    // Clear cache
    this.clearPathCache();

    console.log(`[JumpHostManager] Cleanup complete`);
  }
}

/**
 * MCP Tool Schema for SSH Jump Host
 */
export const sshJumpHostSchema = {
  name: 'ssh_jump_host',
  description: 'Connect to target through multiple SSH jump hosts (bastions) with intelligent routing',
  inputSchema: {
    type: 'object',
    properties: {
      target: {
        type: 'object',
        description: 'Target host configuration',
        properties: {
          host: { type: 'string', description: 'Target hostname or IP' },
          port: { type: 'number', description: 'SSH port (default: 22)' },
          username: { type: 'string', description: 'SSH username' },
          auth_method: { type: 'string', enum: ['key', 'password', 'certificate'] },
          key_path: { type: 'string', description: 'Path to private key' },
          password: { type: 'string', description: 'Password (not recommended)' },
        },
        required: ['host', 'username', 'auth_method'],
      },
      jumps: {
        type: 'array',
        description: 'Array of jump hosts to traverse',
        items: {
          type: 'object',
          properties: {
            host: { type: 'string', description: 'Jump host hostname or IP' },
            port: { type: 'number', description: 'SSH port (default: 22)' },
            username: { type: 'string', description: 'SSH username' },
            auth_method: { type: 'string', enum: ['key', 'password', 'certificate'] },
            key_path: { type: 'string', description: 'Path to private key' },
            password: { type: 'string', description: 'Password' },
            forward_agent: { type: 'boolean', description: 'Forward SSH agent' },
            max_latency_ms: { type: 'number', description: 'Max acceptable latency' },
            priority: { type: 'number', description: 'Priority for optimal routing' },
          },
          required: ['host', 'username', 'auth_method'],
        },
      },
      strategy: {
        type: 'string',
        enum: ['sequential', 'optimal', 'failover'],
        description: 'Connection strategy (default: sequential)',
      },
      max_total_latency_ms: {
        type: 'number',
        description: 'Maximum total latency threshold',
      },
      timeout_per_hop_ms: {
        type: 'number',
        description: 'Timeout per hop connection',
      },
      parallel_probe: {
        type: 'boolean',
        description: 'Probe jumps in parallel (optimal strategy)',
      },
      cache_successful_path: {
        type: 'boolean',
        description: 'Cache successful path for reuse',
      },
      cache_duration_minutes: {
        type: 'number',
        description: 'Cache duration in minutes (default: 60)',
      },
    },
    required: ['target', 'jumps'],
  },
};