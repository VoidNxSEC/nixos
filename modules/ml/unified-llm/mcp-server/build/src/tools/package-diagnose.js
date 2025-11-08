// Package Diagnose Tool - Analyze package configuration and detect issues
import { z } from "zod";
import { spawn } from "child_process";
import { readFile } from "fs/promises";
import { ErrorClassifier } from "../intelligence/error-classifier.js";
// Input schema for package_diagnose tool
export const packageDiagnoseSchema = z.object({
    package_path: z.string().describe("Path to the package .nix file (e.g., modules/packages/tar-packages/packages/lynis.nix)"),
    package_type: z.enum(["tar", "deb", "js"]).describe("Type of package system (tar-packages, deb-packages, js-packages)"),
    build_test: z.boolean().optional().default(true).describe("Whether to perform a test build to detect issues"),
});
export class PackageDiagnoseTool {
    errorClassifier;
    workspaceDir;
    hostname;
    constructor(workspaceDir, hostname = "default") {
        this.errorClassifier = new ErrorClassifier();
        this.workspaceDir = workspaceDir;
        this.hostname = hostname;
    }
    /**
     * Main diagnose function
     */
    async diagnose(input) {
        const startTime = Date.now();
        const issues = [];
        try {
            // Step 1: Validate configuration file exists and is readable
            const configValidation = await this.validateConfig(input.package_path);
            if (!configValidation.valid) {
                issues.push({
                    type: "config_error",
                    severity: "critical",
                    location: input.package_path,
                    problem: "Configuration file not found or not readable",
                    cause: configValidation.error || "Unknown error",
                    solution: "Verify the file path is correct and the file exists",
                    fix_command: "Check path and permissions",
                });
                return {
                    success: false,
                    package_name: this.extractPackageName(input.package_path),
                    package_type: input.package_type,
                    build_status: "failed",
                    issues,
                    suggestions: ["Verify package path and file permissions"],
                    execution_time_ms: Date.now() - startTime,
                };
            }
            // Step 2: Parse and analyze configuration
            const configAnalysis = await this.analyzeConfig(input.package_path, input.package_type);
            if (configAnalysis.issues) {
                issues.push(...configAnalysis.issues);
            }
            // Step 3: Test build if requested
            let buildStatus = "not_tested";
            if (input.build_test) {
                const buildResult = await this.testBuild(input.package_path, input.package_type);
                buildStatus = buildResult.status;
                if (buildResult.errors) {
                    // Classify all errors found
                    const classifiedIssues = this.errorClassifier.classifyAllErrors(buildResult.errors);
                    issues.push(...classifiedIssues);
                }
            }
            // Step 4: Generate suggestions based on issues
            const suggestions = this.generateSuggestions(issues);
            // Step 5: Determine success
            const hasCritical = issues.some((i) => i.severity === "critical");
            const success = !hasCritical && buildStatus !== "failed";
            return {
                success,
                package_name: configAnalysis.package_name || this.extractPackageName(input.package_path),
                package_type: input.package_type,
                build_status: buildStatus,
                issues: issues.length > 0 ? issues : undefined,
                suggestions,
                execution_time_ms: Date.now() - startTime,
            };
        }
        catch (error) {
            return {
                success: false,
                package_name: this.extractPackageName(input.package_path),
                package_type: input.package_type,
                build_status: "failed",
                issues: [
                    {
                        type: "unknown",
                        severity: "critical",
                        location: "diagnose process",
                        problem: "Unexpected error during diagnosis",
                        cause: error instanceof Error ? error.message : String(error),
                        solution: "Review error details and try again",
                        fix_command: "Manual investigation required",
                    },
                ],
                suggestions: ["Check system logs", "Verify NixOS configuration"],
                execution_time_ms: Date.now() - startTime,
            };
        }
    }
    /**
     * Validate configuration file
     */
    async validateConfig(path) {
        try {
            await readFile(`${this.workspaceDir}/${path}`, "utf-8");
            return { valid: true };
        }
        catch (error) {
            return {
                valid: false,
                error: error instanceof Error ? error.message : "Unknown error",
            };
        }
    }
    /**
     * Analyze configuration for potential issues
     */
    async analyzeConfig(path, packageType) {
        try {
            const content = await readFile(`${this.workspaceDir}/${path}`, "utf-8");
            const issues = [];
            let packageName;
            // Extract package name
            const nameMatch = content.match(/^\s*(\w+)\s*=/m);
            if (nameMatch) {
                packageName = nameMatch[1];
            }
            // Check for common configuration issues based on package type
            switch (packageType) {
                case "tar":
                    if (!content.includes("executable =")) {
                        issues.push({
                            type: "config_error",
                            severity: "warning",
                            location: path,
                            problem: "Missing executable definition",
                            cause: "Executable path not specified in wrapper configuration",
                            solution: "Add executable path in wrapper.executable",
                            fix_command: "Add 'wrapper.executable' field to configuration",
                        });
                    }
                    if (!content.includes("sha256")) {
                        issues.push({
                            type: "hash_error",
                            severity: "critical",
                            location: path,
                            problem: "Missing SHA256 hash",
                            cause: "Source hash not specified",
                            solution: "Add sha256 hash for the source tarball",
                            fix_command: "Add 'source.sha256' field to configuration",
                        });
                    }
                    break;
                case "js":
                    if (!content.includes("npmDepsHash")) {
                        issues.push({
                            type: "hash_error",
                            severity: "warning",
                            location: path,
                            problem: "Missing npmDepsHash",
                            cause: "npm dependencies hash not specified",
                            solution: "Run build once to get npmDepsHash from error message",
                            fix_command: "Build package and copy hash from error output",
                        });
                    }
                    break;
                case "deb":
                    if (!content.includes("sha256")) {
                        issues.push({
                            type: "hash_error",
                            severity: "critical",
                            location: path,
                            problem: "Missing SHA256 hash",
                            cause: "Source hash not specified",
                            solution: "Add sha256 hash for the .deb file",
                            fix_command: "Add 'source.sha256' field to configuration",
                        });
                    }
                    break;
            }
            return { package_name: packageName, issues: issues.length > 0 ? issues : undefined };
        }
        catch (error) {
            return {
                issues: [
                    {
                        type: "config_error",
                        severity: "critical",
                        location: path,
                        problem: "Failed to analyze configuration",
                        cause: error instanceof Error ? error.message : "Unknown error",
                        solution: "Check file syntax and permissions",
                        fix_command: "Review configuration file",
                    },
                ],
            };
        }
    }
    /**
     * Test build the package
     */
    async testBuild(path, packageType) {
        return new Promise((resolve) => {
            // Determine the Nix attribute path based on package type
            const packageName = this.extractPackageName(path);
            const attrPath = this.getAttributePath(packageType, packageName);
            const buildProcess = spawn("nix", ["build", `${this.workspaceDir}#${attrPath}`, "--no-link"], {
                cwd: this.workspaceDir,
                shell: true,
            });
            let stderr = "";
            let stdout = "";
            buildProcess.stdout.on("data", (data) => {
                stdout += data.toString();
            });
            buildProcess.stderr.on("data", (data) => {
                stderr += data.toString();
            });
            buildProcess.on("close", (code) => {
                if (code === 0) {
                    resolve({ status: "success" });
                }
                else {
                    resolve({
                        status: "failed",
                        errors: stderr || stdout || "Build failed with no error output",
                    });
                }
            });
            buildProcess.on("error", (error) => {
                resolve({
                    status: "failed",
                    errors: `Failed to start build process: ${error.message}`,
                });
            });
            // Set a timeout of 5 minutes
            setTimeout(() => {
                buildProcess.kill();
                resolve({
                    status: "failed",
                    errors: "Build timed out after 5 minutes",
                });
            }, 5 * 60 * 1000);
        });
    }
    /**
     * Get Nix attribute path for package
     */
    getAttributePath(packageType, packageName) {
        switch (packageType) {
            case "tar":
                return `${this.hostname}.packages.tar.packages.${packageName}`;
            case "deb":
                return `${this.hostname}.packages.deb.packages.${packageName}`;
            case "js":
                return `${this.hostname}.packages.${packageName}`;
            default:
                return packageName;
        }
    }
    /**
     * Extract package name from path
     */
    extractPackageName(path) {
        const match = path.match(/\/([^/]+)\.nix$/);
        return match ? match[1] : "unknown";
    }
    /**
     * Generate suggestions based on issues found
     */
    generateSuggestions(issues) {
        const suggestions = new Set();
        for (const issue of issues) {
            if (issue.solution) {
                suggestions.add(issue.solution);
            }
            // Add specific suggestions based on issue type
            switch (issue.type) {
                case "hash_mismatch":
                    suggestions.add("Update the hash value with the correct one from the error message");
                    break;
                case "directory_execution":
                    suggestions.add("Verify tarball structure and adjust executable path accordingly");
                    break;
                case "dependency_missing":
                    suggestions.add("Add missing dependencies to nativeBuildInputs or buildInputs");
                    break;
                case "broken_symlink":
                    suggestions.add("Add postInstall script to clean up broken symlinks");
                    break;
            }
        }
        // Add general suggestions if no specific issues
        if (issues.length === 0) {
            suggestions.add("Configuration appears valid");
            suggestions.add("Consider running security audit with package validation");
        }
        return Array.from(suggestions);
    }
}
//# sourceMappingURL=package-diagnose.js.map