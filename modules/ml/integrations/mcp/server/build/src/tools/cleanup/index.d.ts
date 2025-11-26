/**
 * Data Cleanup Tools
 * Intelligent cleanup with complex criteria
 */
import type { CleanupAnalyzeWasteArgs, CleanupExecuteSmartArgs, CleanupDuplicateResolverArgs, CleanupLogRotationArgs, ToolResult, CleanupAnalysisResult } from '../../types/extended-tools.js';
/**
 * Cleanup Analyze Waste Tool
 */
export declare class CleanupAnalyzeWasteTool {
    execute(args: CleanupAnalyzeWasteArgs): Promise<CleanupAnalysisResult>;
    private scanDirectory;
    private matchPattern;
}
/**
 * Cleanup Execute Smart Tool
 */
export declare class CleanupExecuteSmartTool {
    execute(args: CleanupExecuteSmartArgs): Promise<ToolResult>;
}
/**
 * Cleanup Duplicate Resolver Tool
 */
export declare class CleanupDuplicateResolverTool {
    execute(args: CleanupDuplicateResolverArgs): Promise<ToolResult>;
    private scanForDuplicates;
    private hashFile;
    private resolveDuplicates;
    private sortByStrategy;
}
/**
 * Cleanup Log Rotation Tool
 */
export declare class CleanupLogRotationTool {
    execute(args: CleanupLogRotationArgs): Promise<ToolResult>;
    private rotateAndCompress;
}
export declare const cleanupAnalyzeWasteSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            paths: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            criteria: {
                type: string;
                properties: {
                    age_days: {
                        type: string;
                        description: string;
                    };
                    min_size_mb: {
                        type: string;
                        description: string;
                    };
                    file_patterns: {
                        type: string;
                        items: {
                            type: string;
                        };
                        description: string;
                    };
                    exclude_patterns: {
                        type: string;
                        items: {
                            type: string;
                        };
                        description: string;
                    };
                };
            };
        };
        required: string[];
    };
};
export declare const cleanupExecuteSmartSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            analysis_id: {
                type: string;
                description: string;
            };
            dry_run: {
                type: string;
                description: string;
            };
            max_delete_size_gb: {
                type: string;
                description: string;
            };
            preserve_recent_days: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const cleanupDuplicateResolverSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            paths: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            strategy: {
                type: string;
                enum: string[];
            };
            hash_algorithm: {
                type: string;
                enum: string[];
                description: string;
            };
            min_size_mb: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const cleanupLogRotationSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            log_paths: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            max_size_mb: {
                type: string;
                description: string;
            };
            max_age_days: {
                type: string;
                description: string;
            };
            compress: {
                type: string;
                description: string;
            };
            keep_files: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=index.d.ts.map