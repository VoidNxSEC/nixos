/**
 * SSH Tunnel Manager - Complete tunneling support for SecureLLM Bridge
 * Supports local port forwarding, remote port forwarding, and dynamic SOCKS proxy
 */
import { SSHConnectionManager } from './connection-manager.js';
import type { LocalTunnelConfig, RemoteTunnelConfig, DynamicTunnelConfig, Tunnel, TunnelStatus, TunnelMetrics } from '../../types/ssh-advanced.js';
import type { ToolResult } from '../../types/extended-tools.js';
/**
 * Tunnel result type for tool responses
 */
export interface TunnelResult extends ToolResult {
    data?: {
        tunnel_id: string;
        type: 'local' | 'remote' | 'dynamic';
        local_endpoint: string;
        remote_endpoint: string;
        status: string;
    };
}
/**
 * SSH Tunnel Manager - Manages SSH tunnels (local, remote, dynamic SOCKS)
 */
export declare class SSHTunnelManager {
    private tunnels;
    private connectionManager;
    private servers;
    private streams;
    constructor(connectionManager: SSHConnectionManager);
    /**
     * Create local port forwarding tunnel: -L [bind_address:]local_port:remote_host:remote_port
     * Forwards local port to remote destination through SSH server
     */
    createLocalTunnel(config: LocalTunnelConfig): Promise<TunnelResult>;
    /**
     * Create remote port forwarding tunnel: -R [bind_address:]remote_port:local_host:local_port
     * Forwards remote port back to local destination
     */
    createRemoteTunnel(config: RemoteTunnelConfig): Promise<TunnelResult>;
    /**
     * Create dynamic SOCKS proxy: -D [bind_address:]socks_port
     * Creates a SOCKS proxy on local port (simplified SOCKS5 implementation)
     */
    createDynamicTunnel(config: DynamicTunnelConfig): Promise<TunnelResult>;
    /**
     * List all active tunnels, optionally filtered by connection
     */
    listTunnels(connection_id?: string): Promise<Tunnel[]>;
    /**
     * Close a specific tunnel
     */
    closeTunnel(tunnel_id: string): Promise<void>;
    /**
     * Get detailed status of a tunnel
     */
    getTunnelStatus(tunnel_id: string): Promise<TunnelStatus>;
    /**
     * Monitor tunnel and get current metrics
     */
    monitorTunnel(tunnel_id: string): Promise<TunnelMetrics>;
    /**
     * Auto-reconnect tunnel with exponential backoff
     */
    private reconnectTunnel;
    /**
     * Generate unique tunnel ID
     */
    private generateTunnelId;
    /**
     * Cleanup all tunnels
     */
    cleanup(): Promise<void>;
}
/**
 * MCP tool schema for SSH tunneling
 */
export declare const sshTunnelSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            type: {
                type: string;
                enum: string[];
                description: string;
            };
            connection_id: {
                type: string;
                description: string;
            };
            local_port: {
                type: string;
                description: string;
            };
            remote_host: {
                type: string;
                description: string;
            };
            remote_port: {
                type: string;
                description: string;
            };
            local_host: {
                type: string;
                description: string;
            };
            socks_port: {
                type: string;
                description: string;
            };
            socks_version: {
                type: string;
                enum: number[];
                description: string;
            };
            bind_address: {
                type: string;
                description: string;
            };
            keep_alive: {
                type: string;
                description: string;
            };
            auto_restart: {
                type: string;
                description: string;
            };
            timeout_seconds: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=tunnel-manager.d.ts.map