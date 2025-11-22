/**
 * System Service Manager Tool
 * Manage systemd services
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import type { SystemServiceManagerArgs, ToolResult } from '../../types/extended-tools.js';

const execAsync = promisify(exec);

export class SystemServiceManagerTool {
  private allowedServices = [
    'sshd', 'nginx', 'docker', 'postgresql', 'redis',
    'NetworkManager', 'systemd-resolved', 'cups'
  ];

  async execute(args: SystemServiceManagerArgs): Promise<ToolResult> {
    const { action, service } = args;

    // Security: whitelist services
    if (!this.allowedServices.includes(service)) {
      return {
        success: false,
        error: `Service '${service}' not in whitelist`,
        timestamp: new Date().toISOString(),
      };
    }

    try {
      let cmd = '';
      switch (action) {
        case 'start':
        case 'stop':
        case 'restart':
          cmd = `sudo systemctl ${action} ${service}`;
          break;
        case 'enable':
        case 'disable':
          cmd = `sudo systemctl ${action} ${service}`;
          break;
        case 'status':
          cmd = `systemctl status ${service} --no-pager`;
          break;
      }

      const { stdout, stderr } = await execAsync(cmd);

      return {
        success: true,
        data: {
          service,
          action,
          output: stdout,
          status: action === 'status' ? this.parseStatus(stdout) : 'completed',
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error: any) {
      return {
        success: false,
        error: `Service ${action} failed: ${error.message}`,
        timestamp: new Date().toISOString(),
      };
    }
  }

  private parseStatus(output: string): string {
    if (output.includes('Active: active (running)')) return 'running';
    if (output.includes('Active: inactive')) return 'stopped';
    if (output.includes('Active: failed')) return 'failed';
    return 'unknown';
  }
}

export const serviceManagerSchema = {
  name: "system_service_manager",
  description: "Manage systemd services (start, stop, restart, enable, disable, status)",
  inputSchema: {
    type: "object",
    properties: {
      action: {
        type: "string",
        enum: ["start", "stop", "restart", "status", "enable", "disable"],
        description: "Action to perform",
      },
      service: {
        type: "string",
        description: "Service name (whitelisted services only)",
      },
    },
    required: ["action", "service"],
  },
};