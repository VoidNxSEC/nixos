/**
 * Directory Lister Proactive Action
 * 
 * Lists directory contents when user asks about directories.
 */

import { readdirSync, statSync } from 'fs';
import { join } from 'path';
import type { ProactiveAction, ActionContext, DirectoryListResult } from '../../types/proactive-actions.js';

/**
 * Directory Lister Action
 */
export class DirectoryListerAction implements ProactiveAction {
  public readonly name = 'directory_list';

  /**
   * Check if should run
   */
  public shouldRun(context: ActionContext): boolean {
    const { enrichedContext } = context;
    
    // Run if user intent is query and mentions directories
    return (
      enrichedContext.input.intent === 'query' &&
      (enrichedContext.input.text.includes('directory') ||
        enrichedContext.input.text.includes('folder') ||
        enrichedContext.input.text.includes('dir'))
    );
  }

  /**
   * Execute directory listing
   */
  public async execute(context: ActionContext): Promise<DirectoryListResult> {
    const startTime = Date.now();
    
    try {
      const { enrichedContext, projectRoot } = context;
      
      // Extract directory path from entities or use project root
      const moduleEntities = enrichedContext.input.entities.filter(e => e.type === 'module');
      const dirPath = moduleEntities.length > 0
        ? join(projectRoot, moduleEntities[0].value)
        : projectRoot;

      const entries = readdirSync(dirPath, { withFileTypes: true }).map(dirent => {
        const fullPath = join(dirPath, dirent.name);
        let size = 0;
        
        try {
          if (dirent.isFile()) {
            size = statSync(fullPath).size;
          }
        } catch {
          // Ignore stat errors
        }

        return {
          name: dirent.name,
          type: dirent.isDirectory() ? 'dir' as const : 'file' as const,
          size,
        };
      }).slice(0, 50); // Limit to 50 entries

      return {
        action: this.name,
        status: 'success',
        data: {
          entries,
          total: entries.length,
          path: dirPath,
        },
        duration: Date.now() - startTime,
      };
    } catch (error: any) {
      return {
        action: this.name,
        status: 'error',
        data: { entries: [], total: 0, path: '' },
        duration: Date.now() - startTime,
        error: error.message,
      };
    }
  }
}