/**
 * Nix Tools Coordinator
 * 
 * Main interface for all Nix development tools.
 */

import { FlakeOps } from './flake-ops.js';
import { PackageSearch } from './package-search.js';
import { BuildAnalyzer } from './build-analyzer.js';
import type {
  FlakeBuildResult,
  FlakeMetadata,
  NixPackage,
  BuildAnalysis,
} from '../../types/nix-tools.js';

/**
 * Nix Tools
 */
export class NixTools {
  private flakeOps: FlakeOps;
  private packageSearch: PackageSearch;
  private buildAnalyzer: BuildAnalyzer;

  constructor(projectRoot: string) {
    this.flakeOps = new FlakeOps(projectRoot);
    this.packageSearch = new PackageSearch();
    this.buildAnalyzer = new BuildAnalyzer();
  }

  // Flake Operations
  public async buildFlake(output?: string): Promise<FlakeBuildResult> {
    return this.flakeOps.build(output);
  }

  public async checkFlake(): Promise<FlakeBuildResult> {
    return this.flakeOps.check();
  }

  public async updateFlake(input?: string): Promise<FlakeBuildResult> {
    return this.flakeOps.update(input);
  }

  public async showFlake(): Promise<FlakeMetadata> {
    return this.flakeOps.show();
  }

  public async evalExpression(expr: string): Promise<string> {
    return this.flakeOps.eval(expr);
  }

  // Package Search
  public async searchPackages(query: string, limit?: number): Promise<NixPackage[]> {
    return this.packageSearch.search(query, limit);
  }

  public async getPackageInfo(attrPath: string): Promise<NixPackage | null> {
    return this.packageSearch.getPackageInfo(attrPath);
  }

  // Build Analysis
  public analyzeBuild(buildLog: string): BuildAnalysis {
    return this.buildAnalyzer.analyze(buildLog);
  }

  public generateBuildSummary(analysis: BuildAnalysis): string {
    return this.buildAnalyzer.generateSummary(analysis);
  }
}