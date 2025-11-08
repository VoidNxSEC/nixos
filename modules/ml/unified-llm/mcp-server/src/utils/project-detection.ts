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

import * as fs from "fs/promises";
import * as path from "path";

export interface ProjectDetectionResult {
  projectRoot: string;
  method: "env_var" | "flake_search" | "fallback";
  flakeFound: boolean;
}

/**
 * Search upward from a directory to find flake.nix
 */
async function findFlakeNix(startDir: string): Promise<string | null> {
  let currentDir = path.resolve(startDir);
  const rootDir = path.parse(currentDir).root;

  while (currentDir !== rootDir) {
    try {
      const flakePath = path.join(currentDir, "flake.nix");
      await fs.access(flakePath, fs.constants.R_OK);
      return currentDir;
    } catch {
      // File doesn't exist or not readable, go up one level
      const parentDir = path.dirname(currentDir);
      if (parentDir === currentDir) {
        // Reached root
        break;
      }
      currentDir = parentDir;
    }
  }

  return null;
}

/**
 * Detect the project root directory
 *
 * @returns ProjectDetectionResult with the detected root and detection method
 * @throws Error if no valid project root can be determined
 */
export async function detectProjectRoot(): Promise<ProjectDetectionResult> {
  // Priority 1: Explicit PROJECT_ROOT environment variable
  const envProjectRoot = process.env.PROJECT_ROOT;
  if (envProjectRoot) {
    try {
      await fs.access(envProjectRoot, fs.constants.R_OK);
      const flakePath = path.join(envProjectRoot, "flake.nix");
      const flakeFound = await fs
        .access(flakePath, fs.constants.R_OK)
        .then(() => true)
        .catch(() => false);

      return {
        projectRoot: path.resolve(envProjectRoot),
        method: "env_var",
        flakeFound,
      };
    } catch {
      console.warn(
        `PROJECT_ROOT env var set to "${envProjectRoot}" but directory is not accessible. Falling back to auto-detection.`
      );
    }
  }

  // Priority 2: Search for flake.nix upward
  const cwd = process.cwd();
  const flakeRoot = await findFlakeNix(cwd);

  if (flakeRoot) {
    return {
      projectRoot: flakeRoot,
      method: "flake_search",
      flakeFound: true,
    };
  }

  // Priority 3: Fallback to current working directory
  console.warn(
    `No flake.nix found in directory tree. Using cwd as project root: ${cwd}`
  );
  console.warn(
    "Consider setting PROJECT_ROOT environment variable for explicit configuration."
  );

  return {
    projectRoot: cwd,
    method: "fallback",
    flakeFound: false,
  };
}

/**
 * Verify that a directory is a valid Nix project
 */
export async function isValidNixProject(dir: string): Promise<boolean> {
  try {
    const flakePath = path.join(dir, "flake.nix");
    await fs.access(flakePath, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}
