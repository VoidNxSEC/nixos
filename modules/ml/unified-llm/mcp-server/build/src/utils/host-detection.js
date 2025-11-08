/**
 * NixOS Host Detection Utility
 *
 * Intelligently selects which NixOS host configuration to use based on:
 * 1. NIXOS_HOST_NAME environment variable (explicit)
 * 2. Single host in flake (automatic)
 * 3. System hostname matching flake host (convention)
 * 4. First host alphabetically (fallback with warning)
 */
import { exec } from "child_process";
import { promisify } from "util";
import { getNixOSHosts } from "./flake-parser.js";
const execAsync = promisify(exec);
/**
 * Get the system hostname
 */
async function getSystemHostname() {
    try {
        const { stdout } = await execAsync("hostname");
        return stdout.trim();
    }
    catch (error) {
        console.warn("Failed to get system hostname:", error);
        return null;
    }
}
/**
 * Detect which NixOS host configuration to use
 *
 * @param projectRoot - Path to the project root (containing flake.nix)
 * @returns HostDetectionResult with selected hostname and detection metadata
 */
export async function detectNixOSHost(projectRoot) {
    const warnings = [];
    // Get all available hosts from flake
    let availableHosts;
    try {
        availableHosts = await getNixOSHosts(projectRoot);
    }
    catch (error) {
        return {
            hostname: "",
            method: "error",
            confidence: "low",
            availableHosts: [],
            warnings: [
                `Failed to parse flake.nix: ${error instanceof Error ? error.message : String(error)}`,
            ],
        };
    }
    if (availableHosts.length === 0) {
        return {
            hostname: "",
            method: "error",
            confidence: "low",
            availableHosts: [],
            warnings: [
                "No nixosConfigurations found in flake.nix",
                "Please ensure your flake.nix contains nixosConfigurations output",
            ],
        };
    }
    // Priority 1: Explicit NIXOS_HOST_NAME environment variable
    const envHostName = process.env.NIXOS_HOST_NAME;
    if (envHostName) {
        if (availableHosts.includes(envHostName)) {
            return {
                hostname: envHostName,
                method: "env_var",
                confidence: "high",
                availableHosts,
                warnings: [],
            };
        }
        else {
            warnings.push(`NIXOS_HOST_NAME="${envHostName}" not found in flake.nix. Available: ${availableHosts.join(", ")}`);
        }
    }
    // Priority 2: Single host in flake (automatic selection)
    if (availableHosts.length === 1) {
        return {
            hostname: availableHosts[0],
            method: "single_host",
            confidence: "high",
            availableHosts,
            warnings,
        };
    }
    // Priority 3: System hostname matching flake host (convention)
    const systemHostname = await getSystemHostname();
    if (systemHostname && availableHosts.includes(systemHostname)) {
        return {
            hostname: systemHostname,
            method: "system_hostname",
            confidence: "medium",
            availableHosts,
            warnings: [
                ...warnings,
                `Using system hostname "${systemHostname}". Set NIXOS_HOST_NAME to override.`,
            ],
        };
    }
    // Priority 4: First host alphabetically (fallback)
    const sortedHosts = [...availableHosts].sort();
    const fallbackHost = sortedHosts[0];
    warnings.push(`Multiple hosts available but could not determine which to use.`, `Available hosts: ${availableHosts.join(", ")}`, `Using fallback: "${fallbackHost}" (first alphabetically)`, `To explicitly select a host, set NIXOS_HOST_NAME environment variable.`);
    return {
        hostname: fallbackHost,
        method: "fallback_first",
        confidence: "low",
        availableHosts,
        warnings,
    };
}
/**
 * Get NixOS host with error handling
 *
 * @param projectRoot - Path to the project root
 * @returns Hostname or throws descriptive error
 */
export async function requireNixOSHost(projectRoot) {
    const result = await detectNixOSHost(projectRoot);
    // Log warnings
    if (result.warnings.length > 0) {
        console.warn("NixOS Host Detection Warnings:");
        result.warnings.forEach((warning) => console.warn(`  - ${warning}`));
    }
    // Handle errors
    if (result.method === "error" || !result.hostname) {
        throw new Error(`Failed to detect NixOS host.\n${result.warnings.join("\n")}`);
    }
    // Log detection result
    console.log(`Detected NixOS host: "${result.hostname}" (method: ${result.method}, confidence: ${result.confidence})`);
    return result.hostname;
}
//# sourceMappingURL=host-detection.js.map