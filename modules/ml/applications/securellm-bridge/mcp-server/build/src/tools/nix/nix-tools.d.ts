/**
 * Nix Tools Coordinator
 *
 * Main interface for all Nix development tools.
 */
import type { FlakeBuildResult, FlakeMetadata, NixPackage, BuildAnalysis } from '../../types/nix-tools.js';
/**
 * Nix Tools
 */
export declare class NixTools {
    private flakeOps;
    private packageSearch;
    private buildAnalyzer;
    constructor(projectRoot: string);
    buildFlake(output?: string): Promise<FlakeBuildResult>;
    checkFlake(): Promise<FlakeBuildResult>;
    updateFlake(input?: string): Promise<FlakeBuildResult>;
    showFlake(): Promise<FlakeMetadata>;
    evalExpression(expr: string): Promise<string>;
    searchPackages(query: string, limit?: number): Promise<NixPackage[]>;
    getPackageInfo(attrPath: string): Promise<NixPackage | null>;
    analyzeBuild(buildLog: string): BuildAnalysis;
    generateBuildSummary(analysis: BuildAnalysis): string;
}
//# sourceMappingURL=nix-tools.d.ts.map