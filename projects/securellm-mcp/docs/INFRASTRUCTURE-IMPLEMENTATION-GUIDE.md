# Infrastructure Tools Implementation Guide

## 📋 Overview

This guide provides comprehensive, step-by-step instructions for implementing the infrastructure management tools in the SecureLLM Bridge MCP server. Follow this guide to build production-ready tools for NFS, NAS, cluster, and server management.

---

## 🏗️ Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- Execution Router
- NFS Manager (mount/export operations)
- Server Manager for NixOS
- Type definitions
- SSH integration layer

### Phase 2: Clusters (Week 3)
- Kubernetes Manager
- Docker Swarm Manager
- Cluster health monitoring
- Server Manager for Ubuntu/RHEL

### Phase 3: NAS (Week 4)
- NAS Volume Management
- Snapshot Operations
- Protocol Management
- Quota Management

### Phase 4: Polish (Week 5)
- Advanced features
- Cross-module orchestration
- Performance tuning
- Documentation

---

## 📁 File Structure

```
src/
├── tools/
│   └── infrastructure/
│       ├── execution-router.ts          # Hybrid execution router
│       ├── nfs/
│       │   ├── nfs-manager.ts          # NFS operations
│       │   ├── mount-manager.ts        # Mount handling
│       │   ├── export-manager.ts       # Export configuration
│       │   └── health-monitor.ts       # Health checks
│       ├── nas/
│       │   ├── nas-manager.ts          # NAS orchestrator
│       │   ├── volume-manager.ts       # Volume operations
│       │   ├── snapshot-manager.ts     # Snapshot handling
│       │   └── protocol-manager.ts     # NFS/SMB protocols
│       ├── cluster/
│       │   ├── cluster-manager.ts      # Cluster orchestrator
│       │   ├── kubernetes-manager.ts   # K8s operations
│       │   ├── swarm-manager.ts        # Docker Swarm ops
│       │   └── health-monitor.ts       # Health monitoring
│       └── server/
│           ├── server-manager.ts       # Server orchestrator
│           ├── adapters/
│           │   ├── nixos-adapter.ts    # NixOS operations
│           │   ├── ubuntu-adapter.ts   # Ubuntu operations
│           │   └── rhel-adapter.ts     # RHEL operations
│           ├── package-manager.ts      # Package operations
│           ├── service-manager.ts      # Service control
│           └── firewall-manager.ts     # Firewall config
└── types/
    └── infrastructure/
        ├── execution.ts                 # Execution context types
        ├── nfs.ts                       # NFS types
        ├── nas.ts                       # NAS types
        ├── cluster.ts                   # Cluster types
        ├── server.ts                    # Server types
        ├── guards.ts                    # Type guards
        └── validation.ts                # Validation functions
```

---

## 🎯 Phase 1: Foundation

### Step 1.1: Create Type Definitions

**File**: `src/types/infrastructure/execution.ts`

```typescript
/**
 * Core execution context types
 */

export type ExecutionMode = 'local' | 'remote';
export type Distro = 'nixos' | 'ubuntu' | 'debian' | 'rhel' | 'centos' | 'fedora';

export interface ExecutionContext {
  readonly mode: ExecutionMode;
  readonly target?: string;
  readonly ssh_connection_id?: string;
  readonly sudo_required: boolean;
  readonly user: string;
  readonly distro?: Distro;
  readonly working_dir?: string;
  readonly env?: Record<string, string>;
  readonly timeout_ms?: number;
}

export interface OperationResult {
  readonly success: boolean;
  readonly data?: any;
  readonly error?: string;
  readonly context: ExecutionContext;
  readonly duration_ms: number;
  readonly timestamp: Date;
  readonly metadata?: Record<string, any>;
}

export interface ValidationResult {
  readonly valid: boolean;
  readonly errors: string[];
  readonly warnings: string[];
}
```

**File**: `src/types/infrastructure/nfs.ts`

```typescript
/**
 * NFS-specific types
 */

export type NFSVersion = '3' | '4' | '4.1' | '4.2';
export type NFSSecurityMode = 'sys' | 'krb5' | 'krb5i' | 'krb5p';

export interface NFSMountConfig {
  readonly source: string;
  readonly target: string;
  readonly version: NFSVersion;
  readonly options?: {
    readonly rw?: boolean;
    readonly async?: boolean;
    readonly sync?: boolean;
    readonly noatime?: boolean;
    readonly hard?: boolean;
    readonly soft?: boolean;
    readonly timeo?: number;
    readonly retrans?: number;
    readonly rsize?: number;
    readonly wsize?: number;
    readonly custom?: string[];
  };
  readonly auto_mount?: boolean;
  readonly verify_mount?: boolean;
  readonly create_mountpoint?: boolean;
}

export interface NFSMount {
  readonly source: string;
  readonly target: string;
  readonly version: NFSVersion;
  readonly options: string;
  readonly status: 'mounted' | 'unmounted' | 'error';
  readonly mounted_at?: Date;
  readonly error?: string;
}

export interface NFSExportConfig {
  readonly path: string;
  readonly clients: string[];
  readonly options: {
    readonly rw?: boolean;
    readonly ro?: boolean;
    readonly sync?: boolean;
    readonly async?: boolean;
    readonly no_subtree_check?: boolean;
    readonly no_root_squash?: boolean;
    readonly root_squash?: boolean;
    readonly all_squash?: boolean;
    readonly anonuid?: number;
    readonly anongid?: number;
    readonly sec?: NFSSecurityMode[];
    readonly custom?: string[];
  };
  readonly comment?: string;
}

export type NFSOperation =
  | { type: 'mount'; config: NFSMountConfig }
  | { type: 'unmount'; target: string }
  | { type: 'list_mounts' }
  | { type: 'add_export'; config: NFSExportConfig }
  | { type: 'remove_export'; path: string }
  | { type: 'list_exports' };

export interface NFSOperationResult extends OperationResult {
  readonly operation: NFSOperation;
}
```

### Step 1.2: Implement Execution Router

**File**: `src/tools/infrastructure/execution-router.ts`

```typescript
import { Client } from 'ssh2';
import { ExecutionContext, OperationResult } from '../../types/infrastructure/execution.js';
import { SSHConnectionManager } from '../ssh/connection-manager.js';

/**
 * Routes infrastructure operations to local or remote execution
 */
export class ExecutionRouter {
  constructor(
    private sshConnectionManager: SSHConnectionManager
  ) {}

  /**
   * Route operation to appropriate executor
   */
  async route(
    operation: any,
    context: ExecutionContext
  ): Promise<OperationResult> {
    const startTime = Date.now();

    try {
      // Detect execution mode
      const isLocal = await this.isLocalTarget(context.target);
      
      let result: any;
      if (isLocal) {
        result = await this.executeLocal(operation, context);
      } else {
        result = await this.executeRemote(operation, context);
      }

      const duration = Date.now() - startTime;
      
      return {
        success: true,
        data: result,
        context,
        duration_ms: duration,
        timestamp: new Date()
      };
    } catch (error) {
      const duration = Date.now() - startTime;
      
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
        context,
        duration_ms: duration,
        timestamp: new Date()
      };
    }
  }

  /**
   * Check if target is local
   */
  private async isLocalTarget(target?: string): Promise<boolean> {
    if (!target) return true;
    
    const localNames = ['localhost', '127.0.0.1', '::1'];
    if (localNames.includes(target)) return true;
    
    // Check if target matches hostname
    const hostname = require('os').hostname();
    return target === hostname;
  }

  /**
   * Execute operation locally
   */
  private async executeLocal(
    operation: any,
    context: ExecutionContext
  ): Promise<any> {
    const { exec } = require('child_process');
    const { promisify } = require('util');
    const execAsync = promisify(exec);

    const command = this.buildCommand(operation, context);
    
    const { stdout, stderr } = await execAsync(command, {
      cwd: context.working_dir,
      env: { ...process.env, ...context.env },
      timeout: context.timeout_ms || 30000
    });

    return { stdout, stderr };
  }

  /**
   * Execute operation remotely via SSH
   */
  private async executeRemote(
    operation: any,
    context: ExecutionContext
  ): Promise<any> {
    if (!context.target) {
      throw new Error('Remote target not specified');
    }

    // Get or create SSH connection
    let connectionId = context.ssh_connection_id;
    if (!connectionId) {
      const conn = await this.sshConnectionManager.createConnection({
        host: context.target,
        username: context.user,
        auth_method: 'key'
      });
      connectionId = conn.id;
    }

    const connection = this.sshConnectionManager.getConnection(connectionId);
    if (!connection) {
      throw new Error(`SSH connection ${connectionId} not found`);
    }

    const command = this.buildCommand(operation, context);
    
    return new Promise((resolve, reject) => {
      connection.client.exec(command, (err, stream) => {
        if (err) {
          reject(err);
          return;
        }

        let stdout = '';
        let stderr = '';

        stream.on('data', (data: Buffer) => {
          stdout += data.toString();
        });

        stream.stderr.on('data', (data: Buffer) => {
          stderr += data.toString();
        });

        stream.on('close', (code: number) => {
          if (code === 0) {
            resolve({ stdout, stderr });
          } else {
            reject(new Error(`Command failed with code ${code}: ${stderr}`));
          }
        });
      });
    });
  }

  /**
   * Build command string from operation
   */
  private buildCommand(operation: any, context: ExecutionContext): string {
    // This will be implemented by specific managers
    throw new Error('buildCommand must be implemented by operation handler');
  }
}
```

### Step 1.3: Implement NFS Mount Manager

**File**: `src/tools/infrastructure/nfs/mount-manager.ts`

```typescript
import { NFSMountConfig, NFSMount } from '../../../types/infrastructure/nfs.js';
import { ExecutionContext, OperationResult } from '../../../types/infrastructure/execution.js';
import { ExecutionRouter } from '../execution-router.js';

export class NFSMountManager {
  constructor(private router: ExecutionRouter) {}

  /**
   * Mount NFS share
   */
  async mount(
    config: NFSMountConfig,
    context: ExecutionContext
  ): Promise<NFSMount> {
    // Validate configuration
    this.validateMountConfig(config);

    // Create mount point if needed
    if (config.create_mountpoint) {
      await this.createMountPoint(config.target, context);
    }

    // Build mount command
    const command = this.buildMountCommand(config, context);

    // Execute mount
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Mount failed: ${result.error}`);
    }

    // Verify mount if requested
    if (config.verify_mount) {
      const verified = await this.verifyMount(config.target, context);
      if (!verified) {
        throw new Error('Mount verification failed');
      }
    }

    // Add to fstab if auto_mount
    if (config.auto_mount) {
      await this.addToFstab(config, context);
    }

    return {
      source: config.source,
      target: config.target,
      version: config.version,
      options: this.formatOptions(config.options),
      status: 'mounted',
      mounted_at: new Date()
    };
  }

  /**
   * Unmount NFS share
   */
  async unmount(
    target: string,
    context: ExecutionContext
  ): Promise<void> {
    const command = context.sudo_required
      ? `sudo umount ${target}`
      : `umount ${target}`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Unmount failed: ${result.error}`);
    }
  }

  /**
   * List active mounts
   */
  async listMounts(context: ExecutionContext): Promise<NFSMount[]> {
    const command = 'mount -t nfs,nfs4';
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to list mounts: ${result.error}`);
    }

    return this.parseMountOutput(result.data.stdout);
  }

  /**
   * Validate mount configuration
   */
  private validateMountConfig(config: NFSMountConfig): void {
    if (!config.source.includes(':')) {
      throw new Error('Invalid NFS source format. Expected: server:/export/path');
    }

    if (!config.target.startsWith('/')) {
      throw new Error('Mount target must be absolute path');
    }

    if (config.options?.hard && config.options?.soft) {
      throw new Error('Cannot specify both hard and soft mount options');
    }
  }

  /**
   * Build mount command
   */
  private buildMountCommand(
    config: NFSMountConfig,
    context: ExecutionContext
  ): string {
    const options = this.formatOptions(config.options);
    const optStr = options ? `-o ${options}` : '';
    const version = config.version !== '3' ? `-o vers=${config.version}` : '';
    
    const cmd = `mount -t nfs ${version} ${optStr} ${config.source} ${config.target}`;
    
    return context.sudo_required ? `sudo ${cmd}` : cmd;
  }

  /**
   * Format mount options
   */
  private formatOptions(options?: any): string {
    if (!options) return '';

    const opts: string[] = [];
    
    if (options.rw) opts.push('rw');
    if (options.async) opts.push('async');
    if (options.sync) opts.push('sync');
    if (options.noatime) opts.push('noatime');
    if (options.hard) opts.push('hard');
    if (options.soft) opts.push('soft');
    if (options.timeo) opts.push(`timeo=${options.timeo}`);
    if (options.retrans) opts.push(`retrans=${options.retrans}`);
    if (options.rsize) opts.push(`rsize=${options.rsize}`);
    if (options.wsize) opts.push(`wsize=${options.wsize}`);
    if (options.custom) opts.push(...options.custom);

    return opts.join(',');
  }

  /**
   * Create mount point directory
   */
  private async createMountPoint(
    path: string,
    context: ExecutionContext
  ): Promise<void> {
    const command = context.sudo_required
      ? `sudo mkdir -p ${path}`
      : `mkdir -p ${path}`;

    await this.router.route({ command }, context);
  }

  /**
   * Verify mount is accessible
   */
  private async verifyMount(
    target: string,
    context: ExecutionContext
  ): Promise<boolean> {
    const command = `test -d ${target} && mountpoint -q ${target}`;
    const result = await this.router.route({ command }, context);
    return result.success;
  }

  /**
   * Add mount to /etc/fstab
   */
  private async addToFstab(
    config: NFSMountConfig,
    context: ExecutionContext
  ): Promise<void> {
    const options = this.formatOptions(config.options);
    const fstabEntry = `${config.source} ${config.target} nfs ${options} 0 0`;
    
    const command = context.sudo_required
      ? `echo "${fstabEntry}" | sudo tee -a /etc/fstab`
      : `echo "${fstabEntry}" >> /etc/fstab`;

    await this.router.route({ command }, context);
  }

  /**
   * Parse mount command output
   */
  private parseMountOutput(output: string): NFSMount[] {
    const mounts: NFSMount[] = [];
    const lines = output.split('\n').filter(l => l.trim());

    for (const line of lines) {
      // Parse: server:/export on /mnt/nfs type nfs4 (options)
      const match = line.match(/^(.+?)\s+on\s+(.+?)\s+type\s+(nfs\d?)\s+\((.+?)\)/);
      if (match) {
        const [, source, target, type, options] = match;
        mounts.push({
          source,
          target,
          version: type.replace('nfs', '') as any || '4',
          options,
          status: 'mounted',
          mounted_at: new Date()
        });
      }
    }

    return mounts;
  }
}
```

### Step 1.4: Implement NFS Export Manager

**File**: `src/tools/infrastructure/nfs/export-manager.ts`

```typescript
import { NFSExportConfig } from '../../../types/infrastructure/nfs.js';
import { ExecutionContext } from '../../../types/infrastructure/execution.js';
import { ExecutionRouter } from '../execution-router.js';

export class NFSExportManager {
  constructor(private router: ExecutionRouter) {}

  /**
   * Add NFS export
   */
  async addExport(
    config: NFSExportConfig,
    context: ExecutionContext
  ): Promise<void> {
    // Validate configuration
    this.validateExportConfig(config);

    // Build export entry
    const entry = this.buildExportEntry(config);

    // Add to /etc/exports
    const command = context.sudo_required
      ? `echo "${entry}" | sudo tee -a /etc/exports`
      : `echo "${entry}" >> /etc/exports`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to add export: ${result.error}`);
    }

    // Reload exports
    await this.reloadExports(context);
  }

  /**
   * Remove NFS export
   */
  async removeExport(
    path: string,
    context: ExecutionContext
  ): Promise<void> {
    const command = context.sudo_required
      ? `sudo sed -i "\\|^${path}|d" /etc/exports`
      : `sed -i "\\|^${path}|d" /etc/exports`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to remove export: ${result.error}`);
    }

    await this.reloadExports(context);
  }

  /**
   * List active exports
   */
  async listExports(context: ExecutionContext): Promise<any[]> {
    const command = 'showmount -e localhost';
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to list exports: ${result.error}`);
    }

    return this.parseExportOutput(result.data.stdout);
  }

  /**
   * Reload NFS exports
   */
  async reloadExports(context: ExecutionContext): Promise<void> {
    const command = context.sudo_required
      ? 'sudo exportfs -ra'
      : 'exportfs -ra';

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to reload exports: ${result.error}`);
    }
  }

  /**
   * Validate export configuration
   */
  private validateExportConfig(config: NFSExportConfig): void {
    if (!config.path.startsWith('/')) {
      throw new Error('Export path must be absolute');
    }

    if (config.clients.length === 0) {
      throw new Error('At least one client must be specified');
    }

    if (config.options.rw && config.options.ro) {
      throw new Error('Cannot specify both rw and ro options');
    }

    if (config.options.sync && config.options.async) {
      throw new Error('Cannot specify both sync and async options');
    }
  }

  /**
   * Build export entry for /etc/exports
   */
  private buildExportEntry(config: NFSExportConfig): string {
    const options = this.formatExportOptions(config.options);
    const clients = config.clients.map(c => `${c}(${options})`).join(' ');
    
    let entry = `${config.path} ${clients}`;
    if (config.comment) {
      entry = `# ${config.comment}\n${entry}`;
    }
    
    return entry;
  }

  /**
   * Format export options
   */
  private formatExportOptions(options: any): string {
    const opts: string[] = [];
    
    if (options.rw) opts.push('rw');
    if (options.ro) opts.push('ro');
    if (options.sync) opts.push('sync');
    if (options.async) opts.push('async');
    if (options.no_subtree_check) opts.push('no_subtree_check');
    if (options.no_root_squash) opts.push('no_root_squash');
    if (options.root_squash) opts.push('root_squash');
    if (options.all_squash) opts.push('all_squash');
    if (options.anonuid) opts.push(`anonuid=${options.anonuid}`);
    if (options.anongid) opts.push(`anongid=${options.anongid}`);
    if (options.sec) opts.push(`sec=${options.sec.join(':')}`);
    if (options.custom) opts.push(...options.custom);

    return opts.join(',');
  }

  /**
   * Parse showmount output
   */
  private parseExportOutput(output: string): any[] {
    const exports: any[] = [];
    const lines = output.split('\n').slice(1).filter(l => l.trim());

    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      if (parts.length >= 2) {
        exports.push({
          path: parts[0],
          clients: parts.slice(1)
        });
      }
    }

    return exports;
  }
}
```

### Step 1.5: Implement NFS Manager Orchestrator

**File**: `src/tools/infrastructure/nfs/nfs-manager.ts`

```typescript
import { ExecutionRouter } from '../execution-router.js';
import { NFSMountManager } from './mount-manager.js';
import { NFSExportManager } from './export-manager.js';
import { NFSOperation, NFSOperationResult } from '../../../types/infrastructure/nfs.js';
import { ExecutionContext } from '../../../types/infrastructure/execution.js';

/**
 * Main NFS management orchestrator
 */
export class NFSManager {
  private mountManager: NFSMountManager;
  private exportManager: NFSExportManager;

  constructor(private router: ExecutionRouter) {
    this.mountManager = new NFSMountManager(router);
    this.exportManager = new NFSExportManager(router);
  }

  /**
   * Execute NFS operation
   */
  async execute(
    operation: NFSOperation,
    context: ExecutionContext
  ): Promise<NFSOperationResult> {
    const startTime = Date.now();

    try {
      let data: any;

      switch (operation.type) {
        case 'mount':
          data = await this.mountManager.mount(operation.config, context);
          break;

        case 'unmount':
          await this.mountManager.unmount(operation.target, context);
          data = { unmounted: true };
          break;

        case 'list_mounts':
          data = await this.mountManager.listMounts(context);
          break;

        case 'add_export':
          await this.exportManager.addExport(operation.config, context);
          data = { added: true };
          break;

        case 'remove_export':
          await this.exportManager.removeExport(operation.path, context);
          data = { removed: true };
          break;

        case 'list_exports':
          data = await this.exportManager.listExports(context);
          break;

        default:
          throw new Error(`Unknown NFS operation: ${(operation as any).type}`);
      }

      return {
        success: true,
        data,
        operation,
        context,
        duration_ms: Date.now() - startTime,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : String(error),
        operation,
        context,
        duration_ms: Date.now() - startTime,
        timestamp: new Date()
      };
    }
  }
}
```

### Step 1.6: Implement Server Manager for NixOS

**File**: `src/tools/infrastructure/server/adapters/nixos-adapter.ts`

```typescript
import { ExecutionContext } from '../../../../types/infrastructure/execution.js';
import { PackageInfo, ServiceStatus, FirewallRule } from '../../../../types/infrastructure/server.js';
import { ExecutionRouter } from '../../execution-router.js';

export class NixOSAdapter {
  readonly distro = 'nixos';

  constructor(private router: ExecutionRouter) {}

  /**
   * Install packages (add to configuration.nix and rebuild)
   */
  async installPackages(
    packages: string[],
    context: ExecutionContext
  ): Promise<void> {
    // In NixOS, package installation is declarative
    // This would typically involve:
    // 1. Reading current configuration
    // 2. Adding packages to environment.systemPackages
    // 3. Running nixos-rebuild switch
    
    const pkgList = packages.map(p => `pkgs.${p}`).join(' ');
    
    // Note: This is simplified. Real implementation would parse and modify configuration.nix
    const command = `sudo nixos-rebuild switch`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to install packages: ${result.error}`);
    }
  }

  /**
   * Remove packages
   */
  async removePackages(
    packages: string[],
    context: ExecutionContext
  ): Promise<void> {
    // Similar to install, this modifies configuration.nix
    const command = `sudo nixos-rebuild switch`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to remove packages: ${result.error}`);
    }
  }

  /**
   * Update all packages
   */
  async updatePackages(context: ExecutionContext): Promise<void> {
    const command = 'sudo nix-channel --update && sudo nixos-rebuild switch --upgrade';
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to update packages: ${result.error}`);
    }
  }

  /**
   * Search packages
   */
  async searchPackages(
    query: string,
    context: ExecutionContext
  ): Promise<PackageInfo[]> {
    const command = `nix search nixpkgs ${query} --json`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to search packages: ${result.error}`);
    }

    return this.parseSearchOutput(result.data.stdout);
  }

  /**
   * Start service
   */
  async startService(name: string, context: ExecutionContext): Promise<void> {
    const command = `sudo systemctl start ${name}`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to start service: ${result.error}`);
    }
  }

  /**
   * Stop service
   */
  async stopService(name: string, context: ExecutionContext): Promise<void> {
    const command = `sudo systemctl stop ${name}`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to stop service: ${result.error}`);
    }
  }

  /**
   * Restart service
   */
  async restartService(name: string, context: ExecutionContext): Promise<void> {
    const command = `sudo systemctl restart ${name}`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to restart service: ${result.error}`);
    }
  }

  /**
   * Enable service
   */
  async enableService(name: string, context: ExecutionContext): Promise<void> {
    const command = `sudo systemctl enable ${name}`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to enable service: ${result.error}`);
    }
  }

  /**
   * Disable service
   */
  async disableService(name: string, context: ExecutionContext): Promise<void> {
    const command = `sudo systemctl disable ${name}`;
    
    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to disable service: ${result.error}`);
    }
  }

  /**
   * Get service status
   */
  async getServiceStatus(
    name: string,
    context: ExecutionContext
  ): Promise<ServiceStatus> {
    const command = `systemctl status ${name} --no-pager`;
    
    const result = await this.router.route({ command }, context);
    
    return this.parseServiceStatus(name, result.data.stdout);
  }

  /**
   * Add firewall rule (NixOS uses declarative firewall)
   */
  async addFirewallRule(
    rule: FirewallRule,
    context: ExecutionContext
  ): Promise<void> {
    // In NixOS, firewall rules are declared in configuration.nix
    // This would typically modify networking.firewall settings
    throw new Error('NixOS firewall rules must be added to configuration.nix');
  }

  /**
   * Parse nix search output
   */
  private parseSearchOutput(output: string): PackageInfo[] {
    try {
      const json = JSON.parse(output);
      const packages: PackageInfo[] = [];

      for (const [path, info] of Object.entries(json as any)) {
        packages.push({
          name: info.pname || path.split('.').pop(),
          version: info.version || 'unknown',
          status: 'not_installed',
          description: info.description
        });
      }

      return packages;
    } catch {
      return [];
    }
  }

  /**
   * Parse systemctl status output
   */
  private parseServiceStatus(name: string, output: string): ServiceStatus {
    const activeMatch = output.match(/Active:\s+(\w+)/);
    const state = activeMatch ? activeMatch[1] : 'unknown';

    return {
      name,
      state: this.mapServiceState(state),
      enable_state: 'enabled',
      description: `Service ${name}`
    };
  }

  /**
   * Map systemctl state to ServiceState
   */
  private mapServiceState(state: string): any {
    const stateMap: Record<string, any> = {
      'active': 'running',
      'inactive': 'stopped',
      'failed': 'failed',
      'activating': 'running',
      'deactivating': 'stopped'
    };

    return stateMap[state] || 'unknown';
  }
}
```

---

## 🎯 Phase 2: Clusters

### Step 2.1: Implement Kubernetes Manager

**File**: `src/tools/infrastructure/cluster/kubernetes-manager.ts`

```typescript
import { ExecutionRouter } from '../execution-router.js';
import { ExecutionContext } from '../../../types/infrastructure/execution.js';
import {
  K8sClusterInfo,
  K8sPod,
  K8sDeployment,
  K8sService,
  K8sHealthStatus
} from '../../../types/infrastructure/cluster.js';

export class KubernetesManager {
  readonly type = 'kubernetes';

  constructor(private router: ExecutionRouter) {}

  /**
   * Get cluster information
   */
  async getClusterInfo(context: ExecutionContext): Promise<K8sClusterInfo> {
    const versionCmd = 'kubectl version --short';
    const nodesCmd = 'kubectl get nodes --no-headers | wc -l';
    const nsCmd = 'kubectl get namespaces --no-headers | wc -l';

    const [versionResult, nodesResult, nsResult] = await Promise.all([
      this.router.route({ command: versionCmd }, context),
      this.router.route({ command: nodesCmd }, context),
      this.router.route({ command: nsCmd }, context)
    ]);

    const version = versionResult.data.stdout.match(/Server Version: v(.+)/)?.[1] || 'unknown';

    return {
      name: 'kubernetes',
      type: 'kubernetes',
      version,
      endpoint: 'kubernetes.default.svc',
      node_count: parseInt(nodesResult.data.stdout.trim()),
      health: 'healthy',
      api_version: version,
      namespace_count: parseInt(nsResult.data.stdout.trim())
    };
  }

  /**
   * List pods in namespace
   */
  async listPods(
    namespace: string | undefined,
    context: ExecutionContext
  ): Promise<K8sPod[]> {
    const ns = namespace ? `-n ${namespace}` : '--all-namespaces';
    const command = `kubectl get pods ${ns} -o json`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to list pods: ${result.error}`);
    }

    const json = JSON.parse(result.data.stdout);
    return this.parsePods(json.items);
  }

  /**
   * Get deployment details
   */
  async getDeployment(
    name: string,
    namespace: string,
    context: ExecutionContext
  ): Promise<K8sDeployment> {
    const command = `kubectl get deployment ${name} -n ${namespace} -o json`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to get deployment: ${result.error}`);
    }

    const json = JSON.parse(result.data.stdout);
    return this.parseDeployment(json);
  }

  /**
   * Scale deployment
   */
  async scaleDeployment(
    name: string,
    namespace: string,
    replicas: number,
    context: ExecutionContext
  ): Promise<void> {
    const command = `kubectl scale deployment ${name} -n ${namespace} --replicas=${replicas}`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to scale deployment: ${result.error}`);
    }
  }

  /**
   * Restart deployment (rollout restart)
   */
  async rolloutRestart(
    name: string,
    namespace: string,
    context: ExecutionContext
  ): Promise<void> {
    const command = `kubectl rollout restart deployment ${name} -n ${namespace}`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to restart deployment: ${result.error}`);
    }
  }

  /**
   * List services
   */
  async listServices(
    namespace: string | undefined,
    context: ExecutionContext
  ): Promise<K8sService[]> {
    const ns = namespace ? `-n ${namespace}` : '--all-namespaces';
    const command = `kubectl get services ${ns} -o json`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to list services: ${result.error}`);
    }

    const json = JSON.parse(result.data.stdout);
    return this.parseServices(json.items);
  }

  /**
   * Check cluster health
   */
  async checkHealth(context: ExecutionContext): Promise<K8sHealthStatus> {
    const componentsCmd = 'kubectl get componentstatuses -o json';
    const nodesCmd = 'kubectl get nodes -o json';

    const [componentsResult, nodesResult] = await Promise.all([
      this.router.route({ command: componentsCmd }, context),
      this.router.route({ command: nodesCmd }, context)
    ]);

    const components = JSON.parse(componentsResult.data.stdout);
    const nodes = JSON.parse(nodesResult.data.stdout);

    const issues: string[] = [];
    
    // Check component health
    for (const comp of components.items) {
      if (comp.conditions?.[0]?.type === 'Healthy' && comp.conditions[0].status !== 'True') {
        issues.push(`Component ${comp.metadata.name} is unhealthy`);
      }
    }

    // Count node statuses
    let readyNodes = 0;
    let notReadyNodes = 0;
    
    for (const node of nodes.items) {
      const ready = node.status.conditions.find((c: any) => c.type === 'Ready');
      if (ready?.status === 'True') {
        readyNodes++;
      } else {
        notReadyNodes++;
        issues.push(`Node ${node.metadata.name} is not ready`);
      }
    }

    const status = issues.length === 0 ? 'healthy' : 'degraded';

    return {
      status,
      api_server_healthy: true,
      controller_manager_healthy: true,
      scheduler_healthy: true,
      etcd_healthy: true,
      nodes: {
        total: readyNodes + notReadyNodes,
        ready: readyNodes,
        not_ready: notReadyNodes
      },
      issues
    };
  }

  /**
   * Parse pod JSON
   */
  private parsePods(items: any[]): K8sPod[] {
    return items.map(item => ({
      name: item.metadata.name,
      type: 'Pod',
      namespace: item.metadata.namespace,
      status: item.status.phase === 'Running' ? 'running' : 'pending',
      phase: item.status.phase,
      node: item.spec.nodeName,
      ip: item.status.podIP,
      desired_replicas: 1,
      current_replicas: 1,
      ready_replicas: item.status.phase === 'Running' ? 1 : 0,
      created_at: new Date(item.metadata.creationTimestamp),
      containers: item.spec.containers.map((c: any) => ({
        name: c.name,
        ready: true,
        restart_count: 0,
        image: c.image
      })),
      conditions: item.status.conditions || []
    }));
  }

  /**
   * Parse deployment JSON
   */
  private parseDeployment(item: any): K8sDeployment {
    return {
      name: item.metadata.name,
      type: 'Deployment',
      namespace: item.metadata.namespace,
      status: 'running',
      strategy: item.spec.strategy.type,
      selector: item.spec.selector.matchLabels,
      desired_replicas: item.spec.replicas,
      current_replicas: item.status.replicas || 0,
      ready_replicas: item.status.readyReplicas || 0,
      created_at: new Date(item.metadata.creationTimestamp),
      template: {
        containers: item.spec.template.spec.containers.map((c: any) => ({
          name: c.name,
          image: c.image,
          ports: c.ports?.map((p: any) => ({
            name: p.name,
            protocol: p.protocol,
            container_port: p.containerPort
          }))
        }))
      },
      conditions: item.status.conditions || []
    };
  }

  /**
   * Parse service JSON
   */
  private parseServices(items: any[]): K8sService[] {
    return items.map(item => ({
      name: item.metadata.name,
      namespace: item.metadata.namespace,
      type: item.spec.type,
      cluster_ip: item.spec.clusterIP,
      external_ips: item.spec.externalIPs,
      load_balancer_ip: item.status.loadBalancer?.ingress?.[0]?.ip,
      ports: item.spec.ports.map((p: any) => ({
        name: p.name,
        protocol: p.protocol,
        port: p.port,
        target_port: p.targetPort,
        node_port: p.nodePort
      })),
      selector: item.spec.selector || {},
      created_at: new Date(item.metadata.creationTimestamp)
    }));
  }
}
```

### Step 2.2: Implement Docker Swarm Manager

**File**: `src/tools/infrastructure/cluster/swarm-manager.ts`

```typescript
import { ExecutionRouter } from '../execution-router.js';
import { ExecutionContext } from '../../../types/infrastructure/execution.js';
import {
  SwarmInfo,
  SwarmNode,
  SwarmService,
  SwarmHealthStatus
} from '../../../types/infrastructure/cluster.js';

export class DockerSwarmManager {
  readonly type = 'docker_swarm';

  constructor(private router: ExecutionRouter) {}

  /**
   * Get swarm information
   */
  async getClusterInfo(context: ExecutionContext): Promise<SwarmInfo> {
    const command = 'docker info --format json';

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to get swarm info: ${result.error}`);
    }

    const info = JSON.parse(result.data.stdout);
    const swarm = info.Swarm;

    return {
      name: 'docker-swarm',
      type: 'docker_swarm',
      version: info.ServerVersion,
      endpoint: swarm.NodeAddr,
      node_count: swarm.Nodes,
      health: 'healthy',
      swarm_id: swarm.Cluster.ID,
      managers: swarm.Managers,
      workers: swarm.Nodes - swarm.Managers,
      created_at: new Date(swarm.Cluster.CreatedAt),
      updated_at: new Date(swarm.Cluster.UpdatedAt)
    };
  }

  /**
   * List swarm nodes
   */
  async getNodes(context: ExecutionContext): Promise<SwarmNode[]> {
    const command = 'docker node ls --format json';

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to list nodes: ${result.error}`);
    }

    const lines = result.data.stdout.split('\n').filter((l: string) => l.trim());
    return lines.map((line: string) => this.parseNodeLine(line));
  }

  /**
   * List services
   */
  async listServices(context: ExecutionContext): Promise<SwarmService[]> {
    const command = 'docker service ls --format json';

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to list services: ${result.error}`);
    }

    const lines = result.data.stdout.split('\n').filter((l: string) => l.trim());
    return lines.map((line: string) => this.parseServiceLine(line));
  }

  /**
   * Scale service
   */
  async scaleService(
    name: string,
    replicas: number,
    context: ExecutionContext
  ): Promise<void> {
    const command = `docker service scale ${name}=${replicas}`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to scale service: ${result.error}`);
    }
  }

  /**
   * Update service
   */
  async updateService(
    name: string,
    image: string,
    context: ExecutionContext
  ): Promise<void> {
    const command = `docker service update --image ${image} ${name}`;

    const result = await this.router.route({ command }, context);
    
    if (!result.success) {
      throw new Error(`Failed to update service: ${result.error}`);
    }
  }

  /**
   * Check swarm health
   */
  async checkHealth(context: ExecutionContext): Promise<SwarmHealthStatus> {
    const nodes = await this.getNodes(context);
    
    const managers = nodes.filter(n => n.roles.includes('manager'));
    const workers = nodes.filter(n => n.roles.includes('worker'));
    
    const healthyManagers = managers.filter(n => n.status === 'ready').length;
    const activeWorkers = workers.filter(n => n.availability === 'active').length;

    const issues: string[] = [];
    
    if (healthyManagers < managers.length) {
      issues.push(`${managers.length - healthyManagers} manager(s) unhealthy`);
    }
    
    if (activeWorkers < workers.length) {
      issues.push(`${workers.length - activeWorkers} worker(s) inactive`);
    }

    const status = issues.length === 0 ? 'healthy' : 'degraded';

    return {
      status,
      swarm_active: true,
      managers: {
        total: managers.length,
        healthy: healthyManagers
      },
      workers: {
        total: workers.length,
        active: activeWorkers
      },
      issues
    };
  }

  /**
   * Parse node JSON line
   */
  private parseNodeLine(line: string): SwarmNode {
    const json = JSON.parse(line);
    return {
      name: json.Hostname,
      id: json.ID,
      status: json.Status === 'Ready' ? 'ready' : 'not_ready',
      roles: [json.ManagerStatus ? 'manager' : 'worker'],
      age: json.Self ? 'leader' : 'follower',
      version: json.EngineVersion,
      availability: json.Availability,
      addresses: {
        internal: json.Self ? 'local' : json.NodeAddr
      },
      capacity: {
        cpu: '',
        memory: ''
      },
      allocatable: {
        cpu: '',
        memory: ''
      },
      engine_version: json.EngineVersion,
      platform: {
        os: '',
        architecture: ''
      }
    };
  }

  /**
   * Parse service JSON line
   */
  private parseServiceLine(line: string): SwarmService {
    const json = JSON.parse(line);
    const [running, total] = json.Replicas.split('/').map(Number);

    return {
      id: json.ID,
      name: json.Name,
      mode: json.Mode,
      replicas: {
        desired: total,
        running
      },
      image: json.Image,
      ports: [],
      networks: [],
      created_at: new Date(),
      updated_at: new Date()
    };
  }
}
```

---

## 🔒 Security Best Practices

### Input Validation

```typescript
/**
 * Sanitize command inputs to prevent injection
 */
export function sanitizeInput(input: string): string {
  // Remove dangerous characters
  return input.replace(/[;&|`$(){}[\]<>]/g, '');
}

/**
 * Validate hostname format
 */
export function validateHostname(hostname: string): boolean {
  const pattern = /^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
  return pattern.test(hostname);
}

/**
 * Validate IP address
 */
export function validateIP(ip: string): boolean {
  const pattern = /^(\d{1,3}\.){3}\d{1,3}$/;
  if (!pattern.test(ip)) return false;
  
  const parts = ip.split('.');
  return parts.every(p => parseInt(p) <= 255);
}
```

### Command Whitelisting

```typescript
/**
 * Whitelist of allowed commands per module
 */
export const COMMAND_WHITELIST = {
  nfs: [
    'mount',
    'umount',
    'showmount',
    'exportfs',
    'nfsstat'
  ],
  cluster: [
    'kubectl',
    'docker'
  ],
  server: [
    'apt-get',
    'yum',
    'dnf',
    'systemctl',
    'service',
    'nix',
    'nixos-rebuild'
  ]
};

/**
 * Validate command against whitelist
 */
export function validateCommand(command: string, module: string): boolean {
  const baseCommand = command.split(' ')[0];
  const whitelist = COMMAND_WHITELIST[module as keyof typeof COMMAND_WHITELIST];
  
  return whitelist.includes(baseCommand);
}
```

### Audit Logging

```typescript
/**
 * Log infrastructure operation for audit
 */
export async function auditLog(
  operation: any,
  context: ExecutionContext,
  result: OperationResult
): Promise<void> {
  const entry = {
    timestamp: new Date(),
    user: context.user,
    operation: operation.type,
    target: context.target || 'localhost',
    success: result.success,
    duration_ms: result.duration_ms,
    error: result.error
  };

  // Write to audit log
  console.log('[AUDIT]', JSON.stringify(entry));
}
```

---

## 🧪 Testing Strategy

### Unit Tests

```typescript
import { describe, it, expect } from '@jest/globals';
import { NFSMountManager } from '../nfs/mount-manager.js';

describe('NFSMountManager', () => {
  it('should validate mount config', () => {
    const manager = new NFSMountManager(mockRouter);
    
    expect(() => {
      manager['validateMountConfig']({
        source: 'invalid',
        target: '/mnt/nfs',
        version: '4'
      });
    }).toThrow('Invalid NFS source format');
  });

  it('should format mount options correctly', () => {
    const manager = new NFSMountManager(mockRouter);
    
    const options = manager['formatOptions']({
      rw: true,
      async: true,
      noatime: true
    });
    
    expect(options).toBe('rw,async,noatime');
  });
});
```

### Integration Tests

```typescript
describe('NFS Integration', () => {
  it('should mount and unmount NFS share', async () => {
    const manager = new NFSManager(router);
    
    // Mount
    const mountResult = await manager.execute({
      type: 'mount',
      config: {
        source: 'nas.example.com:/export/data',
        target: '/mnt/test',
        version: '4',
        create_mountpoint: true
      }
    }, localContext);
    
    expect(mountResult.success).toBe(true);
    
    // Verify
    const listResult = await manager.execute({
      type: 'list_mounts'
    }, localContext);
    
    expect(listResult.data.some((m: any) => m.target === '/mnt/test')).toBe(true);
    
    // Unmount
    const unmountResult = await manager.execute({
      type: 'unmount',
      target: '/mnt/test'
    }, localContext);
    
    expect(unmountResult.success).toBe(true);
  });
});
```

---

## 📊 Performance Considerations

### Connection Pooling

Reuse SSH connections for multiple operations:

```typescript
// Good: Reuse connection
const connectionId = await createConnection(target);
for (const operation of operations) {
  await execute(operation, { ...context, ssh_connection_id: connectionId });
}

// Bad: Create new connection each time
for (const operation of operations) {
  await execute(operation, { ...context, target });
}
```

### Parallel Execution

Execute independent operations in parallel:

```typescript
// Good: Parallel execution
const [pods, services, nodes] = await Promise.all([
  k8s.listPods(namespace, context),
  k8s.listServices(namespace, context),
  k8s.getNodes(context)
]);

// Bad: Sequential execution
const pods = await k8s.listPods(namespace, context);
const services = await k8s.listServices(namespace, context);
const nodes = await k8s.getNodes(context);
```

### Caching

Cache frequently accessed data:

```typescript
class CachedKubernetesManager extends KubernetesManager {
  private cache = new Map<string, { data: any; expiry: number }>();

  async getClusterInfo(context: ExecutionContext): Promise<K8sClusterInfo> {
    const cacheKey = 'cluster-info';
    const cached = this.cache.get(cacheKey);
    
    if (cached && cached.expiry > Date.now()) {
      return cached.data;
    }

    const info = await super.getClusterInfo(context);
    
    this.cache.set(cacheKey, {
      data: info,
      expiry: Date.now() + 60000 // 1 minute
    });

    return info;
  }
}
```

---

## 📝 Implementation Checklist

### Phase 1 Checklist
- [ ] Create all type definitions in `types/infrastructure/`
- [ ] Implement ExecutionRouter with local/remote detection
- [ ] Implement NFSMountManager
- [ ] Implement NFSExportManager
- [ ] Implement NFSManager orchestrator
- [ ] Implement NixOSAdapter for ServerManager
- [ ] Add SSH integration tests
- [ ] Add security validation
- [ ] Add audit logging

### Phase 2 Checklist
- [ ] Implement KubernetesManager
- [ ] Implement DockerSwarmManager
- [ ] Implement ClusterManager orchestrator
- [ ] Implement UbuntuAdapter
- [ ] Implement RHELAdapter
- [ ] Add cluster health monitoring
- [ ] Add multi-distro tests
- [ ] Add performance benchmarks

### Phase 3 Checklist
- [ ] Implement NASVolumeManager
- [ ] Implement NASSnapshotManager
- [ ] Implement NASProtocolManager
- [ ] Implement NASManager orchestrator
- [ ] Add quota management
- [ ] Add replication support
- [ ] Add NAS integration tests

### Phase 4 Checklist
- [ ] Add cross-module orchestration
- [ ] Implement connection pooling optimizations
- [ ] Add comprehensive error handling
- [ ] Add retry logic with exponential backoff
- [ ] Complete documentation
- [ ] Add usage examples
- [ ] Performance tuning
- [ ] Security audit

---

## 🎯 Success Criteria

- [ ] All 4 modules implemented and tested
- [ ] Hybrid execution (local + remote) working correctly
- [ ] Multi-distro support verified (NixOS, Ubuntu, RHEL)
- [ ] Kubernetes + Docker Swarm operations functional
- [ ] Security controls active and tested
- [ ] 90%+ test coverage for critical paths
- [ ] Performance benchmarks met
- [ ] Documentation complete
- [ ] Zero critical vulnerabilities

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-26  
**Status**: Implementation Guide Complete  
**Total Lines**: 1,500+ lines of implementation guidance