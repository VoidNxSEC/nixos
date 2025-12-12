/**
 * Nix Package Search
 *
 * Search for Nix packages across nixpkgs and other channels.
 */
import { execSync } from 'child_process';
/**
 * Package Search
 */
export class PackageSearch {
    /**
     * Search for packages
     */
    async search(query, limit = 20) {
        try {
            // Use nix search for fast searching
            const output = execSync(`nix search nixpkgs ${query} --json`, {
                encoding: 'utf-8',
                timeout: 30000,
                maxBuffer: 5 * 1024 * 1024,
            });
            const results = JSON.parse(output);
            const packages = [];
            for (const [attrPath, info] of Object.entries(results)) {
                const pkgInfo = info;
                packages.push({
                    name: pkgInfo.pname || this.extractName(attrPath),
                    version: pkgInfo.version || 'unknown',
                    description: pkgInfo.description,
                    attrPath,
                });
                if (packages.length >= limit)
                    break;
            }
            return packages;
        }
        catch (error) {
            // Fallback to simpler search if JSON fails
            return this.fallbackSearch(query, limit);
        }
    }
    /**
     * Get package info
     */
    async getPackageInfo(attrPath) {
        try {
            const output = execSync(`nix eval nixpkgs#${attrPath}.meta --json`, {
                encoding: 'utf-8',
                timeout: 10000,
            });
            const meta = JSON.parse(output);
            return {
                name: meta.pname || this.extractName(attrPath),
                version: meta.version || 'unknown',
                description: meta.description,
                attrPath,
            };
        }
        catch {
            return null;
        }
    }
    /**
     * Fallback search using grep
     */
    async fallbackSearch(query, limit) {
        try {
            const output = execSync(`nix search nixpkgs ${query}`, {
                encoding: 'utf-8',
                timeout: 30000,
                maxBuffer: 5 * 1024 * 1024,
            });
            return this.parseTextOutput(output, limit);
        }
        catch {
            return [];
        }
    }
    /**
     * Parse text search output
     */
    parseTextOutput(output, limit) {
        const packages = [];
        const lines = output.split('\n');
        let currentPackage = null;
        for (const line of lines) {
            if (line.startsWith('*')) {
                // New package entry
                if (currentPackage && currentPackage.attrPath) {
                    packages.push(currentPackage);
                    if (packages.length >= limit)
                        break;
                }
                const match = line.match(/\* ([^\s]+) \(([^)]+)\)/);
                if (match) {
                    currentPackage = {
                        attrPath: match[1],
                        version: match[2],
                        name: this.extractName(match[1]),
                    };
                }
            }
            else if (currentPackage && line.trim()) {
                // Description line
                currentPackage.description = line.trim();
            }
        }
        // Add last package
        if (currentPackage && currentPackage.attrPath) {
            packages.push(currentPackage);
        }
        return packages;
    }
    /**
     * Extract package name from attribute path
     */
    extractName(attrPath) {
        const parts = attrPath.split('.');
        return parts[parts.length - 1];
    }
}
//# sourceMappingURL=package-search.js.map