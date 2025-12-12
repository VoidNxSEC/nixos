/**
 * System Package Audit Tool
 * Audit NixOS packages for updates, vulnerabilities, and orphans
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import type { SystemPackageAuditArgs, ToolResult } from '../../types/extended-tools.js';

const execAsync = promisify(exec);

export class SystemPackageAuditTool {
  private projectRoot: string;

  constructor(projectRoot: string) {
    this.projectRoot = projectRoot;
  }

  async execute(args: SystemPackageAuditArgs): Promise<ToolResult> {
    const checkUpdates = args.check_updates ?? true;
    const checkVulnerabilities = args.check_vulnerabilities ?? true;
    const checkOrphans = args.check_orphans ?? true;

    try {
      const results: any = {};

      // Check for available updates (flake)
      if (checkUpdates) {
        results.updates = await this.checkUpdates();
      }

      // Check for known vulnerabilities (via nix-community advisory)
      if (checkVulnerabilities) {
        results.vulnerabilities = await this.checkVulnerabilities();
      }

      // Check for orphaned packages (not referenced in flake)
      if (checkOrphans) {
        results.orphans = await this.checkOrphans();
      }

      const totalIssues = 
        (results.updates?.count || 0) +
        (results.vulnerabilities?.count || 0) +
        (results.orphans?.count || 0);

      return {
        success: true,
        data: results,
        warnings: totalIssues > 0 ? [`Found ${totalIssues} total issues`] : undefined,
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      return {
        success: false,
        error: `Package audit failed: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  private async checkUpdates(): Promise<any> {
    try {
      const { stdout } = await execAsync(`cd ${this.projectRoot} && nix flake update --dry-run 2>&1 || true`);
      
      // Parse output for package updates
      const updates = stdout.match(/Updated .+:/g) || [];
      
      return {
        count: updates.length,
        updates: updates.slice(0, 20), // Limit to 20
        message: updates.length > 0 ? 'Updates available' : 'System up to date',
      };
    } catch (error: any) {
      return {
        count: 0,
        error: error.message,
      };
    }
  }

  private async checkVulnerabilities(): Promise<any> {
    try {
      // Check installed packages against known vulnerabilities
      // This is a simplified check - in production would use proper vulnerability database
      const { stdout } = await execAsync(`nix-store -q --references /run/current-system | wc -l`);
      const packageCount = parseInt(stdout.trim());

      return {
        count: 0, // Simplified - would need proper vulnerability database
        total_packages: packageCount,
        message: 'Vulnerability scanning not fully implemented',
      };
    } catch (error: any) {
      return {
        count: 0,
        error: error.message,
      };
    }
  }

  private async checkOrphans(): Promise<any> {
    try {
      // Find packages not referenced in current system
      const { stdout } = await execAsync(`nix-store --gc --print-dead | wc -l`);
      const deadPaths = parseInt(stdout.trim());

      return {
        count: deadPaths,
        message: deadPaths > 0 ? `${deadPaths} orphaned store paths` : 'No orphans found',
        recommendation: deadPaths > 0 ? 'Run: nix-collect-garbage -d' : null,
      };
    } catch (error: any) {
      return {
        count: 0,
        error: error.message,
      };
    }
  }
}

export const packageAuditSchema = {
  name: "system_package_audit",
  description: "Audit NixOS packages for updates, vulnerabilities, and orphans",
  inputSchema: {
    type: "object",
    properties: {
      check_updates: { type: "boolean", description: "Check for available updates (default: true)" },
      check_vulnerabilities: { type: "boolean", description: "Check for known vulnerabilities (default: true)" },
      check_orphans: { type: "boolean", description: "Check for orphaned packages (default: true)" },
    },
  },
};