/**
 * File Organization & Cataloging Tools
 * Intelligent file management and search
 */
import * as fs from 'fs/promises';
import * as path from 'path';
import * as crypto from 'crypto';
import Database from 'better-sqlite3';
/**
 * Files Analyze Structure Tool
 */
export class FilesAnalyzeStructureTool {
    async execute(args) {
        const { base_path, max_depth = 5, min_size_mb = 0, file_types = [] } = args;
        try {
            const analysis = await this.analyzeDirectory(base_path, 0, max_depth, min_size_mb * 1024 * 1024, file_types);
            return {
                success: true,
                data: {
                    base_path,
                    total_files: analysis.fileCount,
                    total_directories: analysis.dirCount,
                    total_size_mb: parseFloat((analysis.totalSize / (1024 * 1024)).toFixed(2)),
                    by_extension: analysis.byExtension,
                    largest_files: analysis.largestFiles.slice(0, 20),
                    deepest_path: analysis.deepestPath,
                    max_depth_reached: analysis.maxDepthReached,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Structure analysis failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async analyzeDirectory(dirPath, currentDepth, maxDepth, minSize, fileTypes) {
        const analysis = {
            fileCount: 0,
            dirCount: 0,
            totalSize: 0,
            byExtension: {},
            largestFiles: [],
            deepestPath: { path: dirPath, depth: currentDepth },
            maxDepthReached: currentDepth,
        };
        if (currentDepth >= maxDepth) {
            return analysis;
        }
        try {
            const entries = await fs.readdir(dirPath, { withFileTypes: true });
            for (const entry of entries) {
                const fullPath = path.join(dirPath, entry.name);
                if (entry.isDirectory()) {
                    analysis.dirCount++;
                    const subAnalysis = await this.analyzeDirectory(fullPath, currentDepth + 1, maxDepth, minSize, fileTypes);
                    analysis.fileCount += subAnalysis.fileCount;
                    analysis.dirCount += subAnalysis.dirCount;
                    analysis.totalSize += subAnalysis.totalSize;
                    // Merge extensions
                    for (const [ext, data] of Object.entries(subAnalysis.byExtension)) {
                        if (!analysis.byExtension[ext]) {
                            analysis.byExtension[ext] = { count: 0, size: 0 };
                        }
                        const extData = data;
                        analysis.byExtension[ext].count += extData.count;
                        analysis.byExtension[ext].size += extData.size;
                    }
                    analysis.largestFiles.push(...subAnalysis.largestFiles);
                    if (subAnalysis.maxDepthReached > analysis.maxDepthReached) {
                        analysis.maxDepthReached = subAnalysis.maxDepthReached;
                        analysis.deepestPath = subAnalysis.deepestPath;
                    }
                }
                else if (entry.isFile()) {
                    const stats = await fs.stat(fullPath);
                    if (stats.size >= minSize) {
                        const ext = path.extname(entry.name).toLowerCase() || 'no_extension';
                        if (fileTypes.length === 0 || fileTypes.includes(ext)) {
                            analysis.fileCount++;
                            analysis.totalSize += stats.size;
                            if (!analysis.byExtension[ext]) {
                                analysis.byExtension[ext] = { count: 0, size: 0 };
                            }
                            analysis.byExtension[ext].count++;
                            analysis.byExtension[ext].size += stats.size;
                            analysis.largestFiles.push({
                                path: fullPath,
                                size_mb: parseFloat((stats.size / (1024 * 1024)).toFixed(2)),
                            });
                        }
                    }
                }
            }
            // Sort largest files
            analysis.largestFiles.sort((a, b) => b.size_mb - a.size_mb);
            analysis.largestFiles = analysis.largestFiles.slice(0, 50); // Keep top 50
        }
        catch (error) {
            // Skip directories we can't access
        }
        return analysis;
    }
}
/**
 * Files Auto Organize Tool
 */
export class FilesAutoOrganizeTool {
    async execute(args) {
        const { source_path, strategy, dry_run = true, custom_rules = [] } = args;
        try {
            const operations = [];
            const files = await this.getFiles(source_path);
            for (const file of files) {
                const dest = await this.determineDestination(file, strategy, source_path, custom_rules);
                if (dest && dest !== file) {
                    operations.push({
                        from: file,
                        to: dest,
                        reason: `Strategy: ${strategy}`,
                    });
                    if (!dry_run) {
                        await fs.mkdir(path.dirname(dest), { recursive: true });
                        await fs.rename(file, dest);
                    }
                }
            }
            return {
                success: true,
                data: {
                    source_path,
                    strategy,
                    dry_run,
                    files_processed: files.length,
                    files_to_move: operations.length,
                    operations: operations.slice(0, 50), // Limit output
                },
                warnings: dry_run ? ['Dry run - no files actually moved'] : undefined,
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Auto organization failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async getFiles(dirPath) {
        const files = [];
        const entries = await fs.readdir(dirPath, { withFileTypes: true });
        for (const entry of entries) {
            const fullPath = path.join(dirPath, entry.name);
            if (entry.isFile()) {
                files.push(fullPath);
            }
        }
        return files;
    }
    async determineDestination(file, strategy, basePath, customRules) {
        const fileName = path.basename(file);
        const ext = path.extname(fileName).toLowerCase();
        const stats = await fs.stat(file);
        // Check custom rules first
        for (const rule of customRules) {
            if (fileName.match(new RegExp(rule.pattern))) {
                return path.join(basePath, rule.destination, fileName);
            }
        }
        switch (strategy) {
            case 'by_type':
                const typeMap = {
                    '.jpg': 'images', '.jpeg': 'images', '.png': 'images', '.gif': 'images',
                    '.pdf': 'documents', '.doc': 'documents', '.docx': 'documents', '.txt': 'documents',
                    '.mp4': 'videos', '.avi': 'videos', '.mkv': 'videos',
                    '.mp3': 'audio', '.wav': 'audio', '.flac': 'audio',
                    '.zip': 'archives', '.tar': 'archives', '.gz': 'archives',
                };
                const folder = typeMap[ext] || 'others';
                return path.join(basePath, folder, fileName);
            case 'by_date':
                const year = stats.mtime.getFullYear();
                const month = String(stats.mtime.getMonth() + 1).padStart(2, '0');
                return path.join(basePath, `${year}`, `${month}`, fileName);
            case 'by_size':
                const sizeMB = stats.size / (1024 * 1024);
                const sizeFolder = sizeMB < 1 ? 'small' : sizeMB < 100 ? 'medium' : 'large';
                return path.join(basePath, sizeFolder, fileName);
            default:
                return file;
        }
    }
}
/**
 * Files Create Catalog Tool
 */
export class FilesCreateCatalogTool {
    async execute(args) {
        const { paths, include_metadata = true, include_checksums = false, output_format = 'sqlite' } = args;
        try {
            const catalogId = `catalog-${Date.now()}`;
            const catalogPath = `/tmp/${catalogId}.db`;
            const db = new Database(catalogPath);
            db.exec(`
        CREATE TABLE IF NOT EXISTS files (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          path TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          extension TEXT,
          size_bytes INTEGER,
          modified_time TEXT,
          checksum TEXT,
          mime_type TEXT,
          indexed_at TEXT
        );
        CREATE INDEX idx_name ON files(name);
        CREATE INDEX idx_extension ON files(extension);
      `);
            const insertStmt = db.prepare(`
        INSERT OR REPLACE INTO files 
        (path, name, extension, size_bytes, modified_time, checksum, indexed_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);
            let filesIndexed = 0;
            let totalSize = 0;
            for (const basePath of paths) {
                const files = await this.scanFilesRecursive(basePath);
                for (const file of files) {
                    try {
                        const stats = await fs.stat(file);
                        const name = path.basename(file);
                        const ext = path.extname(name).toLowerCase();
                        let checksum = null;
                        if (include_checksums) {
                            checksum = await this.calculateChecksum(file);
                        }
                        insertStmt.run(file, name, ext, stats.size, stats.mtime.toISOString(), checksum, new Date().toISOString());
                        filesIndexed++;
                        totalSize += stats.size;
                    }
                    catch (error) {
                        // Skip files we can't access
                    }
                }
            }
            db.close();
            return {
                success: true,
                data: {
                    catalog_id: catalogId,
                    files_indexed: filesIndexed,
                    total_size_bytes: totalSize,
                    catalog_path: catalogPath,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Catalog creation failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async scanFilesRecursive(dirPath) {
        const files = [];
        try {
            const entries = await fs.readdir(dirPath, { withFileTypes: true });
            for (const entry of entries) {
                const fullPath = path.join(dirPath, entry.name);
                if (entry.isDirectory()) {
                    files.push(...await this.scanFilesRecursive(fullPath));
                }
                else if (entry.isFile()) {
                    files.push(fullPath);
                }
            }
        }
        catch (error) {
            // Skip directories we can't access
        }
        return files;
    }
    async calculateChecksum(filePath) {
        const content = await fs.readFile(filePath);
        return crypto.createHash('sha256').update(content).digest('hex');
    }
}
/**
 * Files Search Catalog Tool
 */
export class FilesSearchCatalogTool {
    async execute(args) {
        const { query, filters = {} } = args;
        try {
            // In production, would use actual catalog database
            return {
                success: true,
                data: {
                    query,
                    filters,
                    results: [],
                    message: 'Catalog search requires catalog ID from create_catalog',
                },
                warnings: ['Simplified implementation - requires integration with catalog DB'],
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Catalog search failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
/**
 * Files Tag Manager Tool
 */
export class FilesTagManagerTool {
    tagsDb = new Map(); // file -> tags
    async execute(args) {
        const { action, file_path, tags = [] } = args;
        try {
            switch (action) {
                case 'add':
                    if (!file_path)
                        throw new Error('file_path required for add action');
                    const existing = this.tagsDb.get(file_path) || new Set();
                    tags.forEach(t => existing.add(t));
                    this.tagsDb.set(file_path, existing);
                    return {
                        success: true,
                        data: { file_path, tags: Array.from(existing), action: 'added' },
                        timestamp: new Date().toISOString(),
                    };
                case 'remove':
                    if (!file_path)
                        throw new Error('file_path required for remove action');
                    const fileTags = this.tagsDb.get(file_path);
                    if (fileTags) {
                        tags.forEach(t => fileTags.delete(t));
                        if (fileTags.size === 0) {
                            this.tagsDb.delete(file_path);
                        }
                    }
                    return {
                        success: true,
                        data: { file_path, tags: fileTags ? Array.from(fileTags) : [], action: 'removed' },
                        timestamp: new Date().toISOString(),
                    };
                case 'search':
                    const matches = [];
                    for (const [file, fileTags] of this.tagsDb.entries()) {
                        if (tags.every(t => fileTags.has(t))) {
                            matches.push(file);
                        }
                    }
                    return {
                        success: true,
                        data: { tags, matches, count: matches.length },
                        timestamp: new Date().toISOString(),
                    };
                case 'list':
                    const allFiles = Array.from(this.tagsDb.entries()).map(([file, tags]) => ({
                        file,
                        tags: Array.from(tags),
                    }));
                    return {
                        success: true,
                        data: { files: allFiles, count: allFiles.length },
                        timestamp: new Date().toISOString(),
                    };
                default:
                    throw new Error(`Unknown action: ${action}`);
            }
        }
        catch (error) {
            return {
                success: false,
                error: `Tag management failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
// Export schemas
export const filesAnalyzeStructureSchema = {
    name: "files_analyze_structure",
    description: "Analyze directory structure with detailed statistics",
    inputSchema: {
        type: "object",
        properties: {
            base_path: { type: "string", description: "Base directory to analyze" },
            max_depth: { type: "number", description: "Maximum depth to traverse (default: 5)" },
            min_size_mb: { type: "number", description: "Minimum file size in MB (default: 0)" },
            file_types: { type: "array", items: { type: "string" }, description: "File extensions to include" },
        },
        required: ["base_path"],
    },
};
export const filesAutoOrganizeSchema = {
    name: "files_auto_organize",
    description: "Automatically organize files by type, date, size, or custom rules",
    inputSchema: {
        type: "object",
        properties: {
            source_path: { type: "string", description: "Source directory" },
            strategy: { type: "string", enum: ["by_type", "by_date", "by_size", "by_project", "custom"] },
            dry_run: { type: "boolean", description: "Preview without moving (default: true)" },
            custom_rules: {
                type: "array",
                items: {
                    type: "object",
                    properties: {
                        pattern: { type: "string" },
                        destination: { type: "string" },
                    },
                },
            },
        },
        required: ["source_path", "strategy"],
    },
};
export const filesCreateCatalogSchema = {
    name: "files_create_catalog",
    description: "Create searchable file catalog with SQLite",
    inputSchema: {
        type: "object",
        properties: {
            paths: { type: "array", items: { type: "string" }, description: "Paths to catalog" },
            include_metadata: { type: "boolean", description: "Include file metadata (default: true)" },
            include_checksums: { type: "boolean", description: "Calculate SHA256 checksums (default: false)" },
            output_format: { type: "string", enum: ["json", "sqlite", "csv"], description: "Default: sqlite" },
        },
        required: ["paths"],
    },
};
export const filesSearchCatalogSchema = {
    name: "files_search_catalog",
    description: "Search file catalog with filters",
    inputSchema: {
        type: "object",
        properties: {
            query: { type: "string", description: "Search query" },
            filters: {
                type: "object",
                properties: {
                    file_type: { type: "string" },
                    min_size: { type: "number" },
                    max_size: { type: "number" },
                    date_range: {
                        type: "object",
                        properties: {
                            start: { type: "string" },
                            end: { type: "string" },
                        },
                    },
                },
            },
        },
        required: ["query"],
    },
};
export const filesTagManagerSchema = {
    name: "files_tag_manager",
    description: "Manage file tags for organization and search",
    inputSchema: {
        type: "object",
        properties: {
            action: { type: "string", enum: ["add", "remove", "search", "list"] },
            file_path: { type: "string", description: "File path (for add/remove)" },
            tags: { type: "array", items: { type: "string" }, description: "Tags to add/remove/search" },
        },
        required: ["action"],
    },
};
//# sourceMappingURL=index.js.map