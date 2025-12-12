import { z } from "zod";
import type { ConfigureResult } from "../types/package-debugger.js";
export declare const packageConfigureSchema: z.ZodObject<{
    package_name: z.ZodString;
    package_type: z.ZodEnum<["tar", "deb", "js"]>;
    storage_file: z.ZodString;
    sha256: z.ZodString;
    options: z.ZodDefault<z.ZodOptional<z.ZodObject<{
        method: z.ZodOptional<z.ZodEnum<["auto", "native", "fhs"]>>;
        sandbox: z.ZodDefault<z.ZodOptional<z.ZodBoolean>>;
        audit: z.ZodDefault<z.ZodOptional<z.ZodBoolean>>;
        executable: z.ZodOptional<z.ZodString>;
        npm_flags: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
    }, "strip", z.ZodTypeAny, {
        sandbox: boolean;
        audit: boolean;
        method?: "auto" | "native" | "fhs" | undefined;
        executable?: string | undefined;
        npm_flags?: string[] | undefined;
    }, {
        method?: "auto" | "native" | "fhs" | undefined;
        sandbox?: boolean | undefined;
        audit?: boolean | undefined;
        executable?: string | undefined;
        npm_flags?: string[] | undefined;
    }>>>;
}, "strip", z.ZodTypeAny, {
    options: {
        sandbox: boolean;
        audit: boolean;
        method?: "auto" | "native" | "fhs" | undefined;
        executable?: string | undefined;
        npm_flags?: string[] | undefined;
    };
    package_type: "tar" | "deb" | "js";
    package_name: string;
    sha256: string;
    storage_file: string;
}, {
    package_type: "tar" | "deb" | "js";
    package_name: string;
    sha256: string;
    storage_file: string;
    options?: {
        method?: "auto" | "native" | "fhs" | undefined;
        sandbox?: boolean | undefined;
        audit?: boolean | undefined;
        executable?: string | undefined;
        npm_flags?: string[] | undefined;
    } | undefined;
}>;
export type PackageConfigureInput = z.infer<typeof packageConfigureSchema>;
export declare class PackageConfigureTool {
    private workspaceDir;
    constructor(workspaceDir: string);
    /**
     * Main configure function
     */
    configure(input: PackageConfigureInput): Promise<ConfigureResult>;
    /**
     * Configure TAR package
     */
    private configureTarPackage;
    /**
     * Configure JavaScript/NPM package
     */
    private configureJsPackage;
    /**
     * Configure DEB package
     */
    private configureDebPackage;
    /**
     * Inspect tarball structure
     */
    private inspectTarball;
    /**
     * Inspect NPM package
     */
    private inspectNpmPackage;
    /**
     * List files in tarball
     */
    private listTarballFiles;
    /**
     * Extract specific file from tarball
     */
    private extractFileFromTarball;
    /**
     * Select appropriate build method
     */
    private selectBuildMethod;
    /**
     * Map common license strings to nixpkgs license identifiers
     */
    private mapLicense;
    /**
     * Get configuration file path
     */
    private getConfigFilePath;
}
//# sourceMappingURL=package-configure.d.ts.map