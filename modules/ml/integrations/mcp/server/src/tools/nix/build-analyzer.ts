/**
 * Nix Build Analyzer
 * 
 * Analyzes Nix build logs and provides insights.
 */

import type { BuildAnalysis } from '../../types/nix-tools.js';

/**
 * Build Analyzer
 */
export class BuildAnalyzer {
  /**
   * Analyze build log
   */
  public analyze(buildLog: string): BuildAnalysis {
    const lines = buildLog.split('\n');
    
    let totalTime = 0;
    let derivationsBuilt = 0;
    const failures: string[] = [];
    const warnings: string[] = [];
    let cacheHits = 0;
    let cacheMisses = 0;
    const downloads: Array<{ name: string; size: number }> = [];

    for (const line of lines) {
      // Count derivations
      if (line.includes('building') && line.includes('/nix/store/')) {
        derivationsBuilt++;
      }

      // Detect cache hits
      if (line.includes('copying path') || line.includes('from cache')) {
        cacheHits++;
      }

      // Detect cache misses (actual builds)
      if (line.includes('building') && !line.includes('copying')) {
        cacheMisses++;
      }

      // Extract failures
      if (line.includes('error:') || line.includes('ERROR') || line.includes('failed')) {
        failures.push(line.trim());
      }

      // Extract warnings
      if (line.includes('warning:') || line.includes('WARN')) {
        warnings.push(line.trim());
      }

      // Extract downloads
      const downloadMatch = line.match(/downloading '([^']+)'.*?(\d+(?:\.\d+)?)\s*([KMG]iB)/);
      if (downloadMatch) {
        downloads.push({
          name: downloadMatch[1],
          size: this.parseSize(downloadMatch[2], downloadMatch[3]),
        });
      }

      // Extract build time
      const timeMatch = line.match(/built in (\d+(?:\.\d+)?)\s*([smh])/);
      if (timeMatch) {
        const value = parseFloat(timeMatch[1]);
        const unit = timeMatch[2];
        totalTime += this.normalizeTime(value, unit);
      }
    }

    return {
      totalTime,
      derivationsBuilt,
      failures,
      warnings,
      cacheHits,
      cacheMisses,
      downloads,
    };
  }

  /**
   * Parse size string to bytes
   */
  private parseSize(value: string, unit: string): number {
    const num = parseFloat(value);
    
    switch (unit) {
      case 'KiB': return num * 1024;
      case 'MiB': return num * 1024 * 1024;
      case 'GiB': return num * 1024 * 1024 * 1024;
      default: return num;
    }
  }

  /**
   * Normalize time to seconds
   */
  private normalizeTime(value: number, unit: string): number {
    switch (unit) {
      case 's': return value;
      case 'm': return value * 60;
      case 'h': return value * 3600;
      default: return value;
    }
  }

  /**
   * Generate build summary
   */
  public generateSummary(analysis: BuildAnalysis): string {
    const lines: string[] = [];
    
    lines.push(`Build Summary:`);
    lines.push(`  Total Time: ${this.formatTime(analysis.totalTime)}`);
    lines.push(`  Derivations Built: ${analysis.derivationsBuilt}`);
    lines.push(`  Cache Hits: ${analysis.cacheHits}`);
    lines.push(`  Cache Misses: ${analysis.cacheMisses}`);
    
    if (analysis.downloads.length > 0) {
      const totalSize = analysis.downloads.reduce((sum, d) => sum + d.size, 0);
      lines.push(`  Downloads: ${analysis.downloads.length} (${this.formatBytes(totalSize)})`);
    }
    
    if (analysis.warnings.length > 0) {
      lines.push(`  Warnings: ${analysis.warnings.length}`);
    }
    
    if (analysis.failures.length > 0) {
      lines.push(`  Failures: ${analysis.failures.length}`);
      analysis.failures.forEach(f => lines.push(`    - ${f}`));
    }
    
    return lines.join('\n');
  }

  /**
   * Format time duration
   */
  private formatTime(seconds: number): string {
    if (seconds < 60) return `${seconds.toFixed(1)}s`;
    if (seconds < 3600) return `${(seconds / 60).toFixed(1)}m`;
    return `${(seconds / 3600).toFixed(1)}h`;
  }

  /**
   * Format bytes
   */
  private formatBytes(bytes: number): string {
    if (bytes < 1024) return `${bytes}B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)}GB`;
  }
}