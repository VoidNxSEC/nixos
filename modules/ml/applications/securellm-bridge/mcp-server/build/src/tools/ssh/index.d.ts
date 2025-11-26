/**
 * SSH Tools - Remote Access and Maintenance
 * All SSH-related tools for secure remote operations
 */
import type { SSHExecuteArgs, SSHFileTransferArgs, SSHMaintenanceCheckArgs, ToolResult } from '../../types/extended-tools.js';
export { SSHConnectionManager, sshConnectSchema } from './connection-manager.js';
/**
 * SSH Execute Tool
 */
export declare class SSHExecuteTool {
    private allowedCommands;
    execute(args: SSHExecuteArgs): Promise<ToolResult>;
}
/**
 * SSH File Transfer Tool (SFTP)
 */
export declare class SSHFileTransferTool {
    execute(args: SSHFileTransferArgs): Promise<ToolResult>;
}
/**
 * SSH Maintenance Check Tool
 */
export declare class SSHMaintenanceCheckTool {
    execute(args: SSHMaintenanceCheckArgs): Promise<ToolResult>;
    private runCheck;
}
export declare const sshExecuteSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            connection_id: {
                type: string;
                description: string;
            };
            command: {
                type: string;
                description: string;
            };
            timeout_seconds: {
                type: string;
                description: string;
            };
            sudo: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const sshFileTransferSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            connection_id: {
                type: string;
                description: string;
            };
            action: {
                type: string;
                enum: string[];
            };
            local_path: {
                type: string;
                description: string;
            };
            remote_path: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const sshMaintenanceCheckSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            connection_id: {
                type: string;
                description: string;
            };
            checks: {
                type: string;
                items: {
                    type: string;
                    enum: string[];
                };
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=index.d.ts.map