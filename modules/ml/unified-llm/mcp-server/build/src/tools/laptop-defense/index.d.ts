/**
 * Laptop Defense Framework Tools
 *
 * MCP tools for thermal protection, hardware forensics, and rebuild safety
 */
export declare const laptopDefenseTools: ({
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            max_temp: {
                type: string;
                description: string;
                default: number;
            };
            duration?: undefined;
            skip_rebuild?: undefined;
            evidence_dir?: undefined;
        };
        required?: undefined;
    };
    defer_loading?: undefined;
    allowed_callers?: undefined;
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    allowed_callers: string[];
    inputSchema: {
        type: string;
        properties: {
            duration: {
                type: string;
                description: string;
                default: number;
            };
            skip_rebuild: {
                type: string;
                description: string;
                default: boolean;
            };
            max_temp?: undefined;
            evidence_dir?: undefined;
        };
        required?: undefined;
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            duration: {
                type: string;
                description: string;
                default: number;
            };
            max_temp?: undefined;
            skip_rebuild?: undefined;
            evidence_dir?: undefined;
        };
        required?: undefined;
    };
    allowed_callers?: undefined;
} | {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            max_temp?: undefined;
            duration?: undefined;
            skip_rebuild?: undefined;
            evidence_dir?: undefined;
        };
        required?: undefined;
    };
    defer_loading?: undefined;
    allowed_callers?: undefined;
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    allowed_callers: string[];
    inputSchema: {
        type: string;
        properties: {
            evidence_dir: {
                type: string;
                description: string;
            };
            max_temp?: undefined;
            duration?: undefined;
            skip_rebuild?: undefined;
        };
        required: string[];
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    allowed_callers: string[];
    inputSchema: {
        type: string;
        properties: {
            max_temp?: undefined;
            duration?: undefined;
            skip_rebuild?: undefined;
            evidence_dir?: undefined;
        };
        required?: undefined;
    };
} | {
    name: string;
    description: string;
    defer_loading: boolean;
    inputSchema: {
        type: string;
        properties: {
            max_temp?: undefined;
            duration?: undefined;
            skip_rebuild?: undefined;
            evidence_dir?: undefined;
        };
        required?: undefined;
    };
    allowed_callers?: undefined;
})[];
interface ThermalCheckResult {
    current_temp: number;
    max_acceptable: number;
    safe: boolean;
    status: 'safe' | 'warning' | 'critical';
    message: string;
}
interface RebuildSafetyResult {
    thermal_temp: number;
    thermal_safe: boolean;
    memory_available_mb: number;
    memory_safe: boolean;
    load_average: number;
    load_safe: boolean;
    verdict: 'SAFE' | 'UNSAFE';
    reasons: string[];
}
interface ForensicsResult {
    success: boolean;
    evidence_dir: string;
    archive: string;
    phases_completed: string[];
    max_temp_observed: number;
    verdict_preview: string;
    message: string;
}
interface VerdictResult {
    score: number;
    critical_flags: number;
    verdict: 'REPLACE' | 'INVESTIGATE' | 'SOFTWARE_ISSUE';
    reasons: string[];
    recommendations: string[];
}
export declare function handleThermalCheck(maxTemp?: number): Promise<ThermalCheckResult>;
export declare function handleRebuildSafetyCheck(): Promise<RebuildSafetyResult>;
export declare function handleThermalForensics(duration?: number, skipRebuild?: boolean): Promise<ForensicsResult>;
export declare function handleThermalWarroom(duration?: number): Promise<{
    success: boolean;
    samples: number;
    message: string;
}>;
export declare function handleLaptopVerdict(evidenceDir: string): Promise<VerdictResult>;
export declare function handleFullInvestigation(): Promise<{
    forensics: ForensicsResult;
    verdict: VerdictResult;
}>;
export declare function handleForceCooldown(): Promise<{
    success: boolean;
    message: string;
}>;
export declare function handleResetPerformance(): Promise<{
    success: boolean;
    message: string;
}>;
export {};
//# sourceMappingURL=index.d.ts.map