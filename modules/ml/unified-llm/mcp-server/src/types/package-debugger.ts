// Types for Package Debugger & Builder System

export type PackageType = "tar" | "deb" | "js" | "py" | "auto";
export type BuildMethod = "auto" | "native" | "fhs";
export type BuildStatus = "success" | "failed" | "not_tested";
export type ErrorSeverity = "critical" | "warning" | "info";
export type ErrorType =
  | "hash_mismatch"
  | "hash_error"
  | "directory_execution"
  | "config_error"
  | "dependency_missing"
  | "missing_dependency"
  | "broken_symlink"
  | "broken_symlinks"
  | "npm_gyp_error"
  | "library_not_found"
  | "pkg_config_missing"
  | "python_not_found"
  | "missing_libsecret"
  | "unknown";

export interface PackageSource {
  type: "github_release" | "npm" | "url" | "pypi" | "local";
  url?: string;
  github?: {
    repo: string;
    tag?: string;
    asset_pattern?: string;
  };
  npm?: {
    package: string;
    version?: string;
  };
  pypi?: {
    package: string;
    version?: string;
  };
}

export interface DiagnoseInput {
  package_name: string;
  package_type: PackageType;
  error_log?: string;
}

export interface DiagnoseIssue {
  type: ErrorType;
  severity: ErrorSeverity;
  location: string;
  problem: string;
  cause: string;
  solution: string;
  fix_command?: string;
}

export interface DiagnoseResult {
  success: boolean;
  package_name: string;
  package_type: PackageType;
  build_status: BuildStatus;
  issues?: DiagnoseIssue[];
  suggestions: string[];
  execution_time_ms: number;
}

export interface DownloadInput {
  package_name: string;
  package_type: PackageType;
  source: PackageSource;
  storage_dir: string;
}

export interface DownloadResult {
  status: "success" | "error";
  downloaded_file?: string;
  storage_path?: string;
  sha256?: string;
  size_bytes?: number;
  config_template?: {
    package_file: string;
    content: string;
  };
  error?: string;
}

export interface ConfigureInput {
  package_name: string;
  package_type: PackageType;
  storage_file: string;
  sha256: string;
  options?: {
    method?: BuildMethod;
    sandbox?: boolean;
    audit?: boolean;
    executable?: string;
    npm_flags?: string[];
  };
}

export interface ConfigureResult {
  status: "success" | "error";
  config_file?: string;
  config_content?: string;
  detected_executables?: string[];
  detected_dependencies?: string[];
  build_method?: BuildMethod;
  error?: string;
}

export interface ErrorPattern {
  name: string;
  regex: RegExp;
  fix: string;
  severity: ErrorSeverity;
  extractor?: (match: RegExpMatchArray) => Record<string, any>;
  suggestion?: string;
}

export interface DependencyInfo {
  type: "nativeBuildInputs" | "buildInputs";
  packages: string[];
}

export interface NixPkgMapping {
  library: string;
  nixpkg: string;
  description?: string;
}