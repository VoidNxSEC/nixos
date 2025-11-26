/**
 * Nix Package Search
 *
 * Search for Nix packages across nixpkgs and other channels.
 */
import type { NixPackage } from '../../types/nix-tools.js';
/**
 * Package Search
 */
export declare class PackageSearch {
    /**
     * Search for packages
     */
    search(query: string, limit?: number): Promise<NixPackage[]>;
    /**
     * Get package info
     */
    getPackageInfo(attrPath: string): Promise<NixPackage | null>;
    /**
     * Fallback search using grep
     */
    private fallbackSearch;
    /**
     * Parse text search output
     */
    private parseTextOutput;
    /**
     * Extract package name from attribute path
     */
    private extractName;
}
//# sourceMappingURL=package-search.d.ts.map