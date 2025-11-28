/**
 * SSH Connection Manager
 * Manages SSH connections with security controls
 */

// @ts-ignore - ssh2 types are in @types/ssh2
import { Client } from 'ssh2';
import * as fs from 'fs/promises';
import type { SSHConnectArgs, SSHConnectionResult } from '../../types/extended-tools.js';

interface Connection {
  id: string;
  client: Client;
  host: string;
  username: string;
  connected: boolean;
  created: Date;
}

export class SSHConnectionManager {
  private connections: Map<string, Connection> = new Map();
  private allowedHosts: string[];

  constructor(allowedHosts: string[] = ['localhost', '127.0.0.1']) {
    this.allowedHosts = allowedHosts;
  }

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
      const connectionId = `ssh-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

      const connectPromise = new Promise<SSHConnectionResult>((resolve, reject) => {
        client.on('ready', () => {
          const conn: Connection = {
            id: connectionId,
            client,
            host,
            username,
            connected: true,
            created: new Date(),
          };
          this.connections.set(connectionId, conn);

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
          reject(new Error(`SSH connection failed: ${err.message}`));
        });

        // Configure connection
        const config: any = {
          host,
          port,
          username,
          readyTimeout: 30000,
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
      return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      };
    }
  }

  getConnection(connectionId: string): Connection | undefined {
    return this.connections.get(connectionId);
  }

  disconnect(connectionId: string): boolean {
    const conn = this.connections.get(connectionId);
    if (conn) {
      conn.client.end();
      this.connections.delete(connectionId);
      return true;
    }
    return false;
  }

  disconnectAll(): void {
    for (const conn of this.connections.values()) {
      conn.client.end();
    }
    this.connections.clear();
  }

  listConnections(): Array<{ id: string; host: string; username: string; uptime: number }> {
    return Array.from(this.connections.values()).map(conn => ({
      id: conn.id,
      host: conn.host,
      username: conn.username,
      uptime: Date.now() - conn.created.getTime(),
    }));
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