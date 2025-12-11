/**
 * Extended MCP Tools Type Definitions
 * Types for all 28 new tools across 6 categories
 */

// ===== SYSTEM MANAGEMENT TYPES =====

export interface SystemHealthCheckArgs {
  detailed?: boolean;
  components?: Array<'cpu' | 'memory' | 'disk' | 'network' | 'services'>;
}

export interface SystemLogAnalyzerArgs {
  service?: string;
  since?: string;
  until?: string;
  level?: 'error' | 'warning' | 'info' | 'debug';
  lines?: number;
  pattern?: string;
}

export interface SystemServiceManagerArgs {
  action: 'start' | 'stop' | 'restart' | 'status' | 'enable' | 'disable';
  service: string;
}

export interface SystemBackupManagerArgs {
  action: 'create' | 'list' | 'restore' | 'verify';
  paths?: string[];
  backup_id?: string;
  destination?: string;
}

export interface SystemResourceMonitorArgs {
  duration_seconds?: number;
  interval_seconds?: number;
  resources?: Array<'cpu' | 'memory' | 'disk' | 'network'>;
}

export interface SystemPackageAuditArgs {
  check_updates?: boolean;
  check_vulnerabilities?: boolean;
  check_orphans?: boolean;
}

// ===== SSH ACCESS TYPES =====

export interface SSHConnectArgs {
  host: string;
  port?: number;
  username: string;
  auth_method: 'key' | 'password' | 'certificate';
  key_path?: string;
  password?: string;
  certificate_path?: string;
}

export interface SSHExecuteArgs {
  connection_id: string;
  command: string;
  timeout_seconds?: number;
  sudo?: boolean;
}

export interface SSHFileTransferArgs {
  connection_id: string;
  action: 'upload' | 'download';
  local_path: string;
  remote_path: string;
}

export interface SSHMaintenanceCheckArgs {
  connection_id: string;
  checks: Array<'disk' | 'services' | 'updates' | 'security' | 'logs'>;
}

// ===== BROWSER NAVIGATION TYPES =====

export interface BrowserLaunchAdvancedArgs {
  url: string;
  headless?: boolean;
  viewport?: { width: number; height: number };
  user_agent?: string;
  cookies?: Array<{ name: string; value: string; domain: string }>;
}

export interface BrowserExtractDataArgs {
  session_id: string;
  selectors: Array<{ name: string; selector: string; type: 'text' | 'html' | 'attribute' }>;
  wait_for?: string;
}

export interface BrowserInteractFormArgs {
  session_id: string;
  actions: Array<{
    type: 'fill' | 'click' | 'select' | 'check' | 'upload';
    selector: string;
    value?: string;
  }>;
  submit_selector?: string;
}

export interface BrowserMonitorChangesArgs {
  session_id: string;
  selector: string;
  interval_seconds: number;
  duration_seconds: number;
}

export interface BrowserSearchAggregateArgs {
  query: string;
  sources: Array<'google' | 'duckduckgo' | 'github' | 'stackoverflow'>;
  max_results?: number;
}

// ===== SENSITIVE DATA TYPES =====

export interface DataScanSensitiveArgs {
  paths: string[];
  patterns?: Array<'email' | 'phone' | 'ssn' | 'credit_card' | 'ip' | 'custom'>;
  custom_regex?: string[];
  recursive?: boolean;
}

export interface DataPseudonymizeArgs {
  input_file: string;
  output_file: string;
  fields: string[];
  method: 'hash' | 'encrypt' | 'tokenize' | 'mask';
  preserve_format?: boolean;
}

export interface DataEncryptSensitiveArgs {
  file_path: string;
  operation: 'encrypt' | 'decrypt';
  output_path?: string;
  key_id?: string;
}

export interface DataAuditAccessArgs {
  resource_type: 'file' | 'service' | 'secret';
  resource_path: string;
  time_range?: { start: string; end: string };
}

// ===== FILE ORGANIZATION TYPES =====

export interface FilesAnalyzeStructureArgs {
  base_path: string;
  max_depth?: number;
  min_size_mb?: number;
  file_types?: string[];
}

export interface FilesAutoOrganizeArgs {
  source_path: string;
  strategy: 'by_type' | 'by_date' | 'by_size' | 'by_project' | 'custom';
  dry_run?: boolean;
  custom_rules?: Array<{ pattern: string; destination: string }>;
}

export interface FilesCreateCatalogArgs {
  paths: string[];
  include_metadata?: boolean;
  include_checksums?: boolean;
  output_format?: 'json' | 'sqlite' | 'csv';
}

export interface FilesSearchCatalogArgs {
  query: string;
  filters?: {
    file_type?: string;
    min_size?: number;
    max_size?: number;
    date_range?: { start: string; end: string };
  };
}

export interface FilesTagManagerArgs {
  action: 'add' | 'remove' | 'search' | 'list';
  file_path?: string;
  tags?: string[];
}

// ===== DATA CLEANUP TYPES =====

export interface CleanupAnalyzeWasteArgs {
  paths: string[];
  criteria?: {
    age_days?: number;
    min_size_mb?: number;
    file_patterns?: string[];
    exclude_patterns?: string[];
  };
}

export interface CleanupExecuteSmartArgs {
  analysis_id: string;
  dry_run?: boolean;
  max_delete_size_gb?: number;
  preserve_recent_days?: number;
}

export interface CleanupDuplicateResolverArgs {
  paths: string[];
  strategy: 'keep_newest' | 'keep_largest' | 'keep_oldest' | 'interactive';
  hash_algorithm?: 'md5' | 'sha256';
  min_size_mb?: number;
}

export interface CleanupLogRotationArgs {
  log_paths: string[];
  max_size_mb?: number;
  max_age_days?: number;
  compress?: boolean;
  keep_files?: number;
}

// ===== RESULT TYPES =====

export interface ToolResult {
  success: boolean;
  data?: any;
  error?: string;
  warnings?: string[];
  timestamp: string;
  metadata?: any;
}

export interface SystemHealthResult extends ToolResult {
  data?: {
    cpu: { usage: number; load: number[]; cores: number };
    memory: { used: number; total: number; percentage: number };
    disk: Array<{ mount: string; used: number; total: number; percentage: number }>;
    network: { interfaces: Array<{ name: string; rx: number; tx: number }> };
    services: Array<{ name: string; status: string; uptime: number }>;
  };
}

export interface SSHConnectionResult extends ToolResult {
  data?: {
    connection_id: string;
    host: string;
    username: string;
    connected: boolean;
  };
}

export interface BrowserSessionResult extends ToolResult {
  data?: {
    session_id: string;
    url: string;
    screenshot?: string;
    console_logs?: string[];
  };
}

export interface SensitiveDataScanResult extends ToolResult {
  data?: {
    files_scanned: number;
    matches_found: number;
    matches: Array<{
      file: string;
      line: number;
      type: string;
      context: string;
    }>;
  };
}

export interface FileCatalogResult extends ToolResult {
  data?: {
    catalog_id: string;
    files_indexed: number;
    total_size_bytes: number;
    catalog_path: string;
  };
}

export interface CleanupAnalysisResult extends ToolResult {
  data?: {
    analysis_id: string;
    total_waste_mb: number;
    files_analyzed: number;
    recommendations: Array<{
      path: string;
      size_mb: number;
      reason: string;
      confidence: number;
    }>;
  };
}