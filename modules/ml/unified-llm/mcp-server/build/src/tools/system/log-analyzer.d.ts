/**
 * System Log Analyzer Tool
 * Analyze systemd journal logs with intelligent filtering
 */
import type { SystemLogAnalyzerArgs, ToolResult } from '../../types/extended-tools.js';
export declare class SystemLogAnalyzerTool {
    execute(args: SystemLogAnalyzerArgs): Promise<ToolResult>;
}
export declare const logAnalyzerSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            service: {
                type: string;
                description: string;
            };
            since: {
                type: string;
                description: string;
            };
            until: {
                type: string;
                description: string;
            };
            level: {
                type: string;
                enum: string[];
            };
            lines: {
                type: string;
                description: string;
            };
            pattern: {
                type: string;
                description: string;
            };
        };
    };
};
//# sourceMappingURL=log-analyzer.d.ts.map