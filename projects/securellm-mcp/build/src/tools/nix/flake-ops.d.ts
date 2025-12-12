/**
 * Nix Flake Operations
 *
 * Provides operations for Nix flakes: build, check, update, etc.
 */
import type { FlakeBuildResult, FlakeMetadata } from '../../types/nix-tools.js';
/**
 * Flake Operations
 */
export declare class FlakeOps {
    private projectRoot;
    constructor(projectRoot: string);
    /**
     * Build a flake output
     */
    build(output?: string): Promise<FlakeBuildResult>;
    /**
     * Check flake (run all checks)
     */
    check(): Promise<FlakeBuildResult>;
    /**
     * Update flake inputs
     */
    update(input?: string): Promise<FlakeBuildResult>;
    /**
     * Show flake metadata
     */
    show(): Promise<FlakeMetadata>;
    /**
     * Evaluate Nix expression
     */
    eval(expression: string): Promise<string>;
    /**
     * Enter development shell
     */
    develop(shell?: string): Promise<FlakeBuildResult>;
    /**
     * Execute flake command
     */
    private executeFlakeCommand;
    /**
     * Extract output path from build output
     */
    private extractOutputPath;
    /**
     * Extract errors from output
     */
    private extractErrors;
    /**
     * Extract warnings from output
     */
    private extractWarnings;
    /**
     * Parse flake inputs
     */
    private parseInputs;
}
//# sourceMappingURL=flake-ops.d.ts.map