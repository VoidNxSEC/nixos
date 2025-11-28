/**
 * SSH Tunnel Manager - Complete tunneling support for SecureLLM Bridge
 * Supports local port forwarding, remote port forwarding, and dynamic SOCKS proxy
 */

import * as net from 'net';
import { SSHConnectionManager } from './connection-manager.js';
import type {
  LocalTunnelConfig,
  RemoteTunnelConfig,
  DynamicTunnelConfig,
  TunnelConfig,
  Tunnel,
  TunnelStatus,
  TunnelMetrics,
  SSHConnection,
} from '../../types/ssh-advanced.js';
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
export class SSHTunnelManager {
  private tunnels: Map<string, Tunnel> = new Map();
  private connectionManager: SSHConnectionManager;
  private servers: Map<string, net.Server> = new Map(); // For SOCKS and remote tunnels
  private streams: Map<string, any[]> = new Map(); // Track active streams per tunnel

  constructor(connectionManager: SSHConnectionManager) {
    this.connectionManager = connectionManager;
    console.log('[TunnelManager] Initialized');
  }

  /**
   * Create local port forwarding tunnel: -L [bind_address:]local_port:remote_host:remote_port
   * Forwards local port to remote destination through SSH server
   */
  async createLocalTunnel(config: LocalTunnelConfig): Promise<TunnelResult> {
    const conn = this.connectionManager.getConnection(config.connection_id);
    if (!conn) {
      return {
        success: false,
        error: 'Connection not found',
        timestamp: new Date().toISOString(),
      };
    }

    if (!conn.connected) {
      return {
        success: false,
        error: 'Connection not active',
        timestamp: new Date().toISOString(),
      };
    }

    const tunnelId = this.generateTunnelId();
    const bindAddress = config.bind_address || 'localhost';

    try {
      // Create local TCP server that forwards to remote
      const server = net.createServer((socket) => {
        console.log(`[LocalTunnel ${tunnelId}] New connection on ${bindAddress}:${config.local_port}`);

        const tunnel = this.tunnels.get(tunnelId);
        if (tunnel) {
          tunnel.connections_count++;
        }

        // Forward through SSH
        conn.client.forwardOut(
          bindAddress,
          config.local_port,
          config.remote_host,
          config.remote_port,
          (err: Error | undefined, stream: any) => {
            if (err) {
              console.error(`[LocalTunnel ${tunnelId}] Forward error:`, err);
              socket.end();
              if (tunnel) {
                tunnel.errors_count++;
                tunnel.last_error = err.message;
              }
              return;
            }

            // Track stream
            const streams = this.streams.get(tunnelId) || [];
            streams.push(stream);
            this.streams.set(tunnelId, streams);

            // Monitor traffic
            stream.on('data', (data: Buffer) => {
              if (tunnel) {
                tunnel.bytes_transferred += data.length;
              }
            });

            socket.on('data', (data: Buffer) => {
              if (tunnel) {
                tunnel.bytes_transferred += data.length;
              }
            });

            // Bidirectional pipe
            stream.pipe(socket);
            socket.pipe(stream);

            stream.on('close', () => {
              socket.end();
              const streams = this.streams.get(tunnelId) || [];
              const index = streams.indexOf(stream);
              if (index > -1) {
                streams.splice(index, 1);
              }
            });

            socket.on('close', () => {
              stream.end();
            });

            stream.on('error', (err: Error) => {
              console.error(`[LocalTunnel ${tunnelId}] Stream error:`, err);
              if (tunnel) {
                tunnel.errors_count++;
                tunnel.last_error = err.message;
              }
              socket.end();
            });

            socket.on('error', (err: Error) => {
              console.error(`[LocalTunnel ${tunnelId}] Socket error:`, err);
              stream.end();
            });
          }
        );
      });

      // Listen on local port
      await new Promise<void>((resolve, reject) => {
        server.listen(config.local_port, bindAddress, () => {
          console.log(`[LocalTunnel ${tunnelId}] Listening on ${bindAddress}:${config.local_port}`);
          resolve();
        });

        server.on('error', (err: Error) => {
          reject(err);
        });
      });

      // Create tunnel instance
      const tunnel: Tunnel = {
        id: tunnelId,
        config,
        connection_id: config.connection_id,
        status: 'active',
        created_at: new Date(),
        local_endpoint: `${bindAddress}:${config.local_port}`,
        remote_endpoint: `${config.remote_host}:${config.remote_port}`,
        bytes_transferred: 0,
        connections_count: 0,
        errors_count: 0,
        reconnect_attempts: 0,
        max_reconnect_attempts: config.keep_alive ? 5 : 0,
      };

      this.tunnels.set(tunnelId, tunnel);
      this.servers.set(tunnelId, server);
      this.streams.set(tunnelId, []);

      // Handle server close
      server.on('close', () => {
        console.log(`[LocalTunnel ${tunnelId}] Server closed`);
        const tunnel = this.tunnels.get(tunnelId);
        if (tunnel && config.keep_alive && tunnel.status !== 'closed') {
          tunnel.status = 'failed';
          if (config.auto_restart) {
            this.reconnectTunnel(tunnelId);
          }
        }
      });

      return {
        success: true,
        data: {
          tunnel_id: tunnelId,
          type: 'local',
          local_endpoint: tunnel.local_endpoint,
          remote_endpoint: tunnel.remote_endpoint,
          status: 'active',
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error(`[LocalTunnel] Creation failed:`, error);
      return {
        success: false,
        error: `Failed to create local tunnel: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Create remote port forwarding tunnel: -R [bind_address:]remote_port:local_host:local_port
   * Forwards remote port back to local destination
   */
  async createRemoteTunnel(config: RemoteTunnelConfig): Promise<TunnelResult> {
    const conn = this.connectionManager.getConnection(config.connection_id);
    if (!conn) {
      return {
        success: false,
        error: 'Connection not found',
        timestamp: new Date().toISOString(),
      };
    }

    if (!conn.connected) {
      return {
        success: false,
        error: 'Connection not active',
        timestamp: new Date().toISOString(),
      };
    }

    const tunnelId = this.generateTunnelId();
    const bindAddress = config.bind_address || 'localhost';

    try {
      // Request remote port forwarding
      await new Promise<void>((resolve, reject) => {
        conn.client.forwardIn(
          bindAddress,
          config.remote_port,
          (err: Error | undefined) => {
            if (err) {
              reject(err);
            } else {
              resolve();
            }
          }
        );
      });

      // Create tunnel instance
      const tunnel: Tunnel = {
        id: tunnelId,
        config,
        connection_id: config.connection_id,
        status: 'active',
        created_at: new Date(),
        local_endpoint: `${config.local_host}:${config.local_port}`,
        remote_endpoint: `${bindAddress}:${config.remote_port}`,
        bytes_transferred: 0,
        connections_count: 0,
        errors_count: 0,
        reconnect_attempts: 0,
        max_reconnect_attempts: config.keep_alive ? 5 : 0,
      };

      this.tunnels.set(tunnelId, tunnel);
      this.streams.set(tunnelId, []);

      // Handle incoming connections from remote
      const tcpConnectionHandler = (info: any, accept: () => any, reject: () => void) => {
        // Check if this is for our tunnel
        if (info.destPort !== config.remote_port) {
          return;
        }

        console.log(`[RemoteTunnel ${tunnelId}] Incoming connection from ${info.srcIP}:${info.srcPort}`);
        
        const tunnel = this.tunnels.get(tunnelId);
        if (!tunnel) {
          reject();
          return;
        }

        tunnel.connections_count++;

        const stream = accept();
        
        // Track stream
        const streams = this.streams.get(tunnelId) || [];
        streams.push(stream);
        this.streams.set(tunnelId, streams);

        // Connect to local destination
        const localSocket = net.connect(
          config.local_port,
          config.local_host,
          () => {
            console.log(`[RemoteTunnel ${tunnelId}] Connected to local ${config.local_host}:${config.local_port}`);
          }
        );

        // Monitor traffic
        stream.on('data', (data: Buffer) => {
          tunnel.bytes_transferred += data.length;
        });

        localSocket.on('data', (data: Buffer) => {
          tunnel.bytes_transferred += data.length;
        });

        // Bidirectional pipe
        stream.pipe(localSocket);
        localSocket.pipe(stream);

        stream.on('close', () => {
          localSocket.end();
          const streams = this.streams.get(tunnelId) || [];
          const index = streams.indexOf(stream);
          if (index > -1) {
            streams.splice(index, 1);
          }
        });

        localSocket.on('close', () => {
          stream.end();
        });

        stream.on('error', (err: Error) => {
          console.error(`[RemoteTunnel ${tunnelId}] Stream error:`, err);
          tunnel.errors_count++;
          tunnel.last_error = err.message;
          localSocket.end();
        });

        localSocket.on('error', (err: Error) => {
          console.error(`[RemoteTunnel ${tunnelId}] Local socket error:`, err);
          tunnel.errors_count++;
          tunnel.last_error = err.message;
          stream.end();
        });
      };

      // Register handler
      conn.client.on('tcp connection', tcpConnectionHandler);

      // Store handler reference for cleanup
      (tunnel as any).tcpConnectionHandler = tcpConnectionHandler;

      return {
        success: true,
        data: {
          tunnel_id: tunnelId,
          type: 'remote',
          local_endpoint: tunnel.local_endpoint,
          remote_endpoint: tunnel.remote_endpoint,
          status: 'active',
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error(`[RemoteTunnel] Creation failed:`, error);
      return {
        success: false,
        error: `Failed to create remote tunnel: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Create dynamic SOCKS proxy: -D [bind_address:]socks_port
   * Creates a SOCKS proxy on local port (simplified SOCKS5 implementation)
   */
  async createDynamicTunnel(config: DynamicTunnelConfig): Promise<TunnelResult> {
    const conn = this.connectionManager.getConnection(config.connection_id);
    if (!conn) {
      return {
        success: false,
        error: 'Connection not found',
        timestamp: new Date().toISOString(),
      };
    }

    if (!conn.connected) {
      return {
        success: false,
        error: 'Connection not active',
        timestamp: new Date().toISOString(),
      };
    }

    const tunnelId = this.generateTunnelId();
    const bindAddress = config.bind_address || 'localhost';
    const socksVersion = config.socks_version || 5;

    try {
      // Create SOCKS server (simplified SOCKS5 implementation)
      const server = net.createServer((socket) => {
        console.log(`[DynamicTunnel ${tunnelId}] New SOCKS connection`);

        const tunnel = this.tunnels.get(tunnelId);
        if (tunnel) {
          tunnel.connections_count++;
        }

        let handshakeDone = false;

        socket.once('data', (data: Buffer) => {
          // SOCKS5 handshake: [version, nmethods, methods...]
          if (data[0] === 5) {
            // Send: [version, method] - no authentication
            socket.write(Buffer.from([5, 0]));
            handshakeDone = true;

            socket.once('data', (data: Buffer) => {
              // SOCKS5 request: [version, cmd, reserved, atyp, dst.addr, dst.port]
              const cmd = data[1];
              const atyp = data[3];

              if (cmd !== 1) { // Only support CONNECT (1)
                socket.write(Buffer.from([5, 7, 0, 1, 0, 0, 0, 0, 0, 0])); // Command not supported
                socket.end();
                return;
              }

              let dstAddr: string;
              let dstPort: number;
              let offset = 4;

              // Parse destination address
              if (atyp === 1) { // IPv4
                dstAddr = `${data[offset]}.${data[offset + 1]}.${data[offset + 2]}.${data[offset + 3]}`;
                offset += 4;
              } else if (atyp === 3) { // Domain name
                const len = data[offset];
                offset++;
                dstAddr = data.slice(offset, offset + len).toString();
                offset += len;
              } else {
                socket.write(Buffer.from([5, 8, 0, 1, 0, 0, 0, 0, 0, 0])); // Address type not supported
                socket.end();
                return;
              }

              // Parse destination port
              dstPort = (data[offset] << 8) + data[offset + 1];

              console.log(`[DynamicTunnel ${tunnelId}] SOCKS request to ${dstAddr}:${dstPort}`);

              // Forward through SSH
              conn.client.forwardOut(
                '0.0.0.0',
                0,
                dstAddr,
                dstPort,
                (err: Error | undefined, stream: any) => {
                  if (err) {
                    console.error(`[DynamicTunnel ${tunnelId}] Forward error:`, err);
                    socket.write(Buffer.from([5, 1, 0, 1, 0, 0, 0, 0, 0, 0])); // General failure
                    socket.end();
                    if (tunnel) {
                      tunnel.errors_count++;
                      tunnel.last_error = err.message;
                    }
                    return;
                  }

                  // Track stream
                  const streams = this.streams.get(tunnelId) || [];
                  streams.push(stream);
                  this.streams.set(tunnelId, streams);

                  // Success response
                  socket.write(Buffer.from([5, 0, 0, 1, 0, 0, 0, 0, 0, 0]));

                  // Monitor traffic
                  stream.on('data', (data: Buffer) => {
                    if (tunnel) {
                      tunnel.bytes_transferred += data.length;
                    }
                  });

                  socket.on('data', (data: Buffer) => {
                    if (tunnel) {
                      tunnel.bytes_transferred += data.length;
                    }
                  });

                  // Bidirectional pipe
                  stream.pipe(socket);
                  socket.pipe(stream);

                  stream.on('close', () => {
                    socket.end();
                    const streams = this.streams.get(tunnelId) || [];
                    const index = streams.indexOf(stream);
                    if (index > -1) {
                      streams.splice(index, 1);
                    }
                  });

                  socket.on('close', () => {
                    stream.end();
                  });

                  stream.on('error', (err: Error) => {
                    console.error(`[DynamicTunnel ${tunnelId}] Stream error:`, err);
                    if (tunnel) {
                      tunnel.errors_count++;
                      tunnel.last_error = err.message;
                    }
                    socket.end();
                  });

                  socket.on('error', (err: Error) => {
                    console.error(`[DynamicTunnel ${tunnelId}] Socket error:`, err);
                    stream.end();
                  });
                }
              );
            });
          } else {
            // Unsupported SOCKS version
            socket.end();
          }
        });

        socket.on('error', (err: Error) => {
          console.error(`[DynamicTunnel ${tunnelId}] Socket error:`, err);
        });
      });

      // Listen on SOCKS port
      await new Promise<void>((resolve, reject) => {
        server.listen(config.socks_port, bindAddress, () => {
          console.log(`[DynamicTunnel ${tunnelId}] SOCKS${socksVersion} proxy listening on ${bindAddress}:${config.socks_port}`);
          resolve();
        });

        server.on('error', (err: Error) => {
          reject(err);
        });
      });

      // Create tunnel instance
      const tunnel: Tunnel = {
        id: tunnelId,
        config,
        connection_id: config.connection_id,
        status: 'active',
        created_at: new Date(),
        local_endpoint: `socks${socksVersion}://${bindAddress}:${config.socks_port}`,
        remote_endpoint: 'dynamic',
        bytes_transferred: 0,
        connections_count: 0,
        errors_count: 0,
        reconnect_attempts: 0,
        max_reconnect_attempts: config.keep_alive ? 5 : 0,
      };

      this.tunnels.set(tunnelId, tunnel);
      this.servers.set(tunnelId, server);
      this.streams.set(tunnelId, []);

      // Handle server close
      server.on('close', () => {
        console.log(`[DynamicTunnel ${tunnelId}] Server closed`);
        const tunnel = this.tunnels.get(tunnelId);
        if (tunnel && config.keep_alive && tunnel.status !== 'closed') {
          tunnel.status = 'failed';
          if (config.auto_restart) {
            this.reconnectTunnel(tunnelId);
          }
        }
      });

      return {
        success: true,
        data: {
          tunnel_id: tunnelId,
          type: 'dynamic',
          local_endpoint: tunnel.local_endpoint,
          remote_endpoint: tunnel.remote_endpoint,
          status: 'active',
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      console.error(`[DynamicTunnel] Creation failed:`, error);
      return {
        success: false,
        error: `Failed to create dynamic tunnel: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * List all active tunnels, optionally filtered by connection
   */
  async listTunnels(connection_id?: string): Promise<Tunnel[]> {
    const tunnels = Array.from(this.tunnels.values());
    if (connection_id) {
      return tunnels.filter(t => t.connection_id === connection_id);
    }
    return tunnels;
  }

  /**
   * Close a specific tunnel
   */
  async closeTunnel(tunnel_id: string): Promise<void> {
    const tunnel = this.tunnels.get(tunnel_id);
    if (!tunnel) {
      throw new Error(`Tunnel not found: ${tunnel_id}`);
    }

    console.log(`[TunnelManager] Closing tunnel: ${tunnel_id}`);

    // Close all active streams
    const streams = this.streams.get(tunnel_id) || [];
    streams.forEach(stream => {
      try {
        stream.end();
      } catch (error) {
        console.error(`[TunnelManager] Error closing stream:`, error);
      }
    });
    this.streams.delete(tunnel_id);

    // Close server if exists
    const server = this.servers.get(tunnel_id);
    if (server) {
      server.close();
      this.servers.delete(tunnel_id);
    }

    // Remove TCP connection handler for remote tunnels
    if (tunnel.config.type === 'remote') {
      const conn = this.connectionManager.getConnection(tunnel.connection_id);
      if (conn && (tunnel as any).tcpConnectionHandler) {
        conn.client.removeListener('tcp connection', (tunnel as any).tcpConnectionHandler);
      }
    }

    tunnel.status = 'closed';
    tunnel.closed_at = new Date();
    
    // Remove from active tunnels
    this.tunnels.delete(tunnel_id);

    console.log(`[TunnelManager] Tunnel closed: ${tunnel_id}`);
  }

  /**
   * Get detailed status of a tunnel
   */
  async getTunnelStatus(tunnel_id: string): Promise<TunnelStatus> {
    const tunnel = this.tunnels.get(tunnel_id);
    if (!tunnel) {
      throw new Error(`Tunnel not found: ${tunnel_id}`);
    }

    const uptime = (Date.now() - tunnel.created_at.getTime()) / 1000;
    const streams = this.streams.get(tunnel_id) || [];
    const activeConnections = streams.length;

    return {
      tunnel_id: tunnel.id,
      type: tunnel.config.type,
      status: tunnel.status,
      local_endpoint: tunnel.local_endpoint,
      remote_endpoint: tunnel.remote_endpoint,
      uptime_seconds: uptime,
      last_activity: tunnel.created_at,
      metrics: {
        tunnel_id: tunnel.id,
        uptime_seconds: uptime,
        bytes_sent: Math.floor(tunnel.bytes_transferred / 2), // Approximate
        bytes_received: Math.floor(tunnel.bytes_transferred / 2),
        active_connections: activeConnections,
        total_connections: tunnel.connections_count,
        errors: tunnel.errors_count,
        health: tunnel.errors_count > 5 ? 'failed' : 
                tunnel.errors_count > 2 ? 'degraded' : 'healthy',
      },
    };
  }

  /**
   * Monitor tunnel and get current metrics
   */
  async monitorTunnel(tunnel_id: string): Promise<TunnelMetrics> {
    const status = await this.getTunnelStatus(tunnel_id);
    return status.metrics;
  }

  /**
   * Auto-reconnect tunnel with exponential backoff
   */
  private async reconnectTunnel(tunnelId: string): Promise<void> {
    const tunnel = this.tunnels.get(tunnelId);
    if (!tunnel) {
      console.log(`[TunnelManager] Tunnel not found for reconnection: ${tunnelId}`);
      return;
    }

    tunnel.reconnect_attempts++;

    // Check max reconnect attempts
    if (tunnel.max_reconnect_attempts && 
        tunnel.reconnect_attempts > tunnel.max_reconnect_attempts) {
      console.log(`[TunnelManager] Max reconnect attempts reached for tunnel: ${tunnelId}`);
      tunnel.status = 'failed';
      return;
    }

    // Exponential backoff: min(1000 * 2^(attempts-1), 30000)
    const delay = Math.min(1000 * Math.pow(2, tunnel.reconnect_attempts - 1), 30000);
    console.log(`[TunnelManager] Reconnecting tunnel ${tunnelId} in ${delay}ms (attempt ${tunnel.reconnect_attempts})`);

    await new Promise(resolve => setTimeout(resolve, delay));

    try {
      // Clean up old resources
      const server = this.servers.get(tunnelId);
      if (server) {
        server.close();
        this.servers.delete(tunnelId);
      }

      const streams = this.streams.get(tunnelId) || [];
      streams.forEach(stream => {
        try {
          stream.end();
        } catch (error) {
          // Ignore errors during cleanup
        }
      });
      this.streams.delete(tunnelId);

      // Remove from tunnels map before recreating
      this.tunnels.delete(tunnelId);

      // Recreate tunnel based on type
      let result: TunnelResult;
      
      if (tunnel.config.type === 'local') {
        result = await this.createLocalTunnel(tunnel.config as LocalTunnelConfig);
      } else if (tunnel.config.type === 'remote') {
        result = await this.createRemoteTunnel(tunnel.config as RemoteTunnelConfig);
      } else {
        result = await this.createDynamicTunnel(tunnel.config as DynamicTunnelConfig);
      }

      if (result.success) {
        console.log(`[TunnelManager] Tunnel ${tunnelId} reconnected successfully`);
        // Reset reconnect attempts on success
        const newTunnel = this.tunnels.get(result.data!.tunnel_id);
        if (newTunnel) {
          newTunnel.reconnect_attempts = 0;
        }
      } else {
        throw new Error(result.error || 'Reconnection failed');
      }
    } catch (error: any) {
      console.error(`[TunnelManager] Reconnection failed for ${tunnelId}:`, error);
      // Restore tunnel to map with failed status
      tunnel.status = 'failed';
      tunnel.errors_count++;
      tunnel.last_error = error.message;
      this.tunnels.set(tunnelId, tunnel);

      // Try again if under max attempts
      if (!tunnel.max_reconnect_attempts || 
          tunnel.reconnect_attempts < tunnel.max_reconnect_attempts) {
        await this.reconnectTunnel(tunnelId);
      }
    }
  }

  /**
   * Generate unique tunnel ID
   */
  private generateTunnelId(): string {
    return `tunnel-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Cleanup all tunnels
   */
  async cleanup(): Promise<void> {
    console.log(`[TunnelManager] Cleaning up ${this.tunnels.size} tunnel(s)`);
    
    for (const tunnelId of Array.from(this.tunnels.keys())) {
      try {
        await this.closeTunnel(tunnelId);
      } catch (error) {
        console.error(`[TunnelManager] Error closing tunnel ${tunnelId}:`, error);
      }
    }

    console.log(`[TunnelManager] Cleanup complete`);
  }
}

/**
 * MCP tool schema for SSH tunneling
 */
export const sshTunnelSchema = {
  name: 'ssh_tunnel',
  description: 'Create SSH tunnels (local forward, remote forward, or dynamic SOCKS proxy)',
  inputSchema: {
    type: 'object',
    properties: {
      type: {
        type: 'string',
        enum: ['local', 'remote', 'dynamic'],
        description: 'Tunnel type: local (forward local port to remote), remote (forward remote port to local), or dynamic (SOCKS proxy)',
      },
      connection_id: {
        type: 'string',
        description: 'SSH connection ID to use for tunneling',
      },
      local_port: {
        type: 'number',
        description: 'Local port (for local and dynamic tunnels)',
      },
      remote_host: {
        type: 'string',
        description: 'Remote destination host (for local tunnels)',
      },
      remote_port: {
        type: 'number',
        description: 'Remote destination port (for local and remote tunnels)',
      },
      local_host: {
        type: 'string',
        description: 'Local destination host (for remote tunnels, default: localhost)',
      },
      socks_port: {
        type: 'number',
        description: 'SOCKS proxy port (for dynamic tunnels)',
      },
      socks_version: {
        type: 'number',
        enum: [4, 5],
        description: 'SOCKS version (default: 5)',
      },
      bind_address: {
        type: 'string',
        description: 'Bind address (default: localhost)',
      },
      keep_alive: {
        type: 'boolean',
        description: 'Keep tunnel alive and auto-reconnect on failure',
      },
      auto_restart: {
        type: 'boolean',
        description: 'Automatically restart tunnel on errors',
      },
      timeout_seconds: {
        type: 'number',
        description: 'Connection timeout in seconds',
      },
    },
    required: ['type', 'connection_id'],
  },
};