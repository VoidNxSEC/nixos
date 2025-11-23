/**
 * System Health Check Tool
 * Comprehensive system health monitoring
 */
import type { SystemHealthCheckArgs, SystemHealthResult } from '../../types/extended-tools.js';
export declare class SystemHealthCheckTool {
    private projectRoot;
    constructor(projectRoot: string);
    execute(args: SystemHealthCheckArgs): Promise<SystemHealthResult>;
    private getCPUTemp;
    private checkCriticalServices;
}
export declare const healthCheckSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            detailed: {
                type: string;
                description: string;
            };
            components: {
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
//# sourceMappingURL=health-check.d.ts.map