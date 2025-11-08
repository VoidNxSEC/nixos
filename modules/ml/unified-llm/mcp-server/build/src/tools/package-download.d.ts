import { z } from "zod";
import type { DownloadResult } from "../types/package-debugger.js";
export declare const packageDownloadSchema: z.ZodObject<{
    package_name: z.ZodString;
    package_type: z.ZodEnum<["tar", "deb", "js"]>;
    source: z.ZodObject<{
        type: z.ZodEnum<["github_release", "npm", "url"]>;
        url: z.ZodOptional<z.ZodString>;
        github: z.ZodOptional<z.ZodObject<{
            repo: z.ZodString;
            tag: z.ZodOptional<z.ZodString>;
            asset_pattern: z.ZodOptional<z.ZodString>;
        }, "strip", z.ZodTypeAny, {
            repo: string;
            tag?: string | undefined;
            asset_pattern?: string | undefined;
        }, {
            repo: string;
            tag?: string | undefined;
            asset_pattern?: string | undefined;
        }>>;
        npm: z.ZodOptional<z.ZodObject<{
            package: z.ZodString;
            version: z.ZodOptional<z.ZodString>;
        }, "strip", z.ZodTypeAny, {
            package: string;
            version?: string | undefined;
        }, {
            package: string;
            version?: string | undefined;
        }>>;
    }, "strip", z.ZodTypeAny, {
        type: "github_release" | "npm" | "url";
        npm?: {
            package: string;
            version?: string | undefined;
        } | undefined;
        url?: string | undefined;
        github?: {
            repo: string;
            tag?: string | undefined;
            asset_pattern?: string | undefined;
        } | undefined;
    }, {
        type: "github_release" | "npm" | "url";
        npm?: {
            package: string;
            version?: string | undefined;
        } | undefined;
        url?: string | undefined;
        github?: {
            repo: string;
            tag?: string | undefined;
            asset_pattern?: string | undefined;
        } | undefined;
    }>;
}, "strip", z.ZodTypeAny, {
    package_type: "tar" | "deb" | "js";
    package_name: string;
    source: {
        type: "github_release" | "npm" | "url";
        npm?: {
            package: string;
            version?: string | undefined;
        } | undefined;
        url?: string | undefined;
        github?: {
            repo: string;
            tag?: string | undefined;
            asset_pattern?: string | undefined;
        } | undefined;
    };
}, {
    package_type: "tar" | "deb" | "js";
    package_name: string;
    source: {
        type: "github_release" | "npm" | "url";
        npm?: {
            package: string;
            version?: string | undefined;
        } | undefined;
        url?: string | undefined;
        github?: {
            repo: string;
            tag?: string | undefined;
            asset_pattern?: string | undefined;
        } | undefined;
    };
}>;
export type PackageDownloadInput = z.infer<typeof packageDownloadSchema>;
export declare class PackageDownloadTool {
    private workspaceDir;
    constructor(workspaceDir: string);
    /**
     * Main download function
     */
    download(input: PackageDownloadInput): Promise<DownloadResult>;
    /**
     * Download from GitHub release
     */
    private downloadFromGitHub;
    /**
     * Get GitHub release info
     */
    private getGitHubReleaseInfo;
    /**
     * Find matching asset from release
     */
    private findMatchingAsset;
    /**
     * Download from NPM
     */
    private downloadFromNpm;
    /**
     * Get NPM package info
     */
    private getNpmPackageInfo;
    /**
     * Download from direct URL
     */
    private downloadFromUrl;
    /**
     * Download file using curl
     */
    private downloadFile;
    /**
     * Calculate SHA256 hash of a file
     */
    private calculateSha256;
    /**
     * Get file information
     */
    private getFileInfo;
    /**
     * Get storage directory for package type
     */
    private getStorageDir;
    /**
     * Generate configuration template
     */
    private generateConfigTemplate;
}
//# sourceMappingURL=package-download.d.ts.map