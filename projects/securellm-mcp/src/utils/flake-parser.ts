/**
 * Flake.nix Parser Utility
 *
 * Parses flake.nix to extract nixosConfigurations and other metadata.
 * Uses pattern matching instead of full Nix evaluation for simplicity and safety.
 */

import * as fs from "fs/promises";
import * as path from "path";

export interface NixOSConfiguration {
  name: string;
  system?: string;
}

export interface FlakeInfo {
  nixosConfigurations: NixOSConfiguration[];
  hasPackages: boolean;
  hasDevShells: boolean;
}

/**
 * Extract nixosConfigurations from flake.nix content
 *
 * Uses regex pattern matching to find nixosConfigurations block
 * and extract the configuration names.
 */
function extractNixOSConfigurations(content: string): NixOSConfiguration[] {
  const configurations: NixOSConfiguration[] = [];

  // Pattern 1: nixosConfigurations = { name = ...; }
  const pattern1 = /nixosConfigurations\s*=\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}/s;
  const match1 = content.match(pattern1);

  if (match1) {
    const configBlock = match1[1];

    // Extract configuration names (looking for "name = " or "name.modules")
    const namePattern = /^\s*(\w+)\s*=/gm;
    let nameMatch;

    while ((nameMatch = namePattern.exec(configBlock)) !== null) {
      const configName = nameMatch[1];
      // Filter out common Nix keywords that might appear
      if (!["lib", "pkgs", "inputs", "outputs", "self"].includes(configName)) {
        configurations.push({ name: configName });
      }
    }
  }

  // Pattern 2: nixosConfigurations.name = ...
  const pattern2 = /nixosConfigurations\.(\w+)\s*=/g;
  let match2;

  while ((match2 = pattern2.exec(content)) !== null) {
    const configName = match2[1];
    if (!configurations.some((c) => c.name === configName)) {
      configurations.push({ name: configName });
    }
  }

  return configurations;
}

/**
 * Check if flake has packages output
 */
function hasPackagesOutput(content: string): boolean {
  return /packages\s*=/.test(content);
}

/**
 * Check if flake has devShells output
 */
function hasDevShellsOutput(content: string): boolean {
  return /devShells\s*=/.test(content);
}

/**
 * Parse flake.nix file and extract configuration information
 *
 * @param flakePath - Path to flake.nix file or directory containing it
 * @returns FlakeInfo object with extracted information
 * @throws Error if flake.nix cannot be read or parsed
 */
export async function parseFlake(flakePath: string): Promise<FlakeInfo> {
  // Determine actual file path
  let filePath = flakePath;
  try {
    const stat = await fs.stat(flakePath);
    if (stat.isDirectory()) {
      filePath = path.join(flakePath, "flake.nix");
    }
  } catch (error) {
    throw new Error(`Cannot access flake path: ${flakePath}`);
  }

  // Read flake.nix content
  let content: string;
  try {
    content = await fs.readFile(filePath, "utf-8");
  } catch (error) {
    throw new Error(
      `Cannot read flake.nix at ${filePath}: ${
        error instanceof Error ? error.message : String(error)
      }`
    );
  }

  // Parse configurations
  const nixosConfigurations = extractNixOSConfigurations(content);
  const hasPackages = hasPackagesOutput(content);
  const hasDevShells = hasDevShellsOutput(content);

  return {
    nixosConfigurations,
    hasPackages,
    hasDevShells,
  };
}

/**
 * Get all NixOS configuration names from a flake
 *
 * @param flakePath - Path to flake.nix or directory containing it
 * @returns Array of configuration names
 */
export async function getNixOSHosts(flakePath: string): Promise<string[]> {
  const flakeInfo = await parseFlake(flakePath);
  return flakeInfo.nixosConfigurations.map((c) => c.name);
}

/**
 * Check if a specific NixOS configuration exists in the flake
 *
 * @param flakePath - Path to flake.nix or directory containing it
 * @param hostName - Name of the host to check
 * @returns true if the host exists, false otherwise
 */
export async function hasNixOSHost(
  flakePath: string,
  hostName: string
): Promise<boolean> {
  const hosts = await getNixOSHosts(flakePath);
  return hosts.includes(hostName);
}
