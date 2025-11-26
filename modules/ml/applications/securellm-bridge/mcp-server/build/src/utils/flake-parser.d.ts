/**
 * Flake.nix Parser Utility
 *
 * Parses flake.nix to extract nixosConfigurations and other metadata.
 * Uses pattern matching instead of full Nix evaluation for simplicity and safety.
 */
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
 * Parse flake.nix file and extract configuration information
 *
 * @param flakePath - Path to flake.nix file or directory containing it
 * @returns FlakeInfo object with extracted information
 * @throws Error if flake.nix cannot be read or parsed
 */
export declare function parseFlake(flakePath: string): Promise<FlakeInfo>;
/**
 * Get all NixOS configuration names from a flake
 *
 * @param flakePath - Path to flake.nix or directory containing it
 * @returns Array of configuration names
 */
export declare function getNixOSHosts(flakePath: string): Promise<string[]>;
/**
 * Check if a specific NixOS configuration exists in the flake
 *
 * @param flakePath - Path to flake.nix or directory containing it
 * @param hostName - Name of the host to check
 * @returns true if the host exists, false otherwise
 */
export declare function hasNixOSHost(flakePath: string, hostName: string): Promise<boolean>;
//# sourceMappingURL=flake-parser.d.ts.map