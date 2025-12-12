/**
 * SSH Connection Manager
 * Manages SSH connections with security controls
 */
import { Client } from 'ssh2';
import type { SSHConnectArgs, SSHConnectionResult } from '../../types/extended-tools.js';
interface Connection {
    id: string;
    client: Client;
    host: string;
    username: string;
    connected: boolean;
    created: Date;
    created_at?: Date;
    last_used?: Date;
    error_count?: number;
    config?: any;
    health_status?: string;
    bytes_sent?: number;
    bytes_received?: number;
    commands_executed?: number;
}
export declare class SSHConnectionManager {
    private connections;
    private allowedHosts;
    constructor(allowedHosts?: string[]);
    connect(args: SSHConnectArgs): Promise<SSHConnectionResult>;
    getConnection(connectionId: string): Connection | undefined;
    getOrCreateConnection(args: SSHConnectArgs): Promise<Connection>;
    disconnect(connectionId: string): boolean;
    disconnectAll(): void;
    listConnections(): Array<{
        id: string;
        host: string;
        username: string;
        uptime: number;
    }>;
}
export declare const sshConnectSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            host: {
                type: string;
                description: string;
            };
            port: {
                type: string;
                description: string;
            };
            username: {
                type: string;
                description: string;
            };
            auth_method: {
                type: string;
                enum: string[];
            };
            key_path: {
                type: string;
                description: string;
            };
            password: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export {};
//# sourceMappingURL=connection-manager.d.ts.map