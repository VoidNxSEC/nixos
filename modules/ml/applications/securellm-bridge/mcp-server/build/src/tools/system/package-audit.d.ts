/**
 * System Package Audit Tool
 * Audit NixOS packages for updates, vulnerabilities, and orphans
 */
import type { SystemPackageAuditArgs, ToolResult } from '../../types/extended-tools.js';
export declare class SystemPackageAuditTool {
    private projectRoot;
    constructor(projectRoot: string);
    execute(args: SystemPackageAuditArgs): Promise<ToolResult>;
    private checkUpdates;
    private checkVulnerabilities;
    private checkOrphans;
}
export declare const packageAuditSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            check_updates: {
                type: string;
                description: string;
            };
            check_vulnerabilities: {
                type: string;
                description: string;
            };
            check_orphans: {
                type: string;
                description: string;
            };
        };
    };
};
//# sourceMappingURL=package-audit.d.ts.map