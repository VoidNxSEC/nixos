/**
 * Sensitive Data Handling Tools
 * Pseudonymization, encryption, and audit
 */
import type { DataScanSensitiveArgs, DataPseudonymizeArgs, DataEncryptSensitiveArgs, DataAuditAccessArgs, SensitiveDataScanResult, ToolResult } from '../../types/extended-tools.js';
/**
 * Data Scan Sensitive Tool
 */
export declare class DataScanSensitiveTool {
    private patterns;
    execute(args: DataScanSensitiveArgs): Promise<SensitiveDataScanResult>;
    private getFiles;
    private maskContext;
}
/**
 * Data Pseudonymize Tool
 */
export declare class DataPseudonymizeTool {
    execute(args: DataPseudonymizeArgs): Promise<ToolResult>;
    private pseudonymizeObject;
    private pseudonymizeLine;
    private pseudonymizeValue;
}
/**
 * Data Encrypt Sensitive Tool (SOPS Integration)
 */
export declare class DataEncryptSensitiveTool {
    execute(args: DataEncryptSensitiveArgs): Promise<ToolResult>;
}
/**
 * Data Audit Access Tool
 */
export declare class DataAuditAccessTool {
    execute(args: DataAuditAccessArgs): Promise<ToolResult>;
}
export declare const dataScanSensitiveSchema: {
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
            patterns: {
                type: string;
                items: {
                    type: string;
                    enum: string[];
                };
                description: string;
            };
            custom_regex: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            recursive: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const dataPseudonymizeSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            input_file: {
                type: string;
                description: string;
            };
            output_file: {
                type: string;
                description: string;
            };
            fields: {
                type: string;
                items: {
                    type: string;
                };
                description: string;
            };
            method: {
                type: string;
                enum: string[];
            };
            preserve_format: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const dataEncryptSensitiveSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            file_path: {
                type: string;
                description: string;
            };
            operation: {
                type: string;
                enum: string[];
            };
            output_path: {
                type: string;
                description: string;
            };
            key_id: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
export declare const dataAuditAccessSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            resource_type: {
                type: string;
                enum: string[];
            };
            resource_path: {
                type: string;
                description: string;
            };
            time_range: {
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
        required: string[];
    };
};
//# sourceMappingURL=index.d.ts.map