/**
 * Data Cleanup Tools
 * Intelligent cleanup with complex criteria
 */
import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as crypto from 'crypto';
const execAsync = promisify(exec);
/**
 * Cleanup Analyze Waste Tool
 */
export class CleanupAnalyzeWasteTool {
    async execute(args) {
        const { paths, criteria = {} } = args;
        const { age_days = 30, min_size_mb = 10, file_patterns = ['*.log', '*.tmp', '*.cache'], exclude_patterns = [] } = criteria;
        try {
            const recommendations = [];
            let totalWasteMB = 0;
            let filesAnalyzed = 0;
            for (const basePath of paths) {
                const files = await this.scanDirectory(basePath, file_patterns, exclude_patterns);
                for (const file of files) {
                    try {
                        const stats = await fs.stat(file);
                        const sizeMB = stats.size / (1024 * 1024);
                        const ageDays = (Date.now() - stats.mtime.getTime()) / (1000 * 60 * 60 * 24);
                        filesAnalyzed++;
                        // Analyze if file is waste
                        let isWaste = false;
                        let reason = '';
                        let confidence = 0;
                        if (ageDays > age_days && sizeMB > min_size_mb) {
                            isWaste = true;
                            reason = `Old file (${Math.floor(ageDays)} days) and large (${sizeMB.toFixed(2)} MB)`;
                            confidence = 0.9;
                        }
                        else if (file.includes('.tmp') || file.includes('.cache')) {
                            isWaste = true;
                            reason = 'Temporary/cache file';
                            confidence = 0.8;
                        }
                        else if (file.match(/\.log\.\d+$/)) {
                            isWaste = true;
                            reason = 'Rotated log file';
                            confidence = 0.7;
                        }
                        if (isWaste) {
                            recommendations.push({
                                path: file,
                                size_mb: parseFloat(sizeMB.toFixed(2)),
                                reason,
                                confidence,
                            });
                            totalWasteMB += sizeMB;
                        }
                    }
                    catch (error) {
                        // Skip files we can't access
                    }
                }
            }
            // Sort by size (largest first)
            recommendations.sort((a, b) => b.size_mb - a.size_mb);
            const analysisId = `analysis-${Date.now()}`;
            return {
                success: true,
                data: {
                    analysis_id: analysisId,
                    total_waste_mb: parseFloat(totalWasteMB.toFixed(2)),
                    files_analyzed: filesAnalyzed,
                    recommendations: recommendations.slice(0, 100), // Limit to top 100
                },
                warnings: totalWasteMB > 1000 ? [`Large amount of waste detected: ${totalWasteMB.toFixed(2)} MB`] : undefined,
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Waste analysis failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async scanDirectory(basePath, patterns, excludePatterns) {
        const files = [];
        try {
            const entries = await fs.readdir(basePath, { withFileTypes: true });
            for (const entry of entries) {
                const fullPath = path.join(basePath, entry.name);
                // Check exclude patterns
                if (excludePatterns.some(p => fullPath.includes(p))) {
                    continue;
                }
                if (entry.isDirectory()) {
                    files.push(...await this.scanDirectory(fullPath, patterns, excludePatterns));
                }
                else if (entry.isFile()) {
                    // Check if matches pattern
                    if (patterns.some(p => this.matchPattern(entry.name, p))) {
                        files.push(fullPath);
                    }
                }
            }
        }
        catch (error) {
            // Skip directories we can't access
        }
        return files;
    }
    matchPattern(filename, pattern) {
        const regex = new RegExp('^' + pattern.replace(/\*/g, '.*').replace(/\?/g, '.') + '$');
        return regex.test(filename);
    }
}
/**
 * Cleanup Execute Smart Tool
 */
export class CleanupExecuteSmartTool {
    async execute(args) {
        const { analysis_id, dry_run = true, max_delete_size_gb = 10, preserve_recent_days = 7 } = args;
        // In production, would load analysis from storage
        return {
            success: true,
            data: {
                analysis_id,
                dry_run,
                files_deleted: dry_run ? 0 : 'N/A',
                space_freed_mb: 0,
                message: dry_run ? 'Dry run - no files deleted' : 'Cleanup executed',
            },
            warnings: ['Smart cleanup requires stored analysis - simplified implementation'],
            timestamp: new Date().toISOString(),
        };
    }
}
/**
 * Cleanup Duplicate Resolver Tool
 */
export class CleanupDuplicateResolverTool {
    async execute(args) {
        const { paths, strategy, hash_algorithm = 'sha256', min_size_mb = 1 } = args;
        try {
            const fileHashes = new Map(); // hash -> [paths]
            let filesScanned = 0;
            for (const basePath of paths) {
                await this.scanForDuplicates(basePath, fileHashes, hash_algorithm, min_size_mb * 1024 * 1024);
                filesScanned++;
            }
            const duplicateGroups = Array.from(fileHashes.entries())
                .filter(([hash, files]) => files.length > 1)
                .map(([hash, files]) => ({ hash, files, count: files.length }));
            let resolution = { message: 'Duplicates found', groups: duplicateGroups.length };
            if (strategy !== 'interactive' && duplicateGroups.length > 0) {
                resolution = await this.resolveDuplicates(duplicateGroups, strategy);
            }
            return {
                success: true,
                data: {
                    duplicates_found: duplicateGroups.length,
                    total_files_in_duplicates: duplicateGroups.reduce((sum, g) => sum + g.count, 0),
                    duplicate_groups: duplicateGroups.slice(0, 20), // Limit output
                    resolution,
                    strategy,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Duplicate resolution failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async scanForDuplicates(basePath, fileHashes, algorithm, minSize) {
        try {
            const entries = await fs.readdir(basePath, { withFileTypes: true });
            for (const entry of entries) {
                const fullPath = path.join(basePath, entry.name);
                if (entry.isDirectory()) {
                    await this.scanForDuplicates(fullPath, fileHashes, algorithm, minSize);
                }
                else if (entry.isFile()) {
                    const stats = await fs.stat(fullPath);
                    if (stats.size >= minSize) {
                        const hash = await this.hashFile(fullPath, algorithm);
                        const existing = fileHashes.get(hash) || [];
                        existing.push(fullPath);
                        fileHashes.set(hash, existing);
                    }
                }
            }
        }
        catch (error) {
            // Skip directories we can't access
        }
    }
    async hashFile(filePath, algorithm) {
        const content = await fs.readFile(filePath);
        return crypto.createHash(algorithm).update(content).digest('hex');
    }
    async resolveDuplicates(groups, strategy) {
        let keptFiles = 0;
        let removedFiles = 0;
        for (const group of groups) {
            const sorted = await this.sortByStrategy(group.files, strategy);
            keptFiles++;
            removedFiles += sorted.length - 1;
        }
        return {
            strategy,
            files_kept: keptFiles,
            files_marked_for_removal: removedFiles,
            message: 'Dry run - no files actually removed',
        };
    }
    async sortByStrategy(files, strategy) {
        const filesWithStats = await Promise.all(files.map(async (f) => ({
            path: f,
            stats: await fs.stat(f),
        })));
        switch (strategy) {
            case 'keep_newest':
                return filesWithStats.sort((a, b) => b.stats.mtime.getTime() - a.stats.mtime.getTime()).map(f => f.path);
            case 'keep_oldest':
                return filesWithStats.sort((a, b) => a.stats.mtime.getTime() - b.stats.mtime.getTime()).map(f => f.path);
            case 'keep_largest':
                return filesWithStats.sort((a, b) => b.stats.size - a.stats.size).map(f => f.path);
            default:
                return files;
        }
    }
}
/**
 * Cleanup Log Rotation Tool
 */
export class CleanupLogRotationTool {
    async execute(args) {
        const { log_paths, max_size_mb = 100, max_age_days = 30, compress = true, keep_files = 5 } = args;
        try {
            const results = [];
            for (const logPath of log_paths) {
                try {
                    const stats = await fs.stat(logPath);
                    const sizeMB = stats.size / (1024 * 1024);
                    const ageDays = (Date.now() - stats.mtime.getTime()) / (1000 * 60 * 60 * 24);
                    let action = 'no_action';
                    let reason = '';
                    if (sizeMB > max_size_mb) {
                        action = 'rotate';
                        reason = `File exceeds ${max_size_mb}MB (${sizeMB.toFixed(2)}MB)`;
                        if (compress) {
                            await this.rotateAndCompress(logPath, keep_files);
                        }
                    }
                    else if (ageDays > max_age_days) {
                        action = 'archive';
                        reason = `File older than ${max_age_days} days`;
                    }
                    results.push({
                        path: logPath,
                        size_mb: parseFloat(sizeMB.toFixed(2)),
                        age_days: Math.floor(ageDays),
                        action,
                        reason,
                    });
                }
                catch (error) {
                    results.push({
                        path: logPath,
                        error: error.message,
                    });
                }
            }
            return {
                success: true,
                data: {
                    logs_processed: results.length,
                    logs_rotated: results.filter(r => r.action === 'rotate').length,
                    logs_archived: results.filter(r => r.action === 'archive').length,
                    results,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Log rotation failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async rotateAndCompress(logPath, keepFiles) {
        const dir = path.dirname(logPath);
        const base = path.basename(logPath);
        // Rotate existing files
        for (let i = keepFiles - 1; i >= 1; i--) {
            const oldFile = path.join(dir, `${base}.${i}.gz`);
            const newFile = path.join(dir, `${base}.${i + 1}.gz`);
            try {
                await fs.rename(oldFile, newFile);
            }
            catch {
                // File might not exist
            }
        }
        // Compress current log
        const { stdout } = await execAsync(`gzip -c ${logPath} > ${logPath}.1.gz`);
        // Truncate original log
        await fs.writeFile(logPath, '');
    }
}
// Export schemas
export const cleanupAnalyzeWasteSchema = {
    name: "cleanup_analyze_waste",
    description: "Analyze directories for waste files based on complex criteria",
    inputSchema: {
        type: "object",
        properties: {
            paths: { type: "array", items: { type: "string" }, description: "Directories to analyze" },
            criteria: {
                type: "object",
                properties: {
                    age_days: { type: "number", description: "Min age in days (default: 30)" },
                    min_size_mb: { type: "number", description: "Min size in MB (default: 10)" },
                    file_patterns: { type: "array", items: { type: "string" }, description: "File patterns to match" },
                    exclude_patterns: { type: "array", items: { type: "string" }, description: "Patterns to exclude" },
                },
            },
        },
        required: ["paths"],
    },
};
export const cleanupExecuteSmartSchema = {
    name: "cleanup_execute_smart",
    description: "Execute smart cleanup based on previous analysis",
    inputSchema: {
        type: "object",
        properties: {
            analysis_id: { type: "string", description: "Analysis ID from analyze_waste" },
            dry_run: { type: "boolean", description: "Dry run mode (default: true)" },
            max_delete_size_gb: { type: "number", description: "Max GB to delete (safety limit)" },
            preserve_recent_days: { type: "number", description: "Preserve files from last N days" },
        },
        required: ["analysis_id"],
    },
};
export const cleanupDuplicateResolverSchema = {
    name: "cleanup_duplicate_resolver",
    description: "Find and resolve duplicate files using hash comparison",
    inputSchema: {
        type: "object",
        properties: {
            paths: { type: "array", items: { type: "string" }, description: "Directories to scan" },
            strategy: { type: "string", enum: ["keep_newest", "keep_largest", "keep_oldest", "interactive"] },
            hash_algorithm: { type: "string", enum: ["md5", "sha256"], description: "Default: sha256" },
            min_size_mb: { type: "number", description: "Min file size to check (default: 1 MB)" },
        },
        required: ["paths", "strategy"],
    },
};
export const cleanupLogRotationSchema = {
    name: "cleanup_log_rotation",
    description: "Rotate and compress log files based on size and age",
    inputSchema: {
        type: "object",
        properties: {
            log_paths: { type: "array", items: { type: "string" }, description: "Log files to manage" },
            max_size_mb: { type: "number", description: "Max size before rotation (default: 100)" },
            max_age_days: { type: "number", description: "Max age before archival (default: 30)" },
            compress: { type: "boolean", description: "Compress rotated logs (default: true)" },
            keep_files: { type: "number", description: "Number of rotated files to keep (default: 5)" },
        },
        required: ["log_paths"],
    },
};
//# sourceMappingURL=index.js.map