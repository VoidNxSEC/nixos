/**
 * Git History Proactive Action
 * 
 * Retrieves recent git history when relevant to user's query.
 */

import { execSync } from 'child_process';
import type { ProactiveAction, ActionContext, GitHistoryResult } from '../../types/proactive-actions.js';

/**
 * Git History Action
 */
export class GitHistoryAction implements ProactiveAction {
  public readonly name = 'git_history';

  /**
   * Check if should run
   */
  public shouldRun(context: ActionContext): boolean {
    const { enrichedContext } = context;
    
    // Run if git-related intent or topics
    const hasGitTopic = enrichedContext.input.topics.some(t => t.name === 'git');
    const hasGitState = enrichedContext.project.git !== null;
    
    return hasGitTopic && hasGitState;
  }

  /**
   * Execute git history retrieval
   */
  public async execute(context: ActionContext): Promise<GitHistoryResult> {
    const startTime = Date.now();
    
    try {
      const { projectRoot, timeout } = context;
      
      // Get last 10 commits
      const output = execSync('git log -10 --pretty=format:"%H|%s|%an|%ad" --date=short', {
        cwd: projectRoot,
        encoding: 'utf-8',
        timeout: Math.min(timeout, 1000),
      });

      const commits = output.split('\n').map(line => {
        const [hash, message, author, date] = line.split('|');
        return { hash: hash.substring(0, 7), message, author, date };
      });

      // Get files changed in recent commits
      const filesOutput = execSync('git diff --name-only HEAD~10..HEAD', {
        cwd: projectRoot,
        encoding: 'utf-8',
        timeout: Math.min(timeout, 500),
      });

      const files = filesOutput.split('\n').filter(f => f.length > 0).slice(0, 20);

      return {
        action: this.name,
        status: 'success',
        data: {
          commits,
          files,
          range: {
            from: commits[commits.length - 1]?.date || '',
            to: commits[0]?.date || '',
          },
        },
        duration: Date.now() - startTime,
      };
    } catch (error: any) {
      if (error.killed) {
        return {
          action: this.name,
          status: 'timeout',
          data: { commits: [], files: [], range: { from: '', to: '' } },
          duration: Date.now() - startTime,
          error: 'Execution timeout',
        };
      }

      return {
        action: this.name,
        status: 'error',
        data: { commits: [], files: [], range: { from: '', to: '' } },
        duration: Date.now() - startTime,
        error: error.message,
      };
    }
  }
}