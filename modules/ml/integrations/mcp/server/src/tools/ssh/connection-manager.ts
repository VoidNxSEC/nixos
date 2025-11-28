/**
 * SSH Connection Manager - Enhanced with Pooling and Health Monitoring
 * Manages SSH connections with security controls, connection pooling, and health checks
 */

// @ts-ignore - ssh2 types are in @types/ssh2
import { Client } from 'ssh2';
import * as fs from 'fs/promises';
import type { SSHConnectArgs, SSHConnectionResult } from '../../types/extended-tools.js';
import type {
  SSHConfig,
  SSHConnection,
  ConnectionPoolConfig,
  ConnectionHealthStatus,
  PoolStatus,
  PoolStatistics,
} from '../../types/ssh-advanced.js';

export class SSHConnectionManager {
  private pool: Map<string, SSHConnection> = new Map();
  private allowedHosts: string[];
  private config: ConnectionPoolConfig;
  private healthCheckInterval?: NodeJS.Timeout;
  private connectionMetrics: {
    totalConnections: number;
    totalBytesTransferred: number;
    totalCommands: number;
    totalErrors: number;
    connectionTimes: number[];
    latencies: number[];
  };

  constructor(
    allowedHosts: string[] = ['localhost', '127.0.0.1'],
    poolConfig?: ConnectionPoolConfig
  ) {
    this.allowedHosts = allowedHosts;
    this.config = {
      max_connections: poolConfig?.max_connections || 10,
      max_idle_time_ms: poolConfig?.max_idle_time_ms || 300000, // 5 minutes
      max_connection_age_ms: poolConfig?.max_connection_age_ms || 3600000, // 1 hour
      health_check_interval_ms: poolConfig?.health_check_interval_ms || 60000, // 1 minute
      health_check_timeout_ms: poolConfig?.health_check_timeout_ms || 5000,
      max_memory_mb: poolConfig?.max_memory_mb,
      max_bandwidth_mbps: poolConfig?.max_bandwidth_mbps,
    };

    this.connectionMetrics = {
      totalConnections: 0,
      totalBytesTransferred: 0,
      totalCommands: 0,
      totalErrors: 0,
      connectionTimes: [],
      latencies: [],
    };

    this.startHealthMonitoring();
  }

  /**
   * Generate unique connection key based on SSH config
   */
  private generateConnectionKey(config: SSHConfig): string {
    return `${config.username}@${config.host}:${config.port || 22}`;
  }

  /**
   * Generate unique connection ID
   */
  private generateId(): string {
    return `ssh-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Get or create connection from pool (connection reuse)
   */
  async getOrCreateConnection(config: SSHConfig): Promise<SSHConnection> {
    const key = this.generateConnectionKey(config);
    let conn = this.pool.get(key);

    // Return existing connection if still valid
    if (conn && conn.connected) {
      conn.last_used = new Date();
      console.log(`[ConnectionPool] Reusing connection: ${key}`);
      return conn;
    }

    // Check pool size limit
    if (this.pool.size >= this.config.max_connections) {
      // Try to prune idle connections
      const pruned = await this.pruneIdleConnections();
      if (pruned === 0 && this.pool.size >= this.config.max_connections) {
        throw new Error(`Connection pool limit reached: ${this.config.max_connections}`);
      }
    }

    // Create new connection
    console.log(`[ConnectionPool] Creating new connection: ${key}`);
    const startTime = Date.now();

    const sshConnectArgs: SSHConnectArgs = {
      host: config.host,
      port: config.port || 22,
      username: config.username,
      auth_method: config.auth_method === 'password' ? 'password' : 'key',
      key_path: config.key_path,
      password: config.password,
    };

    const result = await this.connect(sshConnectArgs);
    if (!result.success) {
      throw new Error(result.error || 'Connection failed');
    }

    // Get the created connection
    conn = this.pool.get(key);
    if (!conn) {
      throw new Error('Failed to retrieve connection from pool');
    }

    // Track connection time
    const connectionTime = Date.now() - startTime;
    this.connectionMetrics.connectionTimes.push(connectionTime);
    this.connectionMetrics.totalConnections++;

    return conn;
  }

  /**
   * Original connect method (now creates SSHConnection in pool)
   */
  async connect(args: SSHConnectArgs): Promise<SSHConnectionResult> {
    const { host, port = 22, username, auth_method, key_path, password } = args;

    // Security: whitelist hosts
    if (!this.allowedHosts.includes(host)) {
      return {
        success: false,
        error: `Host '${host}' not in whitelist`,
        timestamp: new Date().toISOString(),
      };
    }

    try {
      const client = new Client();
      const connectionId = this.generateId();
      const sshConfig: SSHConfig = {
        host,
        port,
        username,
        auth_method: auth_method === 'password' ? 'password' : 'key',
        key_path,
        password,
      };
      const connectionKey = this.generateConnectionKey(sshConfig);

      const connectPromise = new Promise<SSHConnectionResult>((resolve, reject) => {
        client.on('ready', () => {
          const conn: SSHConnection = {
            id: connectionId,
            config: sshConfig,
            client,
            connected: true,
            created_at: new Date(),
            last_used: new Date(),
            bytes_sent: 0,
            bytes_received: 0,
            commands_executed: 0,
            health_status: 'healthy',
            error_count: 0,
          };
          this.pool.set(connectionKey, conn);

          console.log(`[SSH] Connection established: ${connectionKey}`);

          resolve({
            success: true,
            data: {
              connection_id: connectionId,
              host,
              username,
              connected: true,
            },
            timestamp: new Date().toISOString(),
          });
        });

        client.on('error', (err: any) => {
          this.connectionMetrics.totalErrors++;
          reject(new Error(`SSH connection failed: ${err.message}`));
        });

        client.on('close', () => {
          const conn = this.pool.get(connectionKey);
          if (conn) {
            conn.connected = false;
            console.log(`[SSH] Connection closed: ${connectionKey}`);
          }
        });

        // Configure connection
        const config: any = {
          host,
          port,
          username,
          readyTimeout: 30000,
          keepaliveInterval: 30000,
          keepaliveCountMax: 3,
        };

        if (auth_method === 'key' && key_path) {
          fs.readFile(key_path).then(privateKey => {
            config.privateKey = privateKey;
            client.connect(config);
          }).catch(reject);
        } else if (auth_method === 'password' && password) {
          config.password = password;
          client.connect(config);
        } else {
          reject(new Error('Invalid authentication method or missing credentials'));
        }
      });

      return await connectPromise;
    } catch (error: any) {
      this.connectionMetrics.totalErrors++;
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Connect with MFA support (keyboard-interactive authentication)
   */
  async connectWithMFA(config: SSHConfig, mfaCode: string): Promise<SSHConnection> {
    // Validate MFA code format (6 digits)
    if (!/^\d{6}$/.test(mfaCode)) {
      throw new Error('Invalid MFA code format. Expected 6 digits.');
    }

    // Check pool size limit
    if (this.pool.size >= this.config.max_connections) {
      const pruned = await this.pruneIdleConnections();
      if (pruned === 0 && this.pool.size >= this.config.max_connections) {
        throw new Error(`Connection pool limit reached: ${this.config.max_connections}`);
      }
    }

    const client = new Client();
    const connectionId = this.generateId();
    const connectionKey = this.generateConnectionKey(config);

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        client.end();
        reject(new Error('MFA authentication timeout'));
      }, 30000);

      client.on('keyboard-interactive', (name: string, instructions: string, lang: string, prompts: any[], finish: (responses: string[]) => void) => {
        console.log(`[SSH MFA] Responding to MFA prompt`);
        finish([mfaCode]);
      });

      client.on('ready', () => {
        clearTimeout(timeout);
        const conn: SSHConnection = {
          id: connectionId,
          config,
          client,
          connected: true,
          created_at: new Date(),
          last_used: new Date(),
          bytes_sent: 0,
          bytes_received: 0,
          commands_executed: 0,
          health_status: 'healthy',
          error_count: 0,
        };
        this.pool.set(connectionKey, conn);
        this.connectionMetrics.totalConnections++;

        console.log(`[SSH MFA] Connection established: ${connectionKey}`);
        resolve(conn);
      });

      client.on('error', (err: any) => {
        clearTimeout(timeout);
        this.connectionMetrics.totalErrors++;
        reject(new Error(`MFA connection failed: ${err.message}`));
      });

      client.connect({
        host: config.host,
        port: config.port || 22,
        username: config.username,
        tryKeyboard: true,
        readyTimeout: 30000,
      });
    });
  }

  /**
   * Prune idle connections from pool
   */
  async pruneIdleConnections(maxIdleTime?: number): Promise<number> {
    const threshold = maxIdleTime || this.config.max_idle_time_ms;
    const now = Date.now();
    let pruned = 0;

    for (const [key, conn] of this.pool.entries()) {
      const idleTime = now - conn.last_used.getTime();
      const age = now - conn.created_at.getTime();

      // Remove if idle too long or connection is too old
      if (idleTime > threshold || (this.config.max_connection_age_ms && age > this.config.max_connection_age_ms)) {
        try {
          conn.client.end();
          this.pool.delete(key);
          pruned++;
          console.log(`[ConnectionPool] Pruned idle connection: ${key} (idle: ${Math.round(idleTime / 1000)}s)`);
        } catch (error) {
          console.error(`[ConnectionPool] Error pruning connection ${key}:`, error);
        }
      }
    }

    if (pruned > 0) {
      console.log(`[ConnectionPool] Pruned ${pruned} idle connection(s)`);
    }

    return pruned;
  }

  /**
   * Ping connection to check if it's alive
   */
  private async ping(client: Client): Promise<number> {
    return new Promise((resolve, reject) => {
      const start = Date.now();
      const timeout = setTimeout(() => {
        reject(new Error('Ping timeout'));
      }, this.config.health_check_timeout_ms || 5000);

      // Send keepalive and wait for response
      try {
        client.once('error', (err: Error) => {
          clearTimeout(timeout);
          reject(err);
        });

        // Request a channel as a simple health check
        client.exec('echo ping', (err: Error | undefined, channel: any) => {
          clearTimeout(timeout);
          if (err) {
            reject(err);
            return;
          }
          channel.end();
          const latency = Date.now() - start;
          resolve(latency);
        });
      } catch (error) {
        clearTimeout(timeout);
        reject(error);
      }
    });
  }

  /**
   * Health check for a single connection
   */
  async healthCheck(conn: SSHConnection): Promise<ConnectionHealthStatus> {
    try {
      const start = Date.now();
      const latency = await this.ping(conn.client);
      const uptime = (Date.now() - conn.created_at.getTime()) / 1000;

      // Track latency
      this.connectionMetrics.latencies.push(latency);
      if (this.connectionMetrics.latencies.length > 100) {
        this.connectionMetrics.latencies.shift();
      }

      const status = latency < 1000 ? 'healthy' : 'degraded';
      conn.health_status = status;

      return {
        connection_id: conn.id,
        status,
        latency_ms: latency,
        uptime_seconds: uptime,
        last_check: new Date(),
        issues: latency > 1000 ? ['High latency'] : [],
        metrics: {
          success_rate: 1 - (conn.error_count / Math.max(conn.commands_executed, 1)),
          avg_latency_ms: latency,
          error_count: conn.error_count,
        },
      };
    } catch (error: any) {
      conn.health_status = 'failed';
      conn.error_count++;
      this.connectionMetrics.totalErrors++;

      return {
        connection_id: conn.id,
        status: 'failed',
        latency_ms: 0,
        uptime_seconds: 0,
        last_check: new Date(),
        issues: [error.message],
        metrics: {
          success_rate: 0,
          avg_latency_ms: 0,
          error_count: conn.error_count,
        },
      };
    }
  }

  /**
   * Monitor health of all connections
   */
  async monitorAll(): Promise<Map<string, ConnectionHealthStatus>> {
    const results = new Map<string, ConnectionHealthStatus>();

    for (const [key, conn] of this.pool.entries()) {
      if (conn.connected) {
        const health = await this.healthCheck(conn);
        results.set(key, health);

        // Auto-remove failed connections
        if (health.status === 'failed') {
          console.log(`[HealthMonitor] Removing failed connection: ${key}`);
          conn.client.end();
          this.pool.delete(key);
        }
      }
    }

    return results;
  }

  /**
   * Start automatic health monitoring
   */
  private startHealthMonitoring(): void {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }

    this.healthCheckInterval = setInterval(async () => {
      console.log(`[HealthMonitor] Running health check on ${this.pool.size} connection(s)`);
      
      // Run health checks
      await this.monitorAll();
      
      // Prune idle connections
      await this.pruneIdleConnections();
    }, this.config.health_check_interval_ms);

    console.log(`[HealthMonitor] Started (interval: ${this.config.health_check_interval_ms}ms)`);
  }

  /**
   * Stop health monitoring
   */
  stopHealthMonitoring(): void {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
      this.healthCheckInterval = undefined;
      console.log(`[HealthMonitor] Stopped`);
    }
  }

  /**
   * Get connection pool status
   */
  getPoolStatus(): PoolStatus {
    const now = Date.now();
    const connections = Array.from(this.pool.entries()).map(([key, conn]) => ({
      id: conn.id,
      host: key,
      status: conn.connected ? (conn.health_status === 'healthy' ? 'active' as const : 'idle' as const) : 'failed' as const,
      age_seconds: (now - conn.created_at.getTime()) / 1000,
      last_used: conn.last_used,
    }));

    const activeCount = connections.filter(c => c.status === 'active').length;
    const idleCount = connections.filter(c => c.status === 'idle').length;
    const failedCount = connections.filter(c => c.status === 'failed').length;

    const warnings: string[] = [];
    if (this.pool.size >= this.config.max_connections * 0.8) {
      warnings.push(`Pool usage high: ${this.pool.size}/${this.config.max_connections}`);
    }
    if (failedCount > 0) {
      warnings.push(`${failedCount} failed connection(s) detected`);
    }

    const health = failedCount > this.pool.size * 0.5 ? 'critical' as const :
                   idleCount > activeCount ? 'degraded' as const : 'healthy' as const;

    return {
      statistics: this.getPoolStatistics(),
      connections,
      health,
      warnings,
    };
  }

  /**
   * Get connection pool statistics
   */
  getPoolStatistics(): PoolStatistics {
    const activeConnections = Array.from(this.pool.values()).filter(c => c.connected && c.health_status === 'healthy').length;
    const idleConnections = Array.from(this.pool.values()).filter(c => c.connected && c.health_status !== 'healthy').length;
    const failedConnections = Array.from(this.pool.values()).filter(c => !c.connected).length;

    const totalBytesTransferred = Array.from(this.pool.values()).reduce(
      (sum, conn) => sum + conn.bytes_sent + conn.bytes_received,
      0
    );

    const avgConnectionTime = this.connectionMetrics.connectionTimes.length > 0
      ? this.connectionMetrics.connectionTimes.reduce((a, b) => a + b, 0) / this.connectionMetrics.connectionTimes.length
      : 0;

    const avgLatency = this.connectionMetrics.latencies.length > 0
      ? this.connectionMetrics.latencies.reduce((a, b) => a + b, 0) / this.connectionMetrics.latencies.length
      : 0;

    const memoryUsageMb = (process.memoryUsage().heapUsed / 1024 / 1024);

    return {
      total_connections: this.pool.size,
      active_connections: activeConnections,
      idle_connections: idleConnections,
      failed_connections: failedConnections,
      avg_connection_time_ms: avgConnectionTime,
      avg_latency_ms: avgLatency,
      total_bytes_transferred: totalBytesTransferred,
      memory_usage_mb: memoryUsageMb,
      health_check_failures: this.connectionMetrics.totalErrors,
      last_health_check: new Date(),
    };
  }

  /**
   * Get connection by ID (backward compatibility)
   */
  getConnection(connectionId: string): SSHConnection | undefined {
    return Array.from(this.pool.values()).find(conn => conn.id === connectionId);
  }

  /**
   * Disconnect a specific connection
   */
  disconnect(connectionId: string): boolean {
    const conn = this.getConnection(connectionId);
    if (conn) {
      const key = this.generateConnectionKey(conn.config);
      conn.client.end();
      this.pool.delete(key);
      console.log(`[SSH] Disconnected: ${key}`);
      return true;
    }
    return false;
  }

  /**
   * Disconnect all connections and stop monitoring
   */
  disconnectAll(): void {
    console.log(`[ConnectionPool] Disconnecting all ${this.pool.size} connection(s)`);
    
    for (const [key, conn] of this.pool.entries()) {
      try {
        conn.client.end();
      } catch (error) {
        console.error(`[ConnectionPool] Error disconnecting ${key}:`, error);
      }
    }
    
    this.pool.clear();
    this.stopHealthMonitoring();
    
    console.log(`[ConnectionPool] All connections closed`);
  }

  /**
   * List all connections (backward compatibility)
   */
  listConnections(): Array<{ id: string; host: string; username: string; uptime: number }> {
    return Array.from(this.pool.values()).map(conn => ({
      id: conn.id,
      host: conn.config.host,
      username: conn.config.username,
      uptime: Date.now() - conn.created_at.getTime(),
    }));
  }

  /**
   * Cleanup method for graceful shutdown
   */
  async cleanup(): Promise<void> {
    console.log(`[ConnectionPool] Cleanup initiated`);
    this.stopHealthMonitoring();
    this.disconnectAll();
  }
}

export const sshConnectSchema = {
  name: "ssh_connect",
  description: "Establish SSH connection to remote server (whitelisted hosts only)",
  inputSchema: {
    type: "object",
    properties: {
      host: { type: "string", description: "Hostname or IP" },
      port: { type: "number", description: "SSH port (default: 22)" },
      username: { type: "string", description: "SSH username" },
      auth_method: { type: "string", enum: ["key", "password"] },
      key_path: { type: "string", description: "Path to private key (for key auth)" },
      password: { type: "string", description: "Password (for password auth)" },
    },
    required: ["host", "username", "auth_method"],
  },
};