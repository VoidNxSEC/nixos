/**
 * Nix Flake Operations
 * 
 * Provides operations for Nix flakes: build, check, update, etc.
 */

import { execSync } from 'child_process';
import type { FlakeBuildResult, FlakeOperation, FlakeMetadata } from '../../types/nix-tools.js';

/**
 * Flake Operations
 */
export class FlakeOps {
  private projectRoot: string;

  constructor(projectRoot: string) {
    this.projectRoot = projectRoot;
  }

  /**
   * Build a flake output
   */
  public async build(output: string = ''): Promise<FlakeBuildResult> {
    return this.executeFlakeCommand('build', output);
  }

  /**
   * Check flake (run all checks)
   */
  public async check(): Promise<FlakeBuildResult> {
    return this.executeFlakeCommand('check');
  }

  /**
   * Update flake inputs
   */
  public async update(input?: string): Promise<FlakeBuildResult> {
    const args = input ? [input] : [];
    return this.executeFlakeCommand('update', '', args);
  }

  /**
   * Show flake metadata
   */
  public async show(): Promise<FlakeMetadata> {
    try {
      const output = execSync('nix flake metadata --json', {
        cwd: this.projectRoot,
        encoding: 'utf-8',
        timeout: 10000,
      });

      const metadata = JSON.parse(output);
      
      return {
        description: metadata.description || '',
        lastModified: metadata.lastModified || 0,
        revision: metadata.revision,
        inputs: this.parseInputs(metadata.locks?.nodes || {}),
        outputs: Object.keys(metadata.locks?.nodes?.root?.outputs || {}),
      };
    } catch (error: any) {
      throw new Error(`Failed to show flake metadata: ${error.message}`);
    }
  }

  /**
   * Evaluate Nix expression
   */
  public async eval(expression: string): Promise<string> {
    try {
      const output = execSync(`nix eval --raw '${expression}'`, {
        cwd: this.projectRoot,
        encoding: 'utf-8',
        timeout: 5000,
      });

      return output.trim();
    } catch (error: any) {
      throw new Error(`Failed to evaluate expression: ${error.message}`);
    }
  }

  /**
   * Enter development shell
   */
  public async develop(shell?: string): Promise<FlakeBuildResult> {
    const target = shell ? `.#${shell}` : '';
    return this.executeFlakeCommand('develop', target, ['--command', 'echo', 'Shell ready']);
  }

  /**
   * Execute flake command
   */
  private async executeFlakeCommand(
    operation: FlakeOperation,
    target: string = '',
    extraArgs: string[] = []
  ): Promise<FlakeBuildResult> {
    const startTime = Date.now();
    const logs: string[] = [];
    const errors: string[] = [];
    const warnings: string[] = [];

    try {
      const flakeRef = target ? `.#${target}` : '.';
      const args = ['flake', operation, flakeRef, ...extraArgs].filter(Boolean);
      
      const output = execSync(`nix ${args.join(' ')}`, {
        cwd: this.projectRoot,
        encoding: 'utf-8',
        timeout: 120000, // 2 minutes
        maxBuffer: 10 * 1024 * 1024, // 10MB
      });

      logs.push(output);

      // Parse output for paths
      const outputPath = this.extractOutputPath(output);

      // Parse warnings
      const foundWarnings = this.extractWarnings(output);
      warnings.push(...foundWarnings);

      return {
        operation,
        success: true,
        outputPath,
        logs,
        errors,
        warnings,
        duration: Date.now() - startTime,
        exitCode: 0,
      };
    } catch (error: any) {
      const output = error.stdout || error.stderr || '';
      logs.push(output);

      // Parse errors
      const foundErrors = this.extractErrors(output);
      errors.push(...foundErrors);

      return {
        operation,
        success: false,
        logs,
        errors,
        warnings,
        duration: Date.now() - startTime,
        exitCode: error.status || 1,
      };
    }
  }

  /**
   * Extract output path from build output
   */
  private extractOutputPath(output: string): string | undefined {
    const match = output.match(/\/nix\/store\/[a-z0-9]+-[^\s]+/);
    return match ? match[0] : undefined;
  }

  /**
   * Extract errors from output
   */
  private extractErrors(output: string): string[] {
    const errors: string[] = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('error:') || line.includes('ERROR')) {
        errors.push(line.trim());
      }
    }
    
    return errors;
  }

  /**
   * Extract warnings from output
   */
  private extractWarnings(output: string): string[] {
    const warnings: string[] = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('warning:') || line.includes('WARN')) {
        warnings.push(line.trim());
      }
    }
    
    return warnings;
  }

  /**
   * Parse flake inputs
   */
  private parseInputs(nodes: any): Record<string, any> {
    const inputs: Record<string, any> = {};
    
    for (const [name, node] of Object.entries(nodes)) {
      if (name === 'root') continue;
      
      const nodeData = node as any;
      inputs[name] = {
        type: nodeData.original?.type || 'unknown',
        url: nodeData.original?.url || nodeData.locked?.url || '',
        revision: nodeData.locked?.rev,
        lastModified: nodeData.locked?.lastModified,
      };
    }
    
    return inputs;
  }
}