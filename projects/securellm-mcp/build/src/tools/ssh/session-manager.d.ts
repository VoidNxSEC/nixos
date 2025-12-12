/**
 * SSH Session Manager - Persistence and Auto-Recovery
 * Manages SSH session persistence to SQLite and provides automatic recovery
 */
import { SSHConnectionManager } from './connection-manager.js';
import { SSHTunnelManager } from './tunnel-manager.js';
import type { SessionConfig, SessionData, SessionInfo, SessionRecoveryResult, SessionState } from '../../types/ssh-advanced.js';
/**
 * Session Manager - Handles SSH session persistence and auto-recovery
 */
export declare class SessionManager {
    private db;
    private sessions;
    private recoveryTimers;
    private connectionManager;
    private tunnelManager?;
    constructor(dbPath: string, connectionManager: SSHConnectionManager, tunnelManager?: SSHTunnelManager);
    /**
     * Initialize SQLite database schema
     */
    private initDatabase;
    /**
     * Load existing sessions from database
     */
    private loadSessions;
    /**
     * Persist a session with configuration
     */
    persistSession(config: SessionConfig): Promise<SessionData>;
    /**
     * Restore a session from database
     */
    restoreSession(sessionId: string): Promise<SessionRecoveryResult>;
    /**
     * Setup auto-recovery monitoring for a session
     */
    private setupAutoRecovery;
    /**
     * Schedule next health check
     */
    private scheduleNextCheck;
    /**
     * Calculate backoff delay based on strategy
     */
    private calculateBackoff;
    /**
     * List all sessions
     */
    listSessions(activeOnly?: boolean): Promise<SessionInfo[]>;
    /**
     * Save current session state
     */
    saveSessionState(sessionId: string): Promise<void>;
    /**
     * Load session state
     */
    loadSessionState(sessionId: string): Promise<SessionState>;
    /**
     * Clean up expired sessions
     */
    cleanupExpiredSessions(): Promise<number>;
    /**
     * Delete a specific session
     */
    deleteSession(sessionId: string): Promise<void>;
    /**
     * Save resource to database
     */
    private saveResource;
    /**
     * Load resources from database
     */
    private loadResources;
    /**
     * Get tunnel configurations for a connection
     */
    private getTunnelConfigs;
    /**
     * Get port forward configurations for a connection
     */
    private getPortForwardConfigs;
    /**
     * Get jump chain configuration for a connection
     */
    private getJumpChainConfig;
    /**
     * Generate unique session ID
     */
    private generateSessionId;
    /**
     * Cleanup all sessions and close database
     */
    cleanup(): Promise<void>;
}
/**
 * MCP tool schema for session management
 */
export declare const sshSessionSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            action: {
                type: string;
                enum: string[];
                description: string;
            };
            session_id: {
                type: string;
                description: string;
            };
            connection_id: {
                type: string;
                description: string;
            };
            persist: {
                type: string;
                description: string;
            };
            auto_recover: {
                type: string;
                description: string;
            };
            max_recovery_attempts: {
                type: string;
                description: string;
            };
            recovery_backoff_ms: {
                type: string;
                description: string;
            };
            recovery_strategy: {
                type: string;
                enum: string[];
                description: string;
            };
            save_tunnel_state: {
                type: string;
                description: string;
            };
            save_port_forwards: {
                type: string;
                description: string;
            };
            save_jump_chain: {
                type: string;
                description: string;
            };
            active_only: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=session-manager.d.ts.map