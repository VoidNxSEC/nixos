/**
 * File Scanner Proactive Action
 * 
 * Scans for files matching entities extracted from input.
 */

import { execSync } from 'child_process';
import type { ProactiveAction, ActionContext, FileScanResult } from '../../types/proactive-actions.js';

/**
 * File Scanner Action
 */
export class FileScannerAction implements ProactiveAction {
  public readonly name = 'file_scan';

  /**
   * Check if should run
   */
  public shouldRun(context: ActionContext): boolean {
    const { enrichedContext } = context;
    
    // Run if user mentioned files but we haven't found them yet
    const fileEntities = enrichedContext.input.entities.filter(e => e.type === 'file');
    return fileEntities.length > 0 && enrichedContext.quality < 0.7;
  }

  /**
   * Execute file scan
   */
  public async execute(context: ActionContext): Promise<FileScanResult> {
    const startTime = Date.now();
    
    try {
      const { enrichedContext, projectRoot, timeout } = context;
      const fileEntities = enrichedContext.input.entities.filter(e => e.type === 'file');
      
      if (fileEntities.length === 0) {
        return {
          action: this.name,
          status: 'skipped',
          data: { files: [], pattern: '', totalScanned: 0 },
          duration: Date.now() - startTime,
        };
      }

      // Use first file entity as pattern
      const pattern = fileEntities[0].value;
      
      // Use ripgrep for fast file finding
      const output = execSync(`rg --files | rg "${pattern}"`, {
        cwd: projectRoot,
        encoding: 'utf-8',
        timeout: Math.min(timeout, 1000), // Max 1s
        maxBuffer: 1024 * 1024, // 1MB
      });

      const files = output.split('\n').filter(f => f.length > 0).slice(0, 20);

      return {
        action: this.name,
        status: 'success',
        data: {
          files,
          pattern,
          totalScanned: files.length,
        },
        duration: Date.now() - startTime,
      };
    } catch (error: any) {
      if (error.killed) {
        return {
          action: this.name,
          status: 'timeout',
          data: { files: [], pattern: '', totalScanned: 0 },
          duration: Date.now() - startTime,
          error: 'Execution timeout',
        };
      }

      return {
        action: this.name,
        status: 'error',
        data: { files: [], pattern: '', totalScanned: 0 },
        duration: Date.now() - startTime,
        error: error.message,
      };
    }
  }
}