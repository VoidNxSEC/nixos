// Error Classifier - Intelligent error pattern detection and solution suggestion
import type { ErrorPattern, ErrorType, ErrorSeverity, DiagnoseIssue } from "../types/package-debugger.js";

export class ErrorClassifier {
  private patterns: ErrorPattern[];

  constructor() {
    this.patterns = this.initializePatterns();
  }

  private initializePatterns(): ErrorPattern[] {
    return [
      {
        name: "hash_mismatch",
        regex: /hash mismatch.*specified:\s*(sha256-[A-Za-z0-9+\/=]+).*got:\s*(sha256-[A-Za-z0-9+\/=]+)/s,
        fix: "UPDATE_HASH",
        severity: "critical",
        extractor: (match) => ({
          field: "sha256/npmDepsHash",
          specified: match[1],
          correct_hash: match[2],
        }),
        suggestion: "Update the hash in the configuration file with the correct value",
      },
      {
        name: "directory_execution",
        regex: /([^:]+):\s+Is a directory$/m,
        fix: "CHECK_EXECUTABLE_PATH",
        severity: "critical",
        extractor: (match) => ({
          path: match[1],
        }),
        suggestion: "The executable path points to a directory instead of a file. Check tarball structure and update the executable path",
      },
      {
        name: "pkg_config_missing",
        regex: /pkg-config:\s+command not found/,
        fix: "ADD_DEPENDENCY",
        severity: "critical",
        extractor: () => ({
          dependency_type: "nativeBuildInputs",
          packages: ["pkg-config"],
        }),
        suggestion: "Add pkg-config to nativeBuildInputs",
      },
      {
        name: "library_not_found",
        regex: /(\w+(?:-\d+)?(?:\.so[.\d]*)?):\s+cannot open shared object file/,
        fix: "ADD_DEPENDENCY",
        severity: "critical",
        extractor: (match) => ({
          library: match[1],
          dependency_type: "buildInputs",
        }),
        suggestion: "Add the required library to buildInputs",
      },
      {
        name: "broken_symlinks",
        regex: /ERROR: noBrokenSymlinks.*symlink\s+(.+?)\s+points to.*missing target:\s+(.+)/,
        fix: "CLEAN_SYMLINK",
        severity: "warning",
        extractor: (match) => ({
          symlink_path: match[1],
          target_path: match[2],
        }),
        suggestion: "Remove the broken symlink in postInstall phase",
      },
      {
        name: "npm_gyp_error",
        regex: /npm error gyp ERR!/,
        fix: "ADD_BUILD_TOOLS",
        severity: "critical",
        extractor: () => ({
          dependency_type: "nativeBuildInputs",
          packages: ["python3", "pkg-config"],
        }),
        suggestion: "Add build tools (python3, pkg-config) to nativeBuildInputs for native module compilation",
      },
      {
        name: "python_not_found",
        regex: /python[23]?:\s+command not found/,
        fix: "ADD_DEPENDENCY",
        severity: "critical",
        extractor: () => ({
          dependency_type: "nativeBuildInputs",
          packages: ["python3"],
        }),
        suggestion: "Add python3 to nativeBuildInputs",
      },
      {
        name: "missing_libsecret",
        regex: /libsecret-1/,
        fix: "ADD_DEPENDENCY",
        severity: "critical",
        extractor: () => ({
          dependency_type: "buildInputs",
          packages: ["libsecret"],
        }),
        suggestion: "Add libsecret to buildInputs (required for password management)",
      },
    ];
  }

  /**
   * Classify an error and return structured information
   */
  classifyError(errorLog: string): DiagnoseIssue | null {
    for (const pattern of this.patterns) {
      const match = errorLog.match(pattern.regex);
      if (match) {
        const extracted = pattern.extractor ? pattern.extractor(match) : {};
        
        return {
          type: pattern.name as ErrorType,
          severity: pattern.severity,
          location: "build log",
          problem: this.generateProblemDescription(pattern.name, extracted),
          cause: this.generateCauseDescription(pattern.name, extracted),
          solution: this.generateSolution(pattern.name, extracted),
          fix_command: this.generateFixCommand(pattern.fix, extracted),
        };
      }
    }

    return null;
  }

  /**
   * Classify multiple errors from a log
   */
  classifyAllErrors(errorLog: string): DiagnoseIssue[] {
    const issues: DiagnoseIssue[] = [];
    
    for (const pattern of this.patterns) {
      const matches = [...errorLog.matchAll(new RegExp(pattern.regex.source, pattern.regex.flags + 'g'))];
      
      for (const match of matches) {
        const extracted = pattern.extractor ? pattern.extractor(match) : {};
        
        issues.push({
          type: pattern.name as ErrorType,
          severity: pattern.severity,
          location: "build log",
          problem: this.generateProblemDescription(pattern.name, extracted),
          cause: this.generateCauseDescription(pattern.name, extracted),
          solution: this.generateSolution(pattern.name, extracted),
          fix_command: this.generateFixCommand(pattern.fix, extracted),
        });
      }
    }

    return issues;
  }

  private generateProblemDescription(errorName: string, extracted: Record<string, any>): string {
    switch (errorName) {
      case "hash_mismatch":
        return `Hash mismatch detected: specified ${extracted.specified}, got ${extracted.correct_hash}`;
      case "directory_execution":
        return `Executable path '${extracted.path}' points to a directory instead of a file`;
      case "pkg_config_missing":
        return "pkg-config command not found during build";
      case "library_not_found":
        return `Shared library '${extracted.library}' cannot be found`;
      case "broken_symlinks":
        return `Broken symlink: ${extracted.symlink_path} points to missing target`;
      case "npm_gyp_error":
        return "npm gyp failed to build native modules";
      case "python_not_found":
        return "Python interpreter not found during build";
      case "missing_libsecret":
        return "libsecret library required but not found";
      default:
        return "Unknown error";
    }
  }

  private generateCauseDescription(errorName: string, extracted: Record<string, any>): string {
    switch (errorName) {
      case "hash_mismatch":
        return "The calculated hash differs from the specified hash in the configuration";
      case "directory_execution":
        return "The tarball extracts with a nested directory structure";
      case "pkg_config_missing":
        return "Native modules require pkg-config for compilation";
      case "library_not_found":
        return `System library ${extracted.library} is not in the build environment`;
      case "broken_symlinks":
        return "Package is a monorepo with symlinks to workspace packages not included in the release";
      case "npm_gyp_error":
        return "Native node modules require Python and pkg-config for compilation";
      case "python_not_found":
        return "Build process requires Python interpreter";
      case "missing_libsecret":
        return "Password management functionality requires libsecret";
      default:
        return "Unknown cause";
    }
  }

  private generateSolution(errorName: string, extracted: Record<string, any>): string {
    switch (errorName) {
      case "hash_mismatch":
        return `Update hash to: ${extracted.correct_hash}`;
      case "directory_execution":
        return "Update executable path to point to the actual file inside the directory";
      case "pkg_config_missing":
        return "Add pkg-config to nativeBuildInputs";
      case "library_not_found":
        return `Add the nixpkg containing ${extracted.library} to buildInputs`;
      case "broken_symlinks":
        return "Remove broken symlinks in postInstall phase";
      case "npm_gyp_error":
        return "Add python3 and pkg-config to nativeBuildInputs";
      case "python_not_found":
        return "Add python3 to nativeBuildInputs";
      case "missing_libsecret":
        return "Add libsecret to buildInputs";
      default:
        return "Manual investigation required";
    }
  }

  private generateFixCommand(fixType: string, extracted: Record<string, any>): string {
    switch (fixType) {
      case "UPDATE_HASH":
        return `apply_diff to update ${extracted.field} = "${extracted.correct_hash}"`;
      case "CHECK_EXECUTABLE_PATH":
        return "apply_diff to update executable path to correct file location";
      case "ADD_DEPENDENCY":
        return `apply_diff to add ${extracted.packages?.join(', ')} to ${extracted.dependency_type}`;
      case "CLEAN_SYMLINK":
        return `apply_diff to add 'rm -f ${extracted.symlink_path}' to postInstall`;
      case "ADD_BUILD_TOOLS":
        return `apply_diff to add build tools to nativeBuildInputs`;
      default:
        return "Manual fix required";
    }
  }

  /**
   * Get dependency mapping for a library
   */
  getLibraryMapping(library: string): string | null {
    const mappings: Record<string, string> = {
      "libsecret-1.so": "libsecret",
      "libgtk-3.so": "gtk3",
      "libGL.so": "libGL",
      "libX11.so": "xorg.libX11",
      "libXext.so": "xorg.libXext",
      "libXrender.so": "xorg.libXrender",
      "libcairo.so": "cairo",
      "libpango.so": "pango",
      "libglib-2.0.so": "glib",
      "libgobject-2.0.so": "glib",
      "libgio-2.0.so": "glib",
      "libz.so": "zlib",
      "libssl.so": "openssl",
      "libcrypto.so": "openssl",
      "libcurl.so": "curl",
      "libsqlite3.so": "sqlite",
      "libpq.so": "postgresql",
      "libmysqlclient.so": "mysql",
    };

    // Try exact match
    if (mappings[library]) {
      return mappings[library];
    }

    // Try partial match (e.g., "libsecret-1.so.0" matches "libsecret-1.so")
    for (const [key, value] of Object.entries(mappings)) {
      if (library.startsWith(key)) {
        return value;
      }
    }

    return null;
  }
}