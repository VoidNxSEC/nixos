/**
 * NixOS Host Detection Utility
 *
 * Intelligently selects which NixOS host configuration to use based on:
 * 1. NIXOS_HOST_NAME environment variable (explicit)
 * 2. Single host in flake (automatic)
 * 3. System hostname matching flake host (convention)
 * 4. First host alphabetically (fallback with warning)
 */
export interface HostDetectionResult {
    hostname: string;
    method: "env_var" | "single_host" | "system_hostname" | "fallback_first" | "error";
    confidence: "high" | "medium" | "low";
    availableHosts: string[];
    warnings: string[];
}
/**
 * Detect which NixOS host configuration to use
 *
 * @param projectRoot - Path to the project root (containing flake.nix)
 * @returns HostDetectionResult with selected hostname and detection metadata
 */
export declare function detectNixOSHost(projectRoot: string): Promise<HostDetectionResult>;
/**
 * Get NixOS host with error handling
 *
 * @param projectRoot - Path to the project root
 * @returns Hostname or throws descriptive error
 */
export declare function requireNixOSHost(projectRoot: string): Promise<string>;
//# sourceMappingURL=host-detection.d.ts.map