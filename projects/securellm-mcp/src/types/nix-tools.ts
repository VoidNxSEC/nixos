/**
 * Nix Development Tools Types
 * 
 * Types for Nix flake operations, build analysis, and package management.
 */

/**
 * Flake operation type
 */
export type FlakeOperation = 
  | 'build'
  | 'check'
  | 'update'
  | 'show'
  | 'eval'
  | 'develop'
  | 'run'
  | 'search';

/**
 * Flake build result
 */
export interface FlakeBuildResult {
  /** Operation performed */
  operation: FlakeOperation;
  /** Success status */
  success: boolean;
  /** Output path (for successful builds) */
  outputPath?: string;
  /** Build logs */
  logs: string[];
  /** Errors encountered */
  errors: string[];
  /** Warnings */
  warnings: string[];
  /** Duration in ms */
  duration: number;
  /** Exit code */
  exitCode: number;
}

/**
 * Package search result
 */
export interface NixPackage {
  /** Package name */
  name: string;
  /** Package version */
  version: string;
  /** Package description */
  description?: string;
  /** Package attribute path */
  attrPath: string;
  /** Available in these channels */
  channels?: string[];
}

/**
 * Dependency info
 */
export interface NixDependency {
  /** Dependency name */
  name: string;
  /** Dependency version */
  version?: string;
  /** Store path */
  storePath?: string;
  /** Is runtime dependency */
  runtime: boolean;
  /** Is build dependency */
  buildTime: boolean;
}

/**
 * Derivation info
 */
export interface DerivationInfo {
  /** Derivation name */
  name: string;
  /** Store path */
  path: string;
  /** System (x86_64-linux, etc.) */
  system: string;
  /** Builder command */
  builder?: string;
  /** Build inputs */
  buildInputs: string[];
  /** Runtime dependencies */
  runtimeDeps: NixDependency[];
  /** Environment variables */
  env: Record<string, string>;
}

/**
 * Flake metadata
 */
export interface FlakeMetadata {
  /** Flake description */
  description: string;
  /** Last modified timestamp */
  lastModified: number;
  /** Revision (git commit) */
  revision?: string;
  /** Flake inputs */
  inputs: Record<string, FlakeInput>;
  /** Available outputs */
  outputs: string[];
}

/**
 * Flake input info
 */
export interface FlakeInput {
  /** Input type (github, path, etc.) */
  type: string;
  /** Input URL */
  url: string;
  /** Resolved revision */
  revision?: string;
  /** Last modified */
  lastModified?: number;
}

/**
 * Build analysis result
 */
export interface BuildAnalysis {
  /** Total build time */
  totalTime: number;
  /** Number of derivations built */
  derivationsBuilt: number;
  /** Failed builds */
  failures: string[];
  /** Warnings encountered */
  warnings: string[];
  /** Cache hits */
  cacheHits: number;
  /** Cache misses */
  cacheMisses: number;
  /** Downloaded packages */
  downloads: Array<{ name: string; size: number }>;
}