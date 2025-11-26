/**
 * Nix Tools Coordinator
 *
 * Main interface for all Nix development tools.
 */
import { FlakeOps } from './flake-ops.js';
import { PackageSearch } from './package-search.js';
import { BuildAnalyzer } from './build-analyzer.js';
/**
 * Nix Tools
 */
export class NixTools {
    flakeOps;
    packageSearch;
    buildAnalyzer;
    constructor(projectRoot) {
        this.flakeOps = new FlakeOps(projectRoot);
        this.packageSearch = new PackageSearch();
        this.buildAnalyzer = new BuildAnalyzer();
    }
    // Flake Operations
    async buildFlake(output) {
        return this.flakeOps.build(output);
    }
    async checkFlake() {
        return this.flakeOps.check();
    }
    async updateFlake(input) {
        return this.flakeOps.update(input);
    }
    async showFlake() {
        return this.flakeOps.show();
    }
    async evalExpression(expr) {
        return this.flakeOps.eval(expr);
    }
    // Package Search
    async searchPackages(query, limit) {
        return this.packageSearch.search(query, limit);
    }
    async getPackageInfo(attrPath) {
        return this.packageSearch.getPackageInfo(attrPath);
    }
    // Build Analysis
    analyzeBuild(buildLog) {
        return this.buildAnalyzer.analyze(buildLog);
    }
    generateBuildSummary(analysis) {
        return this.buildAnalyzer.generateSummary(analysis);
    }
}
//# sourceMappingURL=nix-tools.js.map