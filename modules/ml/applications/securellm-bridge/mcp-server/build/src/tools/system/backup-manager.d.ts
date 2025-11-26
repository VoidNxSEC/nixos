/**
 * System Backup Manager Tool
 * Manage system backups (simplified implementation)
 */
import type { SystemBackupManagerArgs, ToolResult } from '../../types/extended-tools.js';
export declare class SystemBackupManagerTool {
    private backupRoot;
    constructor(backupRoot?: string);
    execute(args: SystemBackupManagerArgs): Promise<ToolResult>;
    private createBackup;
    private listBackups;
    private restoreBackup;
    private verifyBackup;
}
export declare const backupManagerSchema: {
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
            paths: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            backup_id: {
                type: string;
                description: string;
            };
            destination: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=backup-manager.d.ts.map