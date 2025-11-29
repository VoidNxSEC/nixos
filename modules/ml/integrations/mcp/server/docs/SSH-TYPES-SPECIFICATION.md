# SSH Advanced Types Specification

## 📋 Overview

This document provides detailed TypeScript type definitions for SSH advanced tools. These types will be added to `src/types/extended-tools.ts` or a new `src/types/ssh-advanced.ts` file during implementation.

---

## 🔧 Core SSH Types

### SSH Configuration Types

```typescript
/**
 * Base SSH connection configuration
 */
export interface SSHConfig {
  host: string;
  port?: number;
  username: string;
  auth_method: 'key' | 'password' | 'certificate';
  
  // Authentication credentials
  key_path?: string;
  password?: string;
  certificate_path?: string;
  
  // Connection options
  timeout_ms?: number;
  keep_alive_interval?: number;
  keep_alive_count?: number;
  
  // Security options
  strict_host_key_checking?: boolean;
  known_hosts_path?: string;
  
  // Advanced options
  compression?: boolean;
  algorithms?: {
    kex?: string[];
    cipher?: string[];
    hmac?: string[];
  };
}

/**
 * SSH connection state
 */
export interface SSHConnection {
  id: string;
  config: SSHConfig;
  client: any; // ssh2.Client
  connected: boolean;
  created_at: Date;
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
  connection_id: string;
  status: 'healthy' | 'degraded' | 'failed';
  latency_ms: number;
  uptime_seconds: number;
  last_check: Date;
  issues: string[];
  metrics: {
    success_rate: number;
    avg_latency_ms: number;
    error_count: number;
  };
}
```

---

## 🔀 Tunnel Types

### Tunnel Configuration

```typescript
/**
 * SSH tunnel types
 */
export type TunnelType = 'local' | 'remote' | 'dynamic';

/**
 * Base tunnel configuration
 */
export interface BaseTunnelConfig {
  connection_id: string;
  type: TunnelType;
  
  // Options
  bind_address?: string; // default: 'localhost'
  keep_alive?: boolean; // auto-reconnect on failure
  timeout_seconds?: number;
  
  // Monitoring
  monitor_interval?: number; // seconds between health checks
  auto_restart?: boolean;
}

/**
 * Local port forwarding tunnel: -L [bind_address:]local_port:remote_host:remote_port
 * Forwards local port to remote destination through SSH server
 */
export interface LocalTunnelConfig extends BaseTunnelConfig {
  type: 'local';
  local_port: number;
  remote_host: string;
  remote_port: number;
}

/**
 * Remote port forwarding tunnel: -R [bind_address:]remote_port:local_host:local_port
 * Forwards remote port back to local destination
 */
export interface RemoteTunnelConfig extends BaseTunnelConfig {
  type: 'remote';
  remote_port: number;
  local_host: string;
  local_port: number;
}

/**
 * Dynamic SOCKS proxy: -D [bind_address:]socks_port
 * Creates a SOCKS5 proxy on local port
 */
export interface DynamicTunnelConfig extends BaseTunnelConfig {
  type: 'dynamic';
  socks_port: number;
  socks_version?: 4 | 5; // default: 5
}

/**
 * Union type for all tunnel configurations
 */
export type TunnelConfig = 
  | LocalTunnelConfig 
  | RemoteTunnelConfig 
  | DynamicTunnelConfig;

/**
 * Tunnel instance state
 */
export interface Tunnel {
  id: string;
  config: TunnelConfig;
  connection_id: string;
  
  // State
  status: 'active' | 'establishing' | 'failed' | 'closed';
  created_at: Date;
  closed_at?: Date;
  
  // Endpoints
  local_endpoint: string; // e.g., "localhost:8080"
  remote_endpoint: string; // e.g., "db.internal:5432"
  
  // Metrics
  bytes_transferred: number;
  connections_count: number;
  errors_count: number;
  last_error?: string;
  
  // Recovery
  reconnect_attempts: number;
  max_reconnect_attempts?: number;
}

/**
 * Tunnel metrics for monitoring
 */
export interface TunnelMetrics {
  tunnel_id: string;
  uptime_seconds: number;
  bytes_sent: number;
  bytes_received: number;
  active_connections: number;
  total_connections: number;
  errors: number;
  health: 'healthy' | 'degraded' | 'failed';
}

/**
 * Tunnel status information
 */
export interface TunnelStatus {
  tunnel_id: string;
  type: TunnelType;
  status: 'active' | 'establishing' | 'failed' | 'closed';
  local_endpoint: string;
  remote_endpoint: string;
  uptime_seconds: number;
  last_activity: Date;
  metrics: TunnelMetrics;
}
```

---

## 🔌 Port Forwarding Types

### Port Forward Configuration

```typescript
/**
 * Single port forward rule
 */
export interface PortForwardRule {
  local_port: number;
  remote_host: string;
  remote_port: number;
  protocol?: 'tcp' | 'udp'; // default: 'tcp'
  
  // Options
  bind_address?: string;
  description?: string;
}

/**
 * Port forwarding configuration
 */
export interface PortForwardConfig {
  connection_id: string;
  forwards: PortForwardRule[];
  
  // Options
  auto_reconnect?: boolean;
  validate_ports?: boolean; // check port availability before setup
  conflict_resolution?: 'fail' | 'auto_assign' | 'force'; // default: 'fail'
}

/**
 * Active port forward instance
 */
export interface PortForward {
  id: string;
  rule: PortForwardRule;
  connection_id: string;
  
  // State
  status: 'active' | 'failed' | 'closed';
  created_at: Date;
  
  // Actual endpoints (may differ if auto-assigned)
  actual_local_port: number;
  actual_remote_endpoint: string;
  
  // Metrics
  bytes_transferred: number;
  active_connections: number;
  errors_count: number;
}

/**
 * Port validation result
 */
export interface PortValidationResult {
  port: number;
  available: boolean;
  in_use_by?: string; // process name if in use
  can_force?: boolean; // can be forcefully bound
  alternative_ports?: number[]; // suggested alternatives
}

/**
 * Port forward setup result
 */
export interface PortForwardResult extends ToolResult {
  data?: {
    forward_id: string;
    forwards: Array<{
      rule: PortForwardRule;
      actual_port: number;
      status: 'active' | 'failed';
      error?: string;
    }>;
    connection_id: string;
  };
}
```

---

## 🔗 Jump Host Types

### Jump Chain Configuration

```typescript
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
  forward_agent?: boolean; // forward SSH agent
  max_latency_ms?: number; // skip if latency too high
  priority?: number; // for optimal strategy
}

/**
 * Jump chain configuration
 */
export interface JumpChainConfig {
  target: SSHConfig;
  jumps: JumpHostConfig[];
  strategy?: JumpStrategy; // default: 'sequential'
  
  // Options
  max_total_latency_ms?: number; // fail if total latency exceeds
  timeout_per_hop_ms?: number;
  parallel_probe?: boolean; // probe multiple paths simultaneously
  
  // Caching
  cache_successful_path?: boolean;
  cache_duration_minutes?: number;
}

/**
 * Jump chain instance
 */
export interface JumpChain {
  id: string;
  config: JumpChainConfig;
  
  // State
  status: 'connecting' | 'connected' | 'failed' | 'closed';
  connection_id: string; // final connection to target
  
  // Path information
  actual_path: Array<{
    host: string;
    latency_ms: number;
    connected_at: Date;
  }>;
  total_latency_ms: number;
  
  // Metrics
  hop_count: number;
  created_at: Date;
  reconnect_attempts: number;
}

/**
 * Jump chain status
 */
export interface JumpChainStatus {
  chain_id: string;
  status: string;
  target: string;
  path: string[]; // ["bastion1.com", "bastion2.com", "target.internal"]
  total_latency_ms: number;
  uptime_seconds: number;
  health: 'healthy' | 'degraded' | 'failed';
}

/**
 * Jump chain result
 */
export interface JumpChainResult extends ToolResult {
  data?: {
    chain_id: string;
    connection_id: string;
    target: string;
    jumps: string[];
    path_taken: string[];
    total_latency_ms: number;
    hop_count: number;
  };
}
```

---

## 💾 Session Management Types

### Session Persistence

```typescript
/**
 * Session persistence configuration
 */
export interface SessionConfig {
  connection_id: string;
  persist: boolean; // save to disk
  auto_recover: boolean; // auto-reconnect on failure
  
  // Recovery options
  max_recovery_attempts?: number; // default: 3
  recovery_backoff_ms?: number; // delay between attempts
  recovery_strategy?: 'immediate' | 'exponential' | 'linear';
  
  // State management
  save_tunnel_state?: boolean;
  save_port_forwards?: boolean;
  save_jump_chain?: boolean;
}

/**
 * Serializable session data
 */
export interface SessionData {
  session_id: string;
  connection_config: SSHConfig;
  
  // State
  created_at: string; // ISO timestamp
  last_active: string;
  connection_metadata: {
    bytes_sent: number;
    bytes_received: number;
    commands_executed: number;
  };
  
  // Active resources
  tunnels?: TunnelConfig[];
  port_forwards?: PortForwardRule[];
  jump_chain?: JumpChainConfig;
  
  // Recovery
  recovery_count: number;
  last_recovery_attempt?: string;
  recovery_state: 'stable' | 'recovering' | 'failed';
}

/**
 * Session information
 */
export interface SessionInfo {
  session_id: string;
  connection_id?: string; // undefined if not currently connected
  status: 'active' | 'disconnected' | 'persisted';
  created_at: Date;
  last_active: Date;
  
  // Persistence
  persisted: boolean;
  auto_recover: boolean;
  recovery_count: number;
  
  // Resources
  has_tunnels: boolean;
  has_port_forwards: boolean;
  has_jump_chain: boolean;
}

/**
 * Session recovery result
 */
export interface SessionRecoveryResult extends ToolResult {
  data?: {
    session_id: string;
    connection_id: string;
    recovery_time_ms: number;
    recovered_resources: {
      tunnels: number;
      port_forwards: number;
      jump_chain: boolean;
    };
    warnings: string[];
  };
}

/**
 * Session state snapshot
 */
export interface SessionState {
  session_id: string;
  timestamp: Date;
  connection_state: 'connected' | 'disconnected';
  active_tunnels: string[];
  active_port_forwards: string[];
  jump_chain_id?: string;
  metrics: {
    uptime_seconds: number;
    total_bytes_transferred: number;
    total_commands: number;
  };
}
```

---

## 🔐 Multi-Factor Authentication Types

### MFA Configuration

```typescript
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
  methods: MFAMethod[];
  required_for: Array<'connection' | 'sudo_commands' | 'sensitive_operations'>;
  
  // TOTP settings
  totp?: {
    secret_key?: string;
    issuer?: string;
    algorithm?: 'SHA1' | 'SHA256' | 'SHA512';
    digits?: 6 | 8;
    period?: number; // seconds, default 30
  };
  
  // Hardware token settings
  hardware?: {
    device_path?: string;
    challenge_response?: boolean;
  };
  
  // Backup codes
  backup_codes?: string[];
  backup_codes_remaining?: number;
}

/**
 * MFA authentication request
 */
export interface MFAAuthArgs {
  connection_id: string;
  method: MFAMethod;
  code: string;
  
  // Optional context
  operation?: string; // what operation requires MFA
  timestamp?: number;
}

/**
 * MFA authentication result
 */
export interface MFAAuthResult extends ToolResult {
  data?: {
    authenticated: boolean;
    method: MFAMethod;
    valid_until?: Date;
    attempts_remaining?: number;
  };
}

/**
 * MFA setup data
 */
export interface MFASetup {
  method: MFAMethod;
  secret?: string; // for TOTP
  qr_code?: string; // base64 QR code image
  backup_codes?: string[];
  verification_required: boolean;
}
```

---

## 🔄 Connection Pool Types

### Pool Management

```typescript
/**
 * Connection pool configuration
 */
export interface ConnectionPoolConfig {
  max_connections: number; // max concurrent connections
  max_idle_time_ms: number; // time before idle connection is closed
  max_connection_age_ms?: number; // max age before forced refresh
  
  // Health checks
  health_check_interval_ms?: number;
  health_check_timeout_ms?: number;
  
  // Resource limits
  max_memory_mb?: number;
  max_bandwidth_mbps?: number;
}

/**
 * Connection pool statistics
 */
export interface PoolStatistics {
  total_connections: number;
  active_connections: number;
  idle_connections: number;
  failed_connections: number;
  
  // Performance
  avg_connection_time_ms: number;
  avg_latency_ms: number;
  
  // Resource usage
  total_bytes_transferred: number;
  memory_usage_mb: number;
  
  // Health
  health_check_failures: number;
  last_health_check: Date;
}

/**
 * Pool status information
 */
export interface PoolStatus {
  statistics: PoolStatistics;
  connections: Array<{
    id: string;
    host: string;
    status: 'active' | 'idle' | 'failed';
    age_seconds: number;
    last_used: Date;
  }>;
  health: 'healthy' | 'degraded' | 'critical';
  warnings: string[];
}
```

---

## 🔍 Monitoring & Metrics Types

### System Metrics

```typescript
/**
 * SSH subsystem metrics
 */
export interface SSHMetrics {
  // Connection metrics
  connections: {
    total: number;
    active: number;
    failed: number;
    success_rate: number;
  };
  
  // Tunnel metrics
  tunnels: {
    total: number;
    active: number;
    bytes_transferred: number;
    avg_throughput_mbps: number;
  };
  
  // Performance metrics
  performance: {
    avg_connection_time_ms: number;
    avg_latency_ms: number;
    p95_latency_ms: number;
    p99_latency_ms: number;
  };
  
  // Error metrics
  errors: {
    authentication_failures: number;
    connection_timeouts: number;
    tunnel_failures: number;
    command_rejections: number;
  };
  
  // Resource metrics
  resources: {
    memory_usage_mb: number;
    cpu_usage_percent: number;
    bandwidth_usage_mbps: number;
  };
}

/**
 * Alert configuration
 */
export interface SSHAlert {
  type: 'connection_failure' | 'high_latency' | 'resource_limit' | 'security';
  severity: 'info' | 'warning' | 'critical';
  message: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}
```

---

## 📊 Tool Argument Types

### Tool Input Arguments

```typescript
/**
 * SSH tunnel tool arguments
 */
export interface SSHTunnelArgs {
  type: TunnelType;
  connection_id: string;
  
  // Local tunnel specific
  local_port?: number;
  remote_host?: string;
  remote_port?: number;
  
  // Remote tunnel specific
  local_host?: string;
  
  // Dynamic tunnel specific
  socks_port?: number;
  socks_version?: 4 | 5;
  
  // Common options
  bind_address?: string;
  keep_alive?: boolean;
  timeout_seconds?: number;
  monitor_interval?: number;
  auto_restart?: boolean;
}

/**
 * SSH port forward tool arguments
 */
export interface SSHPortForwardArgs {
  connection_id: string;
  forwards: PortForwardRule[];
  auto_reconnect?: boolean;
  validate_ports?: boolean;
  conflict_resolution?: 'fail' | 'auto_assign' | 'force';
}

/**
 * SSH jump host tool arguments
 */
export interface SSHJumpHostArgs {
  target: SSHConfig;
  jumps: JumpHostConfig[];
  strategy?: JumpStrategy;
  max_total_latency_ms?: number;
  timeout_per_hop_ms?: number;
  parallel_probe?: boolean;
  cache_successful_path?: boolean;
}

/**
 * SSH session manager tool arguments
 */
export interface SSHSessionArgs {
  action: 'save' | 'restore' | 'list' | 'cleanup' | 'status';
  session_id?: string;
  connection_id?: string;
  persist?: boolean;
  auto_recover?: boolean;
  max_recovery_attempts?: number;
}

/**
 * SSH connection pool tool arguments
 */
export interface SSHConnectionPoolArgs {
  action: 'status' | 'prune' | 'stats' | 'health';
  max_idle_time_ms?: number;
  connection_id?: string;
}

/**
 * SSH MFA tool arguments
 */
export interface SSHMFAArgs extends MFAAuthArgs {
  // Inherits from MFAAuthArgs
}
```

---

## ✅ Type Guards & Validators

### Type Guard Functions

```typescript
/**
 * Type guard for tunnel configuration
 */
export function isLocalTunnelConfig(config: TunnelConfig): config is LocalTunnelConfig {
  return config.type === 'local';
}

export function isRemoteTunnelConfig(config: TunnelConfig): config is RemoteTunnelConfig {
  return config.type === 'remote';
}

export function isDynamicTunnelConfig(config: TunnelConfig): config is DynamicTunnelConfig {
  return config.type === 'dynamic';
}

/**
 * Validation functions
 */
export interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

export type ValidateSS

HConfig = (config: SSHConfig) => ValidationResult;
export type ValidateTunnelConfig = (config: TunnelConfig) => ValidationResult;
export type ValidatePortForwardConfig = (config: PortForwardConfig) => ValidationResult;
export type ValidateJumpChainConfig = (config: JumpChainConfig) => ValidationResult;
```

---

## 📝 Usage Examples (Type Definitions)

### Example: Creating a Local Tunnel

```typescript
const tunnelConfig: LocalTunnelConfig = {
  type: 'local',
  connection_id: 'conn-123',
  local_port: 5432,
  remote_host: 'db.internal.example.com',
  remote_port: 5432,
  bind_address: 'localhost',
  keep_alive: true,
  timeout_seconds: 300,
  monitor_interval: 30,
  auto_restart: true
};
```

### Example: Creating a Jump Chain

```typescript
const jumpChainConfig: JumpChainConfig = {
  target: {
    host: '10.0.1.50',
    port: 22,
    username: 'admin',
    auth_method: 'key',
    key_path: '~/.ssh/private_key'
  },
  jumps: [
    {
      host: 'bastion.example.com',
      port: 22,
      username: 'jumpuser',
      auth_method: 'key',
      key_path: '~/.ssh/jump_key',
      forward_agent: true,
      priority: 1
    }
  ],
  strategy: 'optimal',
  max_total_latency_ms: 1000,
  cache_successful_path: true,
  cache_duration_minutes: 60
};
```

### Example: Session Configuration

```typescript
const sessionConfig: SessionConfig = {
  connection_id: 'conn-123',
  persist: true,
  auto_recover: true,
  max_recovery_attempts: 5,
  recovery_backoff_ms: 5000,
  recovery_strategy: 'exponential',
  save_tunnel_state: true,
  save_port_forwards: true,
  save_jump_chain: true
};
```

---

## 🎯 Implementation Notes

### File Organization

1. **Main Types File**: `src/types/extended-tools.ts`
   - Add SSH advanced types to existing file
   - Keep consistent with current structure

2. **Or New File**: `src/types/ssh-advanced.ts`
   - Create separate file for SSH types
   - Export from `src/types/index.ts`

### Type Safety Guidelines

1. **Use Discriminated Unions**: For tunnel types, use `type` field as discriminator
2. **Make Optional Fields Explicit**: Use `?` for truly optional fields
3. **Provide Default Values**: Document default values in comments
4. **Use Readonly When Appropriate**: Mark immutable fields as `readonly`
5. **Export All Types**: Ensure all types are exported for external use

### Validation Strategy

1. **Runtime Validation**: Implement validators for all configuration types
2. **Type Guards**: Provide type guard functions for union types
3. **Error Messages**: Return clear, actionable error messages
4. **Schema Validation**: Consider using Zod or similar for runtime checks

---

## 📚 Dependencies

### Required npm Packages

```json
{
  "dependencies": {
    "ssh2": "^1.15.0",
    "@types/ssh2": "^1.15.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "@types/node": "^22.0.0"
  }
}
```

---

## 🔄 Version History

- **v1.0** (2025-11-26): Initial type specification
- **Next**: Type implementation and validation

---

**Document Status**: Complete  
**Next Step**: Implement these types in TypeScript files  
**Related Documents**: 
- [`SSH-ADVANCED-TOOLS-ARCHITECTURE.md`](./SSH-ADVANCED-TOOLS-ARCHITECTURE.md)
- [`extended-tools.ts`](../src/types/extended-tools.ts)