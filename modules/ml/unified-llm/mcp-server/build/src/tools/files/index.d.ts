/**
 * File Organization & Cataloging Tools
 * Intelligent file management and search
 */
import type { FilesAnalyzeStructureArgs, FilesAutoOrganizeArgs, FilesCreateCatalogArgs, FilesSearchCatalogArgs, FilesTagManagerArgs, FileCatalogResult, ToolResult } from '../../types/extended-tools.js';
/**
 * Files Analyze Structure Tool
 */
export declare class FilesAnalyzeStructureTool {
    execute(args: FilesAnalyzeStructureArgs): Promise<ToolResult>;
    private analyzeDirectory;
}
/**
 * Files Auto Organize Tool
 */
export declare class FilesAutoOrganizeTool {
    execute(args: FilesAutoOrganizeArgs): Promise<ToolResult>;
    private getFiles;
    private determineDestination;
}
/**
 * Files Create Catalog Tool
 */
export declare class FilesCreateCatalogTool {
    execute(args: FilesCreateCatalogArgs): Promise<FileCatalogResult>;
    private scanFilesRecursive;
    private calculateChecksum;
}
/**
 * Files Search Catalog Tool
 */
export declare class FilesSearchCatalogTool {
    execute(args: FilesSearchCatalogArgs): Promise<ToolResult>;
}
/**
 * Files Tag Manager Tool
 */
export declare class FilesTagManagerTool {
    private tagsDb;
    execute(args: FilesTagManagerArgs): Promise<ToolResult>;
}
export declare const filesAnalyzeStructureSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            base_path: {
                type: string;
                description: string;
            };
            max_depth: {
                type: string;
                description: string;
            };
            min_size_mb: {
                type: string;
                description: string;
            };
            file_types: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
        };
        required: string[];
    };
};
export declare const filesAutoOrganizeSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            source_path: {
                type: string;
                description: string;
            };
            strategy: {
                type: string;
                enum: string[];
            };
            dry_run: {
                type: string;
                description: string;
            };
            custom_rules: {
                type: string;
                items: {
                    type: string;
                    properties: {
                        pattern: {
                            type: string;
                        };
                        destination: {
                            type: string;
                        };
                    };
                };
            };
        };
        required: string[];
    };
};
export declare const filesCreateCatalogSchema: {
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
            include_metadata: {
                type: string;
                description: string;
            };
            include_checksums: {
                type: string;
                description: string;
            };
            output_format: {
                type: string;
                enum: string[];
                description: string;
            };
        };
        required: string[];
    };
};
export declare const filesSearchCatalogSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            query: {
                type: string;
                description: string;
            };
            filters: {
                type: string;
                properties: {
                    file_type: {
                        type: string;
                    };
                    min_size: {
                        type: string;
                    };
                    max_size: {
                        type: string;
                    };
                    date_range: {
                        type: string;
                        properties: {
                            start: {
                                type: string;
                            };
                            end: {
                                type: string;
                            };
                        };
                    };
                };
            };
        };
        required: string[];
    };
};
export declare const filesTagManagerSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            action: {
                type: string;
                enum: string[];
            };
            file_path: {
                type: string;
                description: string;
            };
            tags: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=index.d.ts.map