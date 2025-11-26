/**
 * System Resource Monitor Tool
 * Monitor system resources over time
 */
import type { SystemResourceMonitorArgs, ToolResult } from '../../types/extended-tools.js';
export declare class SystemResourceMonitorTool {
    execute(args: SystemResourceMonitorArgs): Promise<ToolResult>;
}
export declare const resourceMonitorSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            duration_seconds: {
                type: string;
                description: string;
            };
            interval_seconds: {
                type: string;
                description: string;
            };
            resources: {
                type: string;
                items: {
                    type: string;
                    enum: string[];
                };
                description: string;
            };
        };
    };
};
//# sourceMappingURL=resource-monitor.d.ts.map