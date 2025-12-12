/**
 * SSH Tools - Remote Access and Maintenance
 * All SSH-related tools for secure remote operations
 */

// @ts-ignore
import { Client } from 'ssh2';
import { SSHConnectionManager } from './connection-manager.js';
import type {
  SSHExecuteArgs,
  SSHFileTransferArgs,
  SSHMaintenanceCheckArgs,
  ToolResult,
} from '../../types/extended-tools.js';

export { SSHConnectionManager, sshConnectSchema } from './connection-manager.js';

// Global connection manager instance
const connectionManager = new SSHConnectionManager();

/**
 * SSH Execute Tool
 */
export class SSHExecuteTool {
  private allowedCommands = [
    'ls', 'cat', 'grep', 'find', 'df', 'du', 'free', 'uptime',
    'systemctl status', 'journalctl', 'ps aux', 'netstat', 'ss'
  ];

  async execute(args: SSHExecuteArgs): Promise<ToolResult> {
    const { connection_id, command, timeout_seconds = 30, sudo = false } = args;

    const conn = connectionManager.getConnection(connection_id);
    if (!conn || !conn.connected) {
      return {
        success: false,
        error: 'Connection not found or not connected',
        timestamp: new Date().toISOString(),
      };
    }

    // Security: whitelist commands
    const isAllowed = this.allowedCommands.some(allowed => command.startsWith(allowed));
    if (!isAllowed && !sudo) {
      return {
        success: false,
        error: `Command '${command}' not in whitelist`,
        warnings: ['Only whitelisted commands are allowed for security'],
        timestamp: new Date().toISOString(),
      };
    }

    return new Promise((resolve) => {
      const fullCommand = sudo ? `sudo ${command}` : command;
      let stdout = '';
      let stderr = '';

      conn.client.exec(fullCommand, (err: any, stream: any) => {
        if (err) {
          resolve({
            success: false,
            error: `Execution failed: ${err.message}`,
            timestamp: new Date().toISOString(),
          });
          return;
        }

        stream.on('data', (data: Buffer) => {
          stdout += data.toString();
        });

        stream.stderr.on('data', (data: Buffer) => {
          stderr += data.toString();
        });

        stream.on('close', (code: number) => {
          resolve({
            success: code === 0,
            data: {
              command: fullCommand,
              exit_code: code,
              stdout,
              stderr,
              connection_id,
            },
            timestamp: new Date().toISOString(),
          });
        });
      });
    });
  }
}

/**
 * SSH File Transfer Tool (SFTP)
 */
export class SSHFileTransferTool {
  async execute(args: SSHFileTransferArgs): Promise<ToolResult> {
    const { connection_id, action, local_path, remote_path } = args;

    const conn = connectionManager.getConnection(connection_id);
    if (!conn || !conn.connected) {
      return {
        success: false,
        error: 'Connection not found or not connected',
        timestamp: new Date().toISOString(),
      };
    }

    return new Promise((resolve) => {
      conn.client.sftp((err: any, sftp: any) => {
        if (err) {
          resolve({
            success: false,
            error: `SFTP failed: ${err.message}`,
            timestamp: new Date().toISOString(),
          });
          return;
        }

        if (action === 'upload') {
          sftp.fastPut(local_path, remote_path, (err: any) => {
            sftp.end();
            if (err) {
              resolve({
                success: false,
                error: `Upload failed: ${err.message}`,
                timestamp: new Date().toISOString(),
              });
            } else {
              resolve({
                success: true,
                data: {
                  action: 'upload',
                  local_path,
                  remote_path,
                  connection_id,
                },
                timestamp: new Date().toISOString(),
              });
            }
          });
        } else {
          sftp.fastGet(remote_path, local_path, (err: any) => {
            sftp.end();
            if (err) {
              resolve({
                success: false,
                error: `Download failed: ${err.message}`,
                timestamp: new Date().toISOString(),
              });
            } else {
              resolve({
                success: true,
                data: {
                  action: 'download',
                  local_path,
                  remote_path,
                  connection_id,
                },
                timestamp: new Date().toISOString(),
              });
            }
          });
        }
      });
    });
  }
}

/**
 * SSH Maintenance Check Tool
 */
export class SSHMaintenanceCheckTool {
  async execute(args: SSHMaintenanceCheckArgs): Promise<ToolResult> {
    const { connection_id, checks } = args;

    const conn = connectionManager.getConnection(connection_id);
    if (!conn || !conn.connected) {
      return {
        success: false,
        error: 'Connection not found or not connected',
        timestamp: new Date().toISOString(),
      };
    }

    const results: any = {};

    for (const check of checks) {
      try {
        results[check] = await this.runCheck(conn.client, check);
      } catch (error: any) {
        results[check] = { error: error.message };
      }
    }

    return {
      success: true,
      data: {
        connection_id,
        checks: results,
        host: conn.host,
      },
      timestamp: new Date().toISOString(),
    };
  }

  private runCheck(client: Client, check: string): Promise<any> {
    return new Promise((resolve, reject) => {
      let command = '';
      switch (check) {
        case 'disk':
          command = 'df -h';
          break;
        case 'services':
          command = 'systemctl list-units --state=failed';
          break;
        case 'updates':
          command = 'apt list --upgradable 2>/dev/null || yum check-update || true';
          break;
        case 'security':
          command = 'last -n 10';
          break;
        case 'logs':
          command = 'journalctl -p err -n 20 --no-pager';
          break;
      }

      client.exec(command, (err: any, stream: any) => {
        if (err) {
          reject(err);
          return;
        }

        let output = '';
        stream.on('data', (data: Buffer) => {
          output += data.toString();
        });

        stream.on('close', () => {
          resolve({ check, output, status: 'completed' });
        });
      });
    });
  }
}

// Export schemas
export const sshExecuteSchema = {
  name: "ssh_execute",
  description: "Execute command on remote server via SSH",
  inputSchema: {
    type: "object",
    properties: {
      connection_id: { type: "string", description: "SSH connection ID" },
      command: { type: "string", description: "Command to execute" },
      timeout_seconds: { type: "number", description: "Timeout in seconds (default: 30)" },
      sudo: { type: "boolean", description: "Execute with sudo (default: false)" },
    },
    required: ["connection_id", "command"],
  },
};

export const sshFileTransferSchema = {
  name: "ssh_file_transfer",
  description: "Transfer files via SFTP (upload/download)",
  inputSchema: {
    type: "object",
    properties: {
      connection_id: { type: "string", description: "SSH connection ID" },
      action: { type: "string", enum: ["upload", "download"] },
      local_path: { type: "string", description: "Local file path" },
      remote_path: { type: "string", description: "Remote file path" },
    },
    required: ["connection_id", "action", "local_path", "remote_path"],
  },
};

export const sshMaintenanceCheckSchema = {
  name: "ssh_maintenance_check",
  description: "Run maintenance checks on remote server",
  inputSchema: {
    type: "object",
    properties: {
      connection_id: { type: "string", description: "SSH connection ID" },
      checks: {
        type: "array",
        items: { type: "string", enum: ["disk", "services", "updates", "security", "logs"] },
        description: "Checks to perform",
      },
    },
    required: ["connection_id", "checks"],
  },
};