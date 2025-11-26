/**
 * Nix Build Analyzer
 *
 * Analyzes Nix build logs and provides insights.
 */
import type { BuildAnalysis } from '../../types/nix-tools.js';
/**
 * Build Analyzer
 */
export declare class BuildAnalyzer {
    /**
     * Analyze build log
     */
    analyze(buildLog: string): BuildAnalysis;
    /**
     * Parse size string to bytes
     */
    private parseSize;
    /**
     * Normalize time to seconds
     */
    private normalizeTime;
    /**
     * Generate build summary
     */
    generateSummary(analysis: BuildAnalysis): string;
    /**
     * Format time duration
     */
    private formatTime;
    /**
     * Format bytes
     */
    private formatBytes;
}
//# sourceMappingURL=build-analyzer.d.ts.map