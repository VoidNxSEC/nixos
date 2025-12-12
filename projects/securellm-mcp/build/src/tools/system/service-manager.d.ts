/**
 * System Service Manager Tool
 * Manage systemd services
 */
import type { SystemServiceManagerArgs, ToolResult } from '../../types/extended-tools.js';
export declare class SystemServiceManagerTool {
    private allowedServices;
    execute(args: SystemServiceManagerArgs): Promise<ToolResult>;
    private parseStatus;
}
export declare const serviceManagerSchema: {
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
            service: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=service-manager.d.ts.map