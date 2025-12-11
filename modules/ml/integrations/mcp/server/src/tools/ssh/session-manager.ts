/**
 * SSH Session Manager - Persistence and Auto-Recovery
 * Manages SSH session persistence to SQLite and provides automatic recovery
 */

import Database from 'better-sqlite3';
import { SSHConnectionManager } from './connection-manager.js';
import { SSHTunnelManager } from './tunnel-manager.js';
import type {
  SessionConfig,
  SessionData,
  SessionInfo,
  SessionRecoveryResult,
  SessionState,
  TunnelConfig,
  PortForwardRule,
  JumpChainConfig,
  SSHConfig,
} from '../../types/ssh-advanced.js';

/**
 * Session Manager - Handles SSH session persistence and auto-recovery
 */
export class SessionManager {
  private db: Database.Database;
  private sessions: Map<string, SessionInfo> = new Map();
  private recoveryTimers: Map<string, NodeJS.Timeout> = new Map();
  private connectionManager: SSHConnectionManager;
  private tunnelManager?: SSHTunnelManager;

  constructor(
    dbPath: string,
    connectionManager: SSHConnectionManager,
    tunnelManager?: SSHTunnelManager
  ) {
    this.db = new Database(dbPath);
    this.connectionManager = connectionManager;
    this.tunnelManager = tunnelManager;
    
    this.initDatabase();
    this.loadSessions();
    
    console.log('[SessionManager] Initialized with database:', dbPath);
  }

  /**
   * Initialize SQLite database schema
   */
  private initDatabase(): void {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        session_id TEXT PRIMARY KEY,
        connection_config TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_active TEXT NOT NULL,
        persist INTEGER DEFAULT 0,
        auto_recover INTEGER DEFAULT 0,
        recovery_count INTEGER DEFAULT 0,
        state_data TEXT
      );
      
      CREATE TABLE IF NOT EXISTS session_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        resource_type TEXT NOT NULL,
        resource_config TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(session_id)
      );
    `);

    console.log('[SessionManager] Database schema initialized');
  }

  /**
   * Load existing sessions from database
   */
  private loadSessions(): void {
    try {
      const rows = this.db.prepare(`
        SELECT session_id, persist, auto_recover, recovery_count, created_at, last_active
        FROM sessions
        WHERE persist = 1
      `).all();

      for (const row of rows) {
        const r = row as any;
        const sessionInfo: SessionInfo = {
          session_id: r.session_id,
          connection_id: undefined, // Not connected yet
          status: 'persisted',
          created_at: new Date(r.created_at),
          last_active: new Date(r.last_active),
          persisted: r.persist === 1,
          auto_recover: r.auto_recover === 1,
          recovery_count: r.recovery_count,
          has_tunnels: false,
          has_port_forwards: false,
          has_jump_chain: false,
        };

        this.sessions.set(r.session_id, sessionInfo);
      }

      console.log(`[SessionManager] Loaded ${rows.length} persisted session(s)`);
    } catch (error: any) {
      console.error('[SessionManager] Error loading sessions:', error);
    }
  }

  /**
   * Persist a session with configuration
   */
  async persistSession(config: SessionConfig): Promise<SessionData> {
    const sessionId = this.generateSessionId();
    const conn = this.connectionManager.getConnection(config.connection_id);

    if (!conn) {
      throw new Error('Connection not found');
    }

    // Gather session data
    const sessionData: SessionData = {
      session_id: sessionId,
      connection_config: conn.config,
      created_at: new Date().toISOString(),
      last_active: new Date().toISOString(),
      connection_metadata: {
        bytes_sent: conn.bytes_sent ?? 0,
        bytes_received: conn.bytes_received ?? 0,
        commands_executed: conn.commands_executed ?? 0,
      },
      tunnels: config.save_tunnel_state ? await this.getTunnelConfigs(config.connection_id) : undefined,
      port_forwards: config.save_port_forwards ? await this.getPortForwardConfigs(config.connection_id) : undefined,
      jump_chain: config.save_jump_chain ? await this.getJumpChainConfig(config.connection_id) : undefined,
      recovery_count: 0,
      recovery_state: 'stable',
    };

    // Save to database if persistence enabled
    if (config.persist) {
      this.db.prepare(`
        INSERT INTO sessions (session_id, connection_config, created_at, last_active, persist, auto_recover, state_data)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).run(
        sessionId,
        JSON.stringify(sessionData.connection_config),
        sessionData.created_at,
        sessionData.last_active,
        1,
        config.auto_recover ? 1 : 0,
        JSON.stringify(sessionData)
      );

      // Save resources
      if (sessionData.tunnels) {
        for (const tunnel of sessionData.tunnels) {
          this.saveResource(sessionId, 'tunnel', tunnel);
        }
      }

      if (sessionData.port_forwards) {
        for (const forward of sessionData.port_forwards) {
          this.saveResource(sessionId, 'port_forward', forward);
        }
      }

      if (sessionData.jump_chain) {
        this.saveResource(sessionId, 'jump_chain', sessionData.jump_chain);
      }

      console.log(`[SessionManager] Session persisted: ${sessionId}`);
    }

    // Create session info
    const sessionInfo: SessionInfo = {
      session_id: sessionId,
      connection_id: config.connection_id,
      status: 'active',
      created_at: new Date(),
      last_active: new Date(),
      persisted: config.persist,
      auto_recover: config.auto_recover,
      recovery_count: 0,
      has_tunnels: !!sessionData.tunnels && sessionData.tunnels.length > 0,
      has_port_forwards: !!sessionData.port_forwards && sessionData.port_forwards.length > 0,
      has_jump_chain: !!sessionData.jump_chain,
    };

    this.sessions.set(sessionId, sessionInfo);

    // Setup auto-recovery if enabled
    if (config.auto_recover) {
      this.setupAutoRecovery(sessionId, config);
    }

    return sessionData;
  }

  /**
   * Restore a session from database
   */
  async restoreSession(sessionId: string): Promise<SessionRecoveryResult> {
    const row: any = this.db.prepare(`
      SELECT * FROM sessions WHERE session_id = ?
    `).get(sessionId);

    if (!row) {
      return {
        success: false,
        error: 'Session not found',
        timestamp: new Date().toISOString(),
      };
    }

    const sessionData: SessionData = JSON.parse(row.state_data);
    const start = Date.now();
    const warnings: string[] = [];

    try {
      // Reconnect
      console.log(`[SessionManager] Restoring session: ${sessionId}`);
      const conn = await this.connectionManager.getOrCreateConnection(sessionData.connection_config);

      // Restore resources
      const recoveredResources = {
        tunnels: 0,
        port_forwards: 0,
        jump_chain: false,
      };

      // Restore tunnels
      if (sessionData.tunnels && this.tunnelManager) {
        for (const tunnelConfig of sessionData.tunnels) {
          try {
            // Recreate tunnel based on type
            if (tunnelConfig.type === 'local') {
              await this.tunnelManager.createLocalTunnel(tunnelConfig);
            } else if (tunnelConfig.type === 'remote') {
              await this.tunnelManager.createRemoteTunnel(tunnelConfig);
            } else if (tunnelConfig.type === 'dynamic') {
              await this.tunnelManager.createDynamicTunnel(tunnelConfig);
            }
            recoveredResources.tunnels++;
          } catch (error: any) {
            console.error(`[SessionManager] Failed to restore tunnel:`, error);
            warnings.push(`Tunnel restoration failed: ${error.message}`);
          }
        }
      }

      // Restore port forwards
      if (sessionData.port_forwards) {
        recoveredResources.port_forwards = sessionData.port_forwards.length;
        // Note: Port forward restoration would require a PortForwardManager
        warnings.push('Port forward restoration not yet implemented');
      }

      // Restore jump chain
      if (sessionData.jump_chain) {
        recoveredResources.jump_chain = true;
        // Note: Jump chain restoration would require tracking in JumpHostManager
        warnings.push('Jump chain restoration not yet implemented');
      }

      // Update session in database
      this.db.prepare(`
        UPDATE sessions 
        SET last_active = ?, recovery_count = recovery_count + 1
        WHERE session_id = ?
      `).run(new Date().toISOString(), sessionId);

      // Update session info
      const sessionInfo = this.sessions.get(sessionId);
      if (sessionInfo) {
        const updatedInfo: SessionInfo = {
          ...sessionInfo,
          connection_id: conn.id,
          status: 'active',
          last_active: new Date(),
          recovery_count: sessionInfo.recovery_count + 1,
        };
        this.sessions.set(sessionId, updatedInfo);
      }

      console.log(`[SessionManager] Session restored: ${sessionId} (${Date.now() - start}ms)`);

      return {
        success: true,
        data: {
          session_id: sessionId,
          connection_id: conn.id,
          recovery_time_ms: Date.now() - start,
          recovered_resources: recoveredResources,
          warnings,
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error(`[SessionManager] Session recovery failed:`, error);
      return {
        success: false,
        error: `Session recovery failed: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Setup auto-recovery monitoring for a session
   */
  private setupAutoRecovery(sessionId: string, config: SessionConfig): void {
    const checkInterval = 30000; // 30 seconds
    const maxAttempts = config.max_recovery_attempts || 3;
    const backoffMs = config.recovery_backoff_ms || 5000;

    const attemptRecovery = async (attempt: number = 1) => {
      if (attempt > maxAttempts) {
        console.error(`[SessionManager] Session ${sessionId}: Max recovery attempts reached`);
        const sessionInfo = this.sessions.get(sessionId);
        if (sessionInfo) {
          const updatedInfo: SessionInfo = {
            ...sessionInfo,
            status: 'disconnected',
          };
          this.sessions.set(sessionId, updatedInfo);
        }
        return;
      }

      const sessionInfo = this.sessions.get(sessionId);
      if (!sessionInfo) return;

      // Check if connection is still alive
      const conn = sessionInfo.connection_id 
        ? this.connectionManager.getConnection(sessionInfo.connection_id)
        : null;

      if (conn && conn.connected) {
        // Connection is fine, schedule next check
        this.scheduleNextCheck(sessionId, config, () => attemptRecovery(1));
        return;
      }

      // Connection lost, attempt recovery
      console.log(`[SessionManager] Session ${sessionId}: Attempting recovery (attempt ${attempt}/${maxAttempts})`);

      try {
        const result = await this.restoreSession(sessionId);
        if (result.success) {
          console.log(`[SessionManager] Session ${sessionId}: Recovery successful`);
          // Schedule next check
          this.scheduleNextCheck(sessionId, config, () => attemptRecovery(1));
        } else {
          // Retry with backoff
          const delay = this.calculateBackoff(attempt, backoffMs, config.recovery_strategy);
          console.log(`[SessionManager] Session ${sessionId}: Retrying in ${delay}ms`);
          setTimeout(() => attemptRecovery(attempt + 1), delay);
        }
      } catch (error: any) {
        console.error(`[SessionManager] Session ${sessionId}: Recovery failed:`, error);
        const delay = this.calculateBackoff(attempt, backoffMs, config.recovery_strategy);
        setTimeout(() => attemptRecovery(attempt + 1), delay);
      }
    };

    // Start monitoring
    this.scheduleNextCheck(sessionId, config, () => attemptRecovery(1));
    console.log(`[SessionManager] Auto-recovery enabled for session: ${sessionId}`);
  }

  /**
   * Schedule next health check
   */
  private scheduleNextCheck(
    sessionId: string,
    config: SessionConfig,
    callback: () => void
  ): void {
    // Clear existing timer
    const existing = this.recoveryTimers.get(sessionId);
    if (existing) {
      clearTimeout(existing);
    }

    // Schedule next check (default: 30 seconds)
    const timer = setTimeout(callback, 30000);
    this.recoveryTimers.set(sessionId, timer);
  }

  /**
   * Calculate backoff delay based on strategy
   */
  private calculateBackoff(
    attempt: number,
    baseMs: number,
    strategy?: string
  ): number {
    if (strategy === 'exponential') {
      return Math.min(baseMs * Math.pow(2, attempt - 1), 60000);
    } else if (strategy === 'linear') {
      return baseMs * attempt;
    }
    return baseMs; // 'immediate' or default
  }

  /**
   * List all sessions
   */
  async listSessions(activeOnly?: boolean): Promise<SessionInfo[]> {
    const sessions = Array.from(this.sessions.values());
    if (activeOnly) {
      return sessions.filter(s => s.status === 'active');
    }
    return sessions;
  }

  /**
   * Save current session state
   */
  async saveSessionState(sessionId: string): Promise<void> {
    const sessionInfo = this.sessions.get(sessionId);
    if (!sessionInfo) {
      throw new Error('Session not found');
    }

    if (!sessionInfo.connection_id) {
      throw new Error('Session not connected');
    }

    const conn = this.connectionManager.getConnection(sessionInfo.connection_id);
    if (!conn) {
      throw new Error('Connection not found');
    }

    const sessionData: SessionData = {
      session_id: sessionId,
      connection_config: conn.config,
      created_at: sessionInfo.created_at.toISOString(),
      last_active: new Date().toISOString(),
      connection_metadata: {
        bytes_sent: conn.bytes_sent ?? 0,
        bytes_received: conn.bytes_received ?? 0,
        commands_executed: conn.commands_executed ?? 0,
      },
      tunnels: await this.getTunnelConfigs(sessionInfo.connection_id),
      port_forwards: await this.getPortForwardConfigs(sessionInfo.connection_id),
      jump_chain: await this.getJumpChainConfig(sessionInfo.connection_id),
      recovery_count: sessionInfo.recovery_count,
      recovery_state: 'stable',
    };

    this.db.prepare(`
      UPDATE sessions
      SET state_data = ?, last_active = ?
      WHERE session_id = ?
    `).run(
      JSON.stringify(sessionData),
      sessionData.last_active,
      sessionId
    );

    console.log(`[SessionManager] Session state saved: ${sessionId}`);
  }

  /**
   * Load session state
   */
  async loadSessionState(sessionId: string): Promise<SessionState> {
    const row: any = this.db.prepare(`
      SELECT state_data FROM sessions WHERE session_id = ?
    `).get(sessionId);

    if (!row) {
      throw new Error('Session not found');
    }

    const sessionData: SessionData = JSON.parse(row.state_data);
    const sessionInfo = this.sessions.get(sessionId);

    return {
      session_id: sessionId,
      timestamp: new Date(),
      connection_state: sessionInfo?.status === 'active' ? 'connected' : 'disconnected',
      active_tunnels: sessionData.tunnels?.map((t, i) => `tunnel-${i}`) || [],
      active_port_forwards: sessionData.port_forwards?.map((p, i) => `forward-${i}`) || [],
      jump_chain_id: sessionData.jump_chain ? 'jump-chain-1' : undefined,
      metrics: {
        uptime_seconds: sessionInfo 
          ? (Date.now() - sessionInfo.created_at.getTime()) / 1000 
          : 0,
        total_bytes_transferred: sessionData.connection_metadata.bytes_sent + sessionData.connection_metadata.bytes_received,
        total_commands: sessionData.connection_metadata.commands_executed,
      },
    };
  }

  /**
   * Clean up expired sessions
   */
  async cleanupExpiredSessions(): Promise<number> {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 7); // 7 days old

    const result = this.db.prepare(`
      DELETE FROM sessions
      WHERE persist = 0 AND last_active < ?
    `).run(cutoff.toISOString());

    console.log(`[SessionManager] Cleaned up ${result.changes} expired session(s)`);
    return result.changes;
  }

  /**
   * Delete a specific session
   */
  async deleteSession(sessionId: string): Promise<void> {
    // Stop auto-recovery if active
    const timer = this.recoveryTimers.get(sessionId);
    if (timer) {
      clearTimeout(timer);
      this.recoveryTimers.delete(sessionId);
    }

    // Delete from database
    this.db.prepare(`
      DELETE FROM session_resources WHERE session_id = ?
    `).run(sessionId);

    this.db.prepare(`
      DELETE FROM sessions WHERE session_id = ?
    `).run(sessionId);

    // Remove from memory
    this.sessions.delete(sessionId);

    console.log(`[SessionManager] Session deleted: ${sessionId}`);
  }

  /**
   * Save resource to database
   */
  private saveResource(sessionId: string, type: string, config: any): void {
    this.db.prepare(`
      INSERT INTO session_resources (session_id, resource_type, resource_config)
      VALUES (?, ?, ?)
    `).run(sessionId, type, JSON.stringify(config));
  }

  /**
   * Load resources from database
   */
  private loadResources(sessionId: string, type: string): any[] {
    const rows = this.db.prepare(`
      SELECT resource_config FROM session_resources
      WHERE session_id = ? AND resource_type = ?
    `).all(sessionId, type);

    return rows.map((row: any) => JSON.parse(row.resource_config));
  }

  /**
   * Get tunnel configurations for a connection
   */
  private async getTunnelConfigs(connectionId: string): Promise<TunnelConfig[]> {
    if (!this.tunnelManager) {
      return [];
    }

    try {
      const tunnels = await this.tunnelManager.listTunnels(connectionId);
      return tunnels.map(t => t.config);
    } catch (error) {
      console.error('[SessionManager] Error getting tunnel configs:', error);
      return [];
    }
  }

  /**
   * Get port forward configurations for a connection
   */
  private async getPortForwardConfigs(connectionId: string): Promise<PortForwardRule[]> {
    // Note: This would require a PortForwardManager implementation
    // For now, return empty array
    return [];
  }

  /**
   * Get jump chain configuration for a connection
   */
  private async getJumpChainConfig(connectionId: string): Promise<JumpChainConfig | undefined> {
    // Note: This would require tracking in JumpHostManager
    // For now, return undefined
    return undefined;
  }

  /**
   * Generate unique session ID
   */
  private generateSessionId(): string {
    return `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Cleanup all sessions and close database
   */
  async cleanup(): Promise<void> {
    console.log('[SessionManager] Cleanup initiated');

    // Clear all recovery timers
    for (const [sessionId, timer] of this.recoveryTimers.entries()) {
      clearTimeout(timer);
      console.log(`[SessionManager] Cleared recovery timer for session: ${sessionId}`);
    }
    this.recoveryTimers.clear();

    // Close database
    try {
      this.db.close();
      console.log('[SessionManager] Database closed');
    } catch (error) {
      console.error('[SessionManager] Error closing database:', error);
    }

    console.log('[SessionManager] Cleanup complete');
  }
}

/**
 * MCP tool schema for session management
 */
export const sshSessionSchema = {
  name: 'ssh_session_manager',
  description: 'Manage SSH sessions with persistence and auto-recovery',
  inputSchema: {
    type: 'object',
    properties: {
      action: {
        type: 'string',
        enum: ['save', 'restore', 'list', 'cleanup', 'status', 'delete'],
        description: 'Action to perform: save (persist session), restore (recover session), list (show sessions), cleanup (remove expired), status (get session state), delete (remove session)',
      },
      session_id: {
        type: 'string',
        description: 'Session ID (required for restore, status, delete)',
      },
      connection_id: {
        type: 'string',
        description: 'Connection ID (required for save)',
      },
      persist: {
        type: 'boolean',
        description: 'Save session to disk (default: true)',
      },
      auto_recover: {
        type: 'boolean',
        description: 'Enable automatic reconnection on failure (default: false)',
      },
      max_recovery_attempts: {
        type: 'number',
        description: 'Maximum recovery attempts (default: 3)',
      },
      recovery_backoff_ms: {
        type: 'number',
        description: 'Delay between recovery attempts in milliseconds (default: 5000)',
      },
      recovery_strategy: {
        type: 'string',
        enum: ['immediate', 'exponential', 'linear'],
        description: 'Backoff strategy for recovery attempts (default: exponential)',
      },
      save_tunnel_state: {
        type: 'boolean',
        description: 'Save active tunnels with session (default: true)',
      },
      save_port_forwards: {
        type: 'boolean',
        description: 'Save port forwards with session (default: true)',
      },
      save_jump_chain: {
        type: 'boolean',
        description: 'Save jump chain configuration with session (default: true)',
      },
      active_only: {
        type: 'boolean',
        description: 'List only active sessions (default: false)',
      },
    },
    required: ['action'],
  },
};