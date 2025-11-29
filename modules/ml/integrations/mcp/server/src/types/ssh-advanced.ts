/**
 * SSH Advanced Types Specification
 * Advanced type definitions for SSH tools with tunneling, port forwarding,
 * jump hosts, session management, MFA, and connection pooling.
 */

import { ToolResult } from './extended-tools.js';

// ===== CORE SSH TYPES =====

/**
 * Base SSH connection configuration
 */
export interface SSHConfig {
  readonly host: string;
  readonly port?: number;
  readonly username: string;
  readonly auth_method: 'key' | 'password' | 'certificate';
  
  // Authentication credentials
  readonly key_path?: string;
  readonly password?: string;
  readonly certificate_path?: string;
  
  // Connection options
  readonly timeout_ms?: number;
  readonly keep_alive_interval?: number;
  readonly keep_alive_count?: number;
  
  // Security options
  readonly strict_host_key_checking?: boolean;
  readonly known_hosts_path?: string;
  
  // Advanced options
  readonly compression?: boolean;
  readonly algorithms?: {
    readonly kex?: readonly string[];
    readonly cipher?: readonly string[];
    readonly hmac?: readonly string[];
  };
}

/**
 * SSH connection state
 */
export interface SSHConnection {
  readonly id: string;
  readonly config: SSHConfig;
  readonly client: any; // ssh2.Client
  connected: boolean;
  readonly created_at: Date;
  last_used: Date;
  
  // Metrics
  bytes_sent: number;
  bytes_received: number;
  commands_executed: number;
  
  // State
  health_status: 'healthy' | 'degraded' | 'failed';
  error_count: number;
  last_error?: string;
}

/**
 * Connection health status
 */
export interface ConnectionHealthStatus {
  readonly connection_id: string;
  readonly status: 'healthy' | 'degraded' | 'failed';
  readonly latency_ms: number;
  readonly uptime_seconds: number;
  readonly last_check: Date;
  readonly issues: readonly string[];
  readonly metrics: {
    readonly success_rate: number;
    readonly avg_latency_ms: number;
    readonly error_count: number;
  };
}

// ===== TUNNEL TYPES =====

/**
 * SSH tunnel types
 */
export type TunnelType = 'local' | 'remote' | 'dynamic';

/**
 * Base tunnel configuration
 */
export interface BaseTunnelConfig {
  readonly connection_id: string;
  readonly type: TunnelType;
  
  // Options
  readonly bind_address?: string; // default: 'localhost'
  readonly keep_alive?: boolean; // auto-reconnect on failure
  readonly timeout_seconds?: number;
  
  // Monitoring
  readonly monitor_interval?: number; // seconds between health checks
  readonly auto_restart?: boolean;
}

/**
 * Local port forwarding tunnel: -L [bind_address:]local_port:remote_host:remote_port
 * Forwards local port to remote destination through SSH server
 */
export interface LocalTunnelConfig extends BaseTunnelConfig {
  readonly type: 'local';
  readonly local_port: number;
  readonly remote_host: string;
  readonly remote_port: number;
}

/**
 * Remote port forwarding tunnel: -R [bind_address:]remote_port:local_host:local_port
 * Forwards remote port back to local destination
 */
export interface RemoteTunnelConfig extends BaseTunnelConfig {
  readonly type: 'remote';
  readonly remote_port: number;
  readonly local_host: string;
  readonly local_port: number;
}

/**
 * Dynamic SOCKS proxy: -D [bind_address:]socks_port
 * Creates a SOCKS5 proxy on local port
 */
export interface DynamicTunnelConfig extends BaseTunnelConfig {
  readonly type: 'dynamic';
  readonly socks_port: number;
  readonly socks_version?: 4 | 5; // default: 5
}

/**
 * Union type for all tunnel configurations (discriminated union)
 */
export type TunnelConfig = 
  | LocalTunnelConfig 
  | RemoteTunnelConfig 
  | DynamicTunnelConfig;

/**
 * Tunnel instance state
 */
export interface Tunnel {
  readonly id: string;
  readonly config: TunnelConfig;
  readonly connection_id: string;
  
  // State
  status: 'active' | 'establishing' | 'failed' | 'closed';
  readonly created_at: Date;
  closed_at?: Date;
  
  // Endpoints
  readonly local_endpoint: string; // e.g., "localhost:8080"
  readonly remote_endpoint: string; // e.g., "db.internal:5432"
  
  // Metrics
  bytes_transferred: number;
  connections_count: number;
  errors_count: number;
  last_error?: string;
  
  // Recovery
  reconnect_attempts: number;
  readonly max_reconnect_attempts?: number;
}

/**
 * Tunnel metrics for monitoring
 */
export interface TunnelMetrics {
  readonly tunnel_id: string;
  readonly uptime_seconds: number;
  readonly bytes_sent: number;
  readonly bytes_received: number;
  readonly active_connections: number;
  readonly total_connections: number;
  readonly errors: number;
  readonly health: 'healthy' | 'degraded' | 'failed';
}

/**
 * Tunnel status information
 */
export interface TunnelStatus {
  readonly tunnel_id: string;
  readonly type: TunnelType;
  readonly status: 'active' | 'establishing' | 'failed' | 'closed';
  readonly local_endpoint: string;
  readonly remote_endpoint: string;
  readonly uptime_seconds: number;
  readonly last_activity: Date;
  readonly metrics: TunnelMetrics;
}

// ===== PORT FORWARDING TYPES =====

/**
 * Single port forward rule
 */
export interface PortForwardRule {
  readonly local_port: number;
  readonly remote_host: string;
  readonly remote_port: number;
  readonly protocol?: 'tcp' | 'udp'; // default: 'tcp'
  
  // Options
  readonly bind_address?: string;
  readonly description?: string;
}

/**
 * Port forwarding configuration
 */
export interface PortForwardConfig {
  readonly connection_id: string;
  readonly forwards: readonly PortForwardRule[];
  
  // Options
  readonly auto_reconnect?: boolean;
  readonly validate_ports?: boolean; // check port availability before setup
  readonly conflict_resolution?: 'fail' | 'auto_assign' | 'force'; // default: 'fail'
}

/**
 * Active port forward instance
 */
export interface PortForward {
  readonly id: string;
  readonly rule: PortForwardRule;
  readonly connection_id: string;
  
  // State
  status: 'active' | 'failed' | 'closed';
  readonly created_at: Date;
  
  // Actual endpoints (may differ if auto-assigned)
  readonly actual_local_port: number;
  readonly actual_remote_endpoint: string;
  
  // Metrics
  bytes_transferred: number;
  active_connections: number;
  errors_count: number;
}

/**
 * Port validation result
 */
export interface PortValidationResult {
  readonly port: number;
  readonly available: boolean;
  readonly in_use_by?: string; // process name if in use
  readonly can_force?: boolean; // can be forcefully bound
  readonly alternative_ports?: readonly number[]; // suggested alternatives
}

/**
 * Port forward setup result
 */
export interface PortForwardResult extends ToolResult {
  data?: {
    readonly forward_id: string;
    readonly forwards: ReadonlyArray<{
      readonly rule: PortForwardRule;
      readonly actual_port: number;
      readonly status: 'active' | 'failed';
      readonly error?: string;
    }>;
    readonly connection_id: string;
  };
}

// ===== JUMP HOST TYPES =====

/**
 * Jump strategy for multi-hop connections
 */
export type JumpStrategy = 
  | 'sequential'  // Connect through each jump in order
  | 'optimal'     // Find fastest path automatically
  | 'failover';   // Try alternative paths on failure

/**
 * Jump host configuration
 */
export interface JumpHostConfig extends SSHConfig {
  // Additional jump-specific options
  readonly forward_agent?: boolean; // forward SSH agent
  readonly max_latency_ms?: number; // skip if latency too high
  readonly priority?: number; // for optimal strategy
}

/**
 * Jump chain configuration
 */
export interface JumpChainConfig {
  readonly target: SSHConfig;
  readonly jumps: readonly JumpHostConfig[];
  readonly strategy?: JumpStrategy; // default: 'sequential'
  
  // Options
  readonly max_total_latency_ms?: number; // fail if total latency exceeds
  readonly timeout_per_hop_ms?: number;
  readonly parallel_probe?: boolean; // probe multiple paths simultaneously
  
  // Caching
  readonly cache_successful_path?: boolean;
  readonly cache_duration_minutes?: number;
}

/**
 * Jump chain instance
 */
export interface JumpChain {
  readonly id: string;
  readonly config: JumpChainConfig;
  
  // State
  status: 'connecting' | 'connected' | 'failed' | 'closed';
  readonly connection_id: string; // final connection to target
  
  // Path information
  readonly actual_path: ReadonlyArray<{
    readonly host: string;
    readonly latency_ms: number;
    readonly connected_at: Date;
  }>;
  readonly total_latency_ms: number;
  
  // Metrics
  readonly hop_count: number;
  readonly created_at: Date;
  reconnect_attempts: number;
}

/**
 * Jump chain status
 */
export interface JumpChainStatus {
  readonly chain_id: string;
  readonly status: string;
  readonly target: string;
  readonly path: readonly string[]; // ["bastion1.com", "bastion2.com", "target.internal"]
  readonly total_latency_ms: number;
  readonly uptime_seconds: number;
  readonly health: 'healthy' | 'degraded' | 'failed';
}

/**
 * Jump chain result
 */
export interface JumpChainResult extends ToolResult {
  data?: {
    readonly chain_id: string;
    readonly connection_id: string;
    readonly target: string;
    readonly jumps: readonly string[];
    readonly path_taken: readonly string[];
    readonly total_latency_ms: number;
    readonly hop_count: number;
  };
}

// ===== SESSION MANAGEMENT TYPES =====

/**
 * Session persistence configuration
 */
export interface SessionConfig {
  readonly connection_id: string;
  readonly persist: boolean; // save to disk
  readonly auto_recover: boolean; // auto-reconnect on failure
  
  // Recovery options
  readonly max_recovery_attempts?: number; // default: 3
  readonly recovery_backoff_ms?: number; // delay between attempts
  readonly recovery_strategy?: 'immediate' | 'exponential' | 'linear';
  
  // State management
  readonly save_tunnel_state?: boolean;
  readonly save_port_forwards?: boolean;
  readonly save_jump_chain?: boolean;
}

/**
 * Serializable session data
 */
export interface SessionData {
  readonly session_id: string;
  readonly connection_config: SSHConfig;
  
  // State
  readonly created_at: string; // ISO timestamp
  readonly last_active: string;
  readonly connection_metadata: {
    readonly bytes_sent: number;
    readonly bytes_received: number;
    readonly commands_executed: number;
  };
  
  // Active resources
  readonly tunnels?: readonly TunnelConfig[];
  readonly port_forwards?: readonly PortForwardRule[];
  readonly jump_chain?: JumpChainConfig;
  
  // Recovery
  recovery_count: number;
  last_recovery_attempt?: string;
  recovery_state: 'stable' | 'recovering' | 'failed';
}

/**
 * Session information
 */
export interface SessionInfo {
  readonly session_id: string;
  readonly connection_id?: string; // undefined if not currently connected
  readonly status: 'active' | 'disconnected' | 'persisted';
  readonly created_at: Date;
  readonly last_active: Date;
  
  // Persistence
  readonly persisted: boolean;
  readonly auto_recover: boolean;
  readonly recovery_count: number;
  
  // Resources
  readonly has_tunnels: boolean;
  readonly has_port_forwards: boolean;
  readonly has_jump_chain: boolean;
}

/**
 * Session recovery result
 */
export interface SessionRecoveryResult extends ToolResult {
  data?: {
    readonly session_id: string;
    readonly connection_id: string;
    readonly recovery_time_ms: number;
    readonly recovered_resources: {
      readonly tunnels: number;
      readonly port_forwards: number;
      readonly jump_chain: boolean;
    };
    readonly warnings: readonly string[];
  };
}

/**
 * Session state snapshot
 */
export interface SessionState {
  readonly session_id: string;
  readonly timestamp: Date;
  readonly connection_state: 'connected' | 'disconnected';
  readonly active_tunnels: readonly string[];
  readonly active_port_forwards: readonly string[];
  readonly jump_chain_id?: string;
  readonly metrics: {
    readonly uptime_seconds: number;
    readonly total_bytes_transferred: number;
    readonly total_commands: number;
  };
}

// ===== MULTI-FACTOR AUTHENTICATION TYPES =====

/**
 * MFA methods supported
 */
export type MFAMethod = 
  | 'totp'      // Time-based One-Time Password (Google Authenticator, etc.)
  | 'hardware'  // Hardware token (YubiKey, etc.)
  | 'sms'       // SMS code
  | 'email'     // Email code
  | 'push';     // Push notification

/**
 * MFA configuration
 */
export interface MFAConfig {
  enabled: boolean;
  readonly methods: readonly MFAMethod[];
  readonly required_for: ReadonlyArray<'connection' | 'sudo_commands' | 'sensitive_operations'>;
  
  // TOTP settings
  readonly totp?: {
    readonly secret_key?: string;
    readonly issuer?: string;
    readonly algorithm?: 'SHA1' | 'SHA256' | 'SHA512';
    readonly digits?: 6 | 8;
    readonly period?: number; // seconds, default 30
  };
  
  // Hardware token settings
  readonly hardware?: {
    readonly device_path?: string;
    readonly challenge_response?: boolean;
  };
  
  // Backup codes
  readonly backup_codes?: readonly string[];
  backup_codes_remaining?: number;
}

/**
 * MFA authentication request
 */
export interface MFAAuthArgs {
  readonly connection_id: string;
  readonly method: MFAMethod;
  readonly code: string;
  
  // Optional context
  readonly operation?: string; // what operation requires MFA
  readonly timestamp?: number;
}

/**
 * MFA authentication result
 */
export interface MFAAuthResult extends ToolResult {
  data?: {
    readonly authenticated: boolean;
    readonly method: MFAMethod;
    readonly valid_until?: Date;
    readonly attempts_remaining?: number;
  };
}

/**
 * MFA setup data
 */
export interface MFASetup {
  readonly method: MFAMethod;
  readonly secret?: string; // for TOTP
  readonly qr_code?: string; // base64 QR code image
  readonly backup_codes?: readonly string[];
  readonly verification_required: boolean;
}

// ===== CONNECTION POOL TYPES =====

/**
 * Connection pool configuration
 */
export interface ConnectionPoolConfig {
  readonly max_connections: number; // max concurrent connections
  readonly max_idle_time_ms: number; // time before idle connection is closed
  readonly max_connection_age_ms?: number; // max age before forced refresh
  
  // Health checks
  readonly health_check_interval_ms?: number;
  readonly health_check_timeout_ms?: number;
  
  // Resource limits
  readonly max_memory_mb?: number;
  readonly max_bandwidth_mbps?: number;
}

/**
 * Connection pool statistics
 */
export interface PoolStatistics {
  readonly total_connections: number;
  readonly active_connections: number;
  readonly idle_connections: number;
  readonly failed_connections: number;
  
  // Performance
  readonly avg_connection_time_ms: number;
  readonly avg_latency_ms: number;
  
  // Resource usage
  readonly total_bytes_transferred: number;
  readonly memory_usage_mb: number;
  
  // Health
  readonly health_check_failures: number;
  readonly last_health_check: Date;
}

/**
 * Pool status information
 */
export interface PoolStatus {
  readonly statistics: PoolStatistics;
  readonly connections: ReadonlyArray<{
    readonly id: string;
    readonly host: string;
    readonly status: 'active' | 'idle' | 'failed';
    readonly age_seconds: number;
    readonly last_used: Date;
  }>;
  readonly health: 'healthy' | 'degraded' | 'critical';
  readonly warnings: readonly string[];
}

// ===== MONITORING & METRICS TYPES =====

/**
 * SSH subsystem metrics
 */
export interface SSHMetrics {
  // Connection metrics
  readonly connections: {
    readonly total: number;
    readonly active: number;
    readonly failed: number;
    readonly success_rate: number;
  };
  
  // Tunnel metrics
  readonly tunnels: {
    readonly total: number;
    readonly active: number;
    readonly bytes_transferred: number;
    readonly avg_throughput_mbps: number;
  };
  
  // Performance metrics
  readonly performance: {
    readonly avg_connection_time_ms: number;
    readonly avg_latency_ms: number;
    readonly p95_latency_ms: number;
    readonly p99_latency_ms: number;
  };
  
  // Error metrics
  readonly errors: {
    readonly authentication_failures: number;
    readonly connection_timeouts: number;
    readonly tunnel_failures: number;
    readonly command_rejections: number;
  };
  
  // Resource metrics
  readonly resources: {
    readonly memory_usage_mb: number;
    readonly cpu_usage_percent: number;
    readonly bandwidth_usage_mbps: number;
  };
}

/**
 * Alert configuration
 */
export interface SSHAlert {
  readonly type: 'connection_failure' | 'high_latency' | 'resource_limit' | 'security';
  readonly severity: 'info' | 'warning' | 'critical';
  readonly message: string;
  readonly timestamp: Date;
  readonly metadata?: Readonly<Record<string, any>>;
}

// ===== TOOL ARGUMENT TYPES =====

/**
 * SSH tunnel tool arguments
 */
export interface SSHTunnelArgs {
  readonly type: TunnelType;
  readonly connection_id: string;
  
  // Local tunnel specific
  readonly local_port?: number;
  readonly remote_host?: string;
  readonly remote_port?: number;
  
  // Remote tunnel specific
  readonly local_host?: string;
  
  // Dynamic tunnel specific
  readonly socks_port?: number;
  readonly socks_version?: 4 | 5;
  
  // Common options
  readonly bind_address?: string;
  readonly keep_alive?: boolean;
  readonly timeout_seconds?: number;
  readonly monitor_interval?: number;
  readonly auto_restart?: boolean;
}

/**
 * SSH port forward tool arguments
 */
export interface SSHPortForwardArgs {
  readonly connection_id: string;
  readonly forwards: readonly PortForwardRule[];
  readonly auto_reconnect?: boolean;
  readonly validate_ports?: boolean;
  readonly conflict_resolution?: 'fail' | 'auto_assign' | 'force';
}

/**
 * SSH jump host tool arguments
 */
export interface SSHJumpHostArgs {
  readonly target: SSHConfig;
  readonly jumps: readonly JumpHostConfig[];
  readonly strategy?: JumpStrategy;
  readonly max_total_latency_ms?: number;
  readonly timeout_per_hop_ms?: number;
  readonly parallel_probe?: boolean;
  readonly cache_successful_path?: boolean;
}

/**
 * SSH session manager tool arguments
 */
export interface SSHSessionArgs {
  readonly action: 'save' | 'restore' | 'list' | 'cleanup' | 'status';
  readonly session_id?: string;
  readonly connection_id?: string;
  readonly persist?: boolean;
  readonly auto_recover?: boolean;
  readonly max_recovery_attempts?: number;
}

/**
 * SSH connection pool tool arguments
 */
export interface SSHConnectionPoolArgs {
  readonly action: 'status' | 'prune' | 'stats' | 'health';
  readonly max_idle_time_ms?: number;
  readonly connection_id?: string;
}

/**
 * SSH MFA tool arguments (extends MFAAuthArgs)
 */
export interface SSHMFAArgs extends MFAAuthArgs {
  // Inherits all fields from MFAAuthArgs
}

// ===== TYPE GUARDS & VALIDATORS =====

/**
 * Type guard for local tunnel configuration
 */
export function isLocalTunnelConfig(config: TunnelConfig): config is LocalTunnelConfig {
  return config.type === 'local';
}

/**
 * Type guard for remote tunnel configuration
 */
export function isRemoteTunnelConfig(config: TunnelConfig): config is RemoteTunnelConfig {
  return config.type === 'remote';
}

/**
 * Type guard for dynamic tunnel configuration
 */
export function isDynamicTunnelConfig(config: TunnelConfig): config is DynamicTunnelConfig {
  return config.type === 'dynamic';
}

/**
 * Validation result interface
 */
export interface ValidationResult {
  readonly valid: boolean;
  readonly errors: readonly string[];
  readonly warnings: readonly string[];
}

/**
 * Validation function type for SSH configuration
 */
export type ValidateSSHConfig = (config: SSHConfig) => ValidationResult;

/**
 * Validation function type for tunnel configuration
 */
export type ValidateTunnelConfig = (config: TunnelConfig) => ValidationResult;

/**
 * Validation function type for port forward configuration
 */
export type ValidatePortForwardConfig = (config: PortForwardConfig) => ValidationResult;

/**
 * Validation function type for jump chain configuration
 */
export type ValidateJumpChainConfig = (config: JumpChainConfig) => ValidationResult;