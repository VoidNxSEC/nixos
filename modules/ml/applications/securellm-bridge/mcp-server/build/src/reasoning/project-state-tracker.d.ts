/**
 * Project State Tracker
 *
 * Monitors project state including file system, git, and build status.
 * Provides real-time awareness of project changes.
 */
import type { ProjectState } from '../types/context-inference.js';
/**
 * Project State Tracker
 */
export declare class ProjectStateTracker {
    private projectRoot;
    private cache;
    private cacheExpiry;
    private readonly CACHE_TTL;
    constructor(projectRoot: string);
    /**
     * Get current project state (cached)
     */
    getState(): ProjectState;
    /**
     * Force refresh state
     */
    refresh(): ProjectState;
    /**
     * Build complete project state
     */
    private buildState;
    /**
     * Get git repository state
     */
    private getGitState;
    /**
     * Get build state (check if nix build succeeds)
     */
    private getBuildState;
    /**
     * Parse errors from build output
     */
    private parseErrors;
    /**
     * Parse warnings from build output
     */
    private parseWarnings;
    /**
     * Get recently modified files
     */
    private getRecentFiles;
    /**
     * Count files by extension
     */
    private getFileTypeCounts;
    /**
     * Walk directory tree (limited depth)
     */
    private walkDirectory;
}
//# sourceMappingURL=project-state-tracker.d.ts.map