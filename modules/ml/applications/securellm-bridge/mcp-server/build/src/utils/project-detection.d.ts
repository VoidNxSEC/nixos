/**
 * Project Root Detection Utility
 *
 * Automatically detects the project root directory by searching for flake.nix
 * upward from the current working directory.
 *
 * Priority:
 * 1. Explicit PROJECT_ROOT environment variable
 * 2. Search for flake.nix upward from cwd
 * 3. Fallback to process.cwd()
 */
export interface ProjectDetectionResult {
    projectRoot: string;
    method: "env_var" | "flake_search" | "fallback";
    flakeFound: boolean;
}
/**
 * Detect the project root directory
 *
 * @returns ProjectDetectionResult with the detected root and detection method
 * @throws Error if no valid project root can be determined
 */
export declare function detectProjectRoot(): Promise<ProjectDetectionResult>;
/**
 * Verify that a directory is a valid Nix project
 */
export declare function isValidNixProject(dir: string): Promise<boolean>;
//# sourceMappingURL=project-detection.d.ts.map