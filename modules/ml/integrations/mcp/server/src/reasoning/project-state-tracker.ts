/**
 * Project State Tracker
 * 
 * Monitors project state including file system, git, and build status.
 * Provides real-time awareness of project changes.
 */

import { execSync } from 'child_process';
import { readdirSync, statSync } from 'fs';
import { join, extname } from 'path';
import type { ProjectState, GitState, BuildState } from '../types/context-inference.js';

/**
 * Project State Tracker
 */
export class ProjectStateTracker {
  private projectRoot: string;
  private cache: ProjectState | null = null;
  private cacheExpiry: number = 0;
  private readonly CACHE_TTL = 10_000; // 10 seconds

  constructor(projectRoot: string) {
    this.projectRoot = projectRoot;
  }

  /**
   * Get current project state (cached)
   */
  public getState(): ProjectState {
    const now = Date.now();
    
    if (this.cache && now < this.cacheExpiry) {
      return this.cache;
    }

    this.cache = this.buildState();
    this.cacheExpiry = now + this.CACHE_TTL;
    
    return this.cache;
  }

  /**
   * Force refresh state
   */
  public refresh(): ProjectState {
    this.cacheExpiry = 0;
    return this.getState();
  }

  /**
   * Build complete project state
   */
  private buildState(): ProjectState {
    return {
      root: this.projectRoot,
      git: this.getGitState(),
      build: this.getBuildState(),
      recentFiles: this.getRecentFiles(),
      fileTypes: this.getFileTypeCounts(),
      timestamp: Date.now(),
    };
  }

  /**
   * Get git repository state
   */
  private getGitState(): GitState | null {
    try {
      // Check if git repo
      execSync('git rev-parse --git-dir', {
        cwd: this.projectRoot,
        stdio: 'ignore',
      });

      // Get current branch
      const branch = execSync('git rev-parse --abbrev-ref HEAD', {
        cwd: this.projectRoot,
        encoding: 'utf-8',
      }).trim();

      // Get status
      const statusOutput = execSync('git status --porcelain', {
        cwd: this.projectRoot,
        encoding: 'utf-8',
      });

      const modified: string[] = [];
      const staged: string[] = [];
      const untracked: string[] = [];

      for (const line of statusOutput.split('\n')) {
        if (!line) continue;
        
        const status = line.substring(0, 2);
        const file = line.substring(3);
        
        if (status[0] !== ' ' && status[0] !== '?') {
          staged.push(file);
        }
        if (status[1] === 'M') {
          modified.push(file);
        }
        if (status === '??') {
          untracked.push(file);
        }
      }

      // Get last commit
      let lastCommit: string | undefined;
      let lastCommitMessage: string | undefined;
      
      try {
        lastCommit = execSync('git rev-parse --short HEAD', {
          cwd: this.projectRoot,
          encoding: 'utf-8',
        }).trim();
        
        lastCommitMessage = execSync('git log -1 --pretty=%B', {
          cwd: this.projectRoot,
          encoding: 'utf-8',
        }).trim();
      } catch {
        // No commits yet
      }

      return {
        branch,
        modified,
        staged,
        untracked,
        isDirty: modified.length > 0 || staged.length > 0 || untracked.length > 0,
        lastCommit,
        lastCommitMessage,
      };
    } catch {
      return null;
    }
  }

  /**
   * Get build state (check if nix build succeeds)
   */
  private getBuildState(): BuildState | null {
    try {
      // Try nix flake check
      execSync('nix flake check --no-build 2>&1', {
        cwd: this.projectRoot,
        encoding: 'utf-8',
        timeout: 5000, // 5s timeout
      });

      return {
        success: true,
        errors: [],
        warnings: [],
        timestamp: Date.now(),
      };
    } catch (error: any) {
      const output = error.stdout || error.stderr || '';
      
      return {
        success: false,
        errors: this.parseErrors(output),
        warnings: this.parseWarnings(output),
        timestamp: Date.now(),
      };
    }
  }

  /**
   * Parse errors from build output
   */
  private parseErrors(output: string): string[] {
    const errors: string[] = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('error:') || line.includes('ERROR')) {
        errors.push(line.trim());
      }
    }
    
    return errors.slice(0, 10); // Limit to 10 errors
  }

  /**
   * Parse warnings from build output
   */
  private parseWarnings(output: string): string[] {
    const warnings: string[] = [];
    const lines = output.split('\n');
    
    for (const line of lines) {
      if (line.includes('warning:') || line.includes('WARN')) {
        warnings.push(line.trim());
      }
    }
    
    return warnings.slice(0, 10); // Limit to 10 warnings
  }

  /**
   * Get recently modified files
   */
  private getRecentFiles(): string[] {
    try {
      const output = execSync('git diff --name-only HEAD~5..HEAD', {
        cwd: this.projectRoot,
        encoding: 'utf-8',
        timeout: 2000,
      });
      
      return output.split('\n').filter(f => f.length > 0).slice(0, 20);
    } catch {
      return [];
    }
  }

  /**
   * Count files by extension
   */
  private getFileTypeCounts(): Record<string, number> {
    const counts: Record<string, number> = {};
    
    try {
      this.walkDirectory(this.projectRoot, (file) => {
        const ext = extname(file);
        if (ext) {
          counts[ext] = (counts[ext] || 0) + 1;
        }
      });
    } catch {
      // Ignore errors
    }
    
    return counts;
  }

  /**
   * Walk directory tree (limited depth)
   */
  private walkDirectory(dir: string, callback: (file: string) => void, depth: number = 0): void {
    if (depth > 3) return; // Max depth 3
    
    try {
      const entries = readdirSync(dir);
      
      for (const entry of entries) {
        // Skip hidden and common ignore dirs
        if (entry.startsWith('.') || entry === 'node_modules' || entry === 'target') {
          continue;
        }
        
        const fullPath = join(dir, entry);
        const stat = statSync(fullPath);
        
        if (stat.isDirectory()) {
          this.walkDirectory(fullPath, callback, depth + 1);
        } else {
          callback(fullPath);
        }
      }
    } catch {
      // Ignore errors
    }
  }
}