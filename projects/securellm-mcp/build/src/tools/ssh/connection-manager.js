/**
 * SSH Connection Manager
 * Manages SSH connections with security controls
 */
// @ts-ignore - ssh2 types are in @types/ssh2
import { Client } from 'ssh2';
import * as fs from 'fs/promises';
export class SSHConnectionManager {
    connections = new Map();
    allowedHosts;
    constructor(allowedHosts = ['localhost', '127.0.0.1']) {
        this.allowedHosts = allowedHosts;
    }
    async connect(args) {
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
            const connectPromise = new Promise((resolve, reject) => {
                client.on('ready', () => {
                    const conn = {
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
                client.on('error', (err) => {
                    reject(new Error(`SSH connection failed: ${err.message}`));
                });
                // Configure connection
                const config = {
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
                }
                else if (auth_method === 'password' && password) {
                    config.password = password;
                    client.connect(config);
                }
                else {
                    reject(new Error('Invalid authentication method or missing credentials'));
                }
            });
            return await connectPromise;
        }
        catch (error) {
            return {
                success: false,
                error: error.message,
                timestamp: new Date().toISOString(),
            };
        }
    }
    getConnection(connectionId) {
        return this.connections.get(connectionId);
    }
    async getOrCreateConnection(args) {
        // Try to find existing connection
        const existing = Array.from(this.connections.values()).find(conn => conn.host === args.host && conn.username === args.username && conn.connected);
        if (existing) {
            return existing;
        }
        // Create new connection
        const result = await this.connect(args);
        if (!result.success || !result.data) {
            throw new Error(result.error || 'Failed to create connection');
        }
        const connection = this.connections.get(result.data.connection_id);
        if (!connection) {
            throw new Error('Connection created but not found in map');
        }
        return connection;
    }
    disconnect(connectionId) {
        const conn = this.connections.get(connectionId);
        if (conn) {
            conn.client.end();
            this.connections.delete(connectionId);
            return true;
        }
        return false;
    }
    disconnectAll() {
        for (const conn of this.connections.values()) {
            conn.client.end();
        }
        this.connections.clear();
    }
    listConnections() {
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
//# sourceMappingURL=connection-manager.js.map