/**
 * Infrastructure Types Specification
 * Complete type definitions for NFS, NAS, Cluster, and Server management tools.
 *
 * This follows the same pattern as ssh-advanced.ts for consistency.
 */
import type { ValidationResult } from './ssh-advanced.js';
/**
 * Execution mode for infrastructure operations
 */
export type ExecutionMode = 'local' | 'remote';
/**
 * Supported Linux distributions
 */
export type Distro = 'nixos' | 'ubuntu' | 'debian' | 'rhel' | 'centos' | 'fedora';
/**
 * Execution context for infrastructure operations
 */
export interface ExecutionContext {
    /** Execution mode (local or remote) */
    readonly mode: ExecutionMode;
    /** Target hostname for remote execution */
    readonly target?: string;
    /** SSH connection ID if using remote execution */
    readonly ssh_connection_id?: string;
    /** Whether sudo elevation is required */
    readonly sudo_required: boolean;
    /** User executing the operation */
    readonly user: string;
    /** Detected or specified Linux distribution */
    readonly distro?: Distro;
    /** Working directory for operation */
    readonly working_dir?: string;
    /** Environment variables for operation */
    readonly env?: Record<string, string>;
    /** Operation timeout in milliseconds */
    readonly timeout_ms?: number;
}
/**
 * Result of infrastructure operations
 */
export interface OperationResult<T = any> {
    /** Whether operation succeeded */
    readonly success: boolean;
    /** Result data */
    readonly data?: T;
    /** Error message if failed */
    readonly error?: string;
    /** Execution context used */
    readonly context: ExecutionContext;
    /** Execution duration in milliseconds */
    readonly duration_ms: number;
    /** Timestamp of operation */
    readonly timestamp: Date;
    /** Additional metadata */
    readonly metadata?: Record<string, any>;
}
/**
 * NFS protocol version
 */
export type NFSVersion = '3' | '4' | '4.1' | '4.2';
/**
 * NFS security mode
 */
export type NFSSecurityMode = 'sys' | 'krb5' | 'krb5i' | 'krb5p';
/**
 * NFS mount state
 */
export type NFSMountState = 'mounted' | 'unmounted' | 'error' | 'unknown';
/**
 * NFS health status
 */
export type NFSHealthStatus = 'healthy' | 'degraded' | 'failed' | 'unknown';
/**
 * NFS mount options
 */
export interface NFSMountOptions {
    /** Read-write or read-only */
    readonly rw?: boolean;
    /** Asynchronous I/O */
    readonly async?: boolean;
    /** Synchronous I/O */
    readonly sync?: boolean;
    /** No access time updates */
    readonly noatime?: boolean;
    /** Hard mount (recommended) */
    readonly hard?: boolean;
    /** Soft mount */
    readonly soft?: boolean;
    /** RPC timeout in deciseconds */
    readonly timeo?: number;
    /** Number of retries */
    readonly retrans?: number;
    /** Read size in bytes */
    readonly rsize?: number;
    /** Write size in bytes */
    readonly wsize?: number;
    /** Additional custom options */
    readonly custom?: string[];
}
/**
 * NFS mount configuration
 */
export interface NFSMountConfig {
    /** NFS source (server:/export/path) */
    readonly source: string;
    /** Local mount target */
    readonly target: string;
    /** NFS version */
    readonly version: NFSVersion;
    /** Mount options */
    readonly options?: NFSMountOptions;
    /** Add to /etc/fstab for auto-mount */
    readonly auto_mount?: boolean;
    /** Verify mount after mounting */
    readonly verify_mount?: boolean;
    /** Create mount point if it doesn't exist */
    readonly create_mountpoint?: boolean;
}
/**
 * Active NFS mount information
 */
export interface NFSMount {
    /** Mount source */
    readonly source: string;
    /** Mount target */
    readonly target: string;
    /** NFS version */
    readonly version: NFSVersion;
    /** Mount options as string */
    readonly options: string;
    /** Mount status */
    readonly status: NFSMountState;
    /** Mount time */
    readonly mounted_at?: Date;
    /** Error message if status is error */
    readonly error?: string;
}
/**
 * NFS export options
 */
export interface NFSExportOptions {
    /** Read-write access */
    readonly rw?: boolean;
    /** Read-only access */
    readonly ro?: boolean;
    /** Synchronous writes */
    readonly sync?: boolean;
    /** Asynchronous writes */
    readonly async?: boolean;
    /** No subtree check */
    readonly no_subtree_check?: boolean;
    /** No root squash */
    readonly no_root_squash?: boolean;
    /** Root squash */
    readonly root_squash?: boolean;
    /** All squash */
    readonly all_squash?: boolean;
    /** Anonymous UID */
    readonly anonuid?: number;
    /** Anonymous GID */
    readonly anongid?: number;
    /** Security mode */
    readonly sec?: NFSSecurityMode[];
    /** Custom options */
    readonly custom?: string[];
}
/**
 * NFS export configuration
 */
export interface NFSExportConfig {
    /** Export path */
    readonly path: string;
    /** Allowed clients (hostnames, IPs, or CIDR) */
    readonly clients: string[];
    /** Export options */
    readonly options: NFSExportOptions;
    /** Comment for export entry */
    readonly comment?: string;
}
/**
 * Active NFS export information
 */
export interface NFSExport {
    /** Export path */
    readonly path: string;
    /** Allowed clients */
    readonly clients: string[];
    /** Export options string */
    readonly options: string;
    /** Export ID */
    readonly id: number;
    /** Export status */
    readonly status: 'active' | 'inactive' | 'error';
    /** Number of active connections */
    readonly active_connections?: number;
}
/**
 * NFS health check result
 */
export interface NFSHealth {
    /** Mount point or export path */
    readonly path: string;
    /** Overall health status */
    readonly status: NFSHealthStatus;
    /** Server reachable */
    readonly server_reachable: boolean;
    /** Mount accessible */
    readonly mount_accessible: boolean;
    /** Response time in milliseconds */
    readonly response_time_ms: number;
    /** Last health check time */
    readonly last_check: Date;
    /** List of issues */
    readonly issues: string[];
    /** Health metrics */
    readonly metrics: NFSMetrics;
}
/**
 * NFS performance metrics
 */
export interface NFSMetrics {
    /** Read IOPS */
    readonly read_iops: number;
    /** Write IOPS */
    readonly write_iops: number;
    /** Average latency in milliseconds */
    readonly latency_ms: number;
    /** Throughput in MB/s */
    readonly throughput_mbps: number;
    /** Operations per second */
    readonly ops_per_sec: number;
    /** Bytes read */
    readonly bytes_read: number;
    /** Bytes written */
    readonly bytes_written: number;
    /** Number of operations */
    readonly operations: number;
    /** Number of errors */
    readonly errors: number;
}
/**
 * NFS operation types (discriminated union)
 */
export type NFSOperation = {
    type: 'mount';
    config: NFSMountConfig;
} | {
    type: 'unmount';
    target: string;
} | {
    type: 'list_mounts';
} | {
    type: 'health_check';
    target: string;
} | {
    type: 'get_metrics';
    target: string;
} | {
    type: 'add_export';
    config: NFSExportConfig;
} | {
    type: 'remove_export';
    path: string;
} | {
    type: 'list_exports';
} | {
    type: 'reload_exports';
};
/**
 * NFS operation result
 */
export interface NFSOperationResult extends OperationResult {
    readonly operation: NFSOperation;
}
/**
 * Filesystem types
 */
export type FilesystemType = 'ext4' | 'xfs' | 'btrfs' | 'zfs';
/**
 * Volume status
 */
export type VolumeStatus = 'online' | 'offline' | 'degraded' | 'failed' | 'maintenance';
/**
 * Snapshot status
 */
export type SnapshotStatus = 'valid' | 'invalid' | 'creating' | 'deleting';
/**
 * NAS protocol types
 */
export type NASProtocol = 'nfs' | 'smb' | 'iscsi' | 'afp';
/**
 * SMB version
 */
export type SMBVersion = '2.0' | '2.1' | '3.0' | '3.1.1';
/**
 * Quota type
 */
export type QuotaType = 'user' | 'group' | 'project';
/**
 * NAS volume configuration
 */
export interface NASVolumeConfig {
    /** Volume name */
    readonly name: string;
    /** Volume size in GB */
    readonly size_gb: number;
    /** Storage pool name */
    readonly pool?: string;
    /** Filesystem type */
    readonly filesystem?: FilesystemType;
    /** Enable compression */
    readonly compression?: boolean;
    /** Enable deduplication */
    readonly deduplication?: boolean;
    /** Enable encryption */
    readonly encryption?: boolean;
    /** Encryption key */
    readonly encryption_key?: string;
    /** Volume description */
    readonly description?: string;
    /** Volume labels */
    readonly labels?: Record<string, string>;
}
/**
 * NAS volume information
 */
export interface NASVolume {
    /** Volume name */
    readonly name: string;
    /** Volume ID */
    readonly id: string;
    /** Volume size in GB */
    readonly size_gb: number;
    /** Used space in GB */
    readonly used_gb: number;
    /** Available space in GB */
    readonly available_gb: number;
    /** Storage pool */
    readonly pool: string;
    /** Filesystem type */
    readonly filesystem: FilesystemType;
    /** Volume status */
    readonly status: VolumeStatus;
    /** Compression enabled */
    readonly compression: boolean;
    /** Deduplication enabled */
    readonly deduplication: boolean;
    /** Encryption enabled */
    readonly encryption: boolean;
    /** Creation time */
    readonly created_at: Date;
    /** Last modified time */
    readonly modified_at: Date;
    /** Mount path if mounted */
    readonly mount_path?: string;
    /** Volume labels */
    readonly labels?: Record<string, string>;
}
/**
 * Detailed volume information
 */
export interface NASVolumeDetails extends NASVolume {
    /** Volume UUID */
    readonly uuid: string;
    /** Number of snapshots */
    readonly snapshot_count: number;
    /** Compression ratio */
    readonly compression_ratio?: number;
    /** Deduplication ratio */
    readonly dedup_ratio?: number;
    /** IOPS statistics */
    readonly iops: {
        readonly read: number;
        readonly write: number;
    };
    /** Throughput statistics */
    readonly throughput: {
        readonly read_mbps: number;
        readonly write_mbps: number;
    };
    /** Access control list */
    readonly acl?: string[];
}
/**
 * NAS snapshot configuration
 */
export interface NASSnapshotConfig {
    /** Volume name */
    readonly volume: string;
    /** Snapshot name */
    readonly name: string;
    /** Retention period in days */
    readonly retention_days?: number;
    /** Snapshot description */
    readonly description?: string;
    /** Snapshot labels */
    readonly labels?: Record<string, string>;
}
/**
 * NAS snapshot information
 */
export interface NASSnapshot {
    /** Snapshot name */
    readonly name: string;
    /** Snapshot ID */
    readonly id: string;
    /** Volume name */
    readonly volume: string;
    /** Snapshot status */
    readonly status: SnapshotStatus;
    /** Snapshot size in GB */
    readonly size_gb: number;
    /** Creation time */
    readonly created_at: Date;
    /** Expiration time */
    readonly expires_at?: Date;
    /** Snapshot description */
    readonly description?: string;
    /** Snapshot labels */
    readonly labels?: Record<string, string>;
}
/**
 * Snapshot clone configuration
 */
export interface SnapshotCloneConfig {
    /** Source volume */
    readonly source_volume: string;
    /** Source snapshot */
    readonly source_snapshot: string;
    /** New volume name */
    readonly new_volume_name: string;
    /** Clone description */
    readonly description?: string;
}
/**
 * NFS protocol configuration
 */
export interface NFSProtocolConfig {
    readonly type: 'nfs';
    readonly volume: string;
    readonly enabled: boolean;
    readonly version: NFSVersion;
    readonly export_options: NFSExportOptions;
    readonly allowed_clients: string[];
}
/**
 * SMB protocol configuration
 */
export interface SMBProtocolConfig {
    readonly type: 'smb';
    readonly volume: string;
    readonly enabled: boolean;
    readonly version: SMBVersion;
    readonly share_name: string;
    readonly comment?: string;
    readonly read_only: boolean;
    readonly browseable: boolean;
    readonly guest_ok: boolean;
    readonly valid_users?: string[];
    readonly write_list?: string[];
    readonly create_mask?: string;
    readonly directory_mask?: string;
}
/**
 * Protocol configuration (discriminated union)
 */
export type ProtocolConfig = NFSProtocolConfig | SMBProtocolConfig;
/**
 * NAS share information
 */
export interface NASShare {
    /** Share name */
    readonly name: string;
    /** Protocol type */
    readonly protocol: NASProtocol;
    /** Volume name */
    readonly volume: string;
    /** Share path */
    readonly path: string;
    /** Share enabled */
    readonly enabled: boolean;
    /** Active connections */
    readonly active_connections: number;
    /** Share configuration */
    readonly config: ProtocolConfig;
}
/**
 * NAS quota configuration
 */
export interface NASQuotaConfig {
    /** Volume name */
    readonly volume: string;
    /** Quota type */
    readonly type: QuotaType;
    /** Target (username, groupname, or project ID) */
    readonly target: string;
    /** Soft limit in GB */
    readonly soft_limit_gb: number;
    /** Hard limit in GB */
    readonly hard_limit_gb: number;
    /** Grace period in days */
    readonly grace_period_days?: number;
}
/**
 * NAS quota information
 */
export interface NASQuota {
    /** Volume name */
    readonly volume: string;
    /** Quota type */
    readonly type: QuotaType;
    /** Target */
    readonly target: string;
    /** Soft limit in GB */
    readonly soft_limit_gb: number;
    /** Hard limit in GB */
    readonly hard_limit_gb: number;
    /** Current usage in GB */
    readonly used_gb: number;
    /** Quota exceeded */
    readonly exceeded: boolean;
    /** Grace period remaining in days */
    readonly grace_remaining_days?: number;
}
/**
 * NAS operation types (discriminated union)
 */
export type NASOperation = {
    type: 'create_volume';
    config: NASVolumeConfig;
} | {
    type: 'delete_volume';
    name: string;
} | {
    type: 'resize_volume';
    name: string;
    new_size_gb: number;
} | {
    type: 'list_volumes';
} | {
    type: 'get_volume';
    name: string;
} | {
    type: 'create_snapshot';
    config: NASSnapshotConfig;
} | {
    type: 'delete_snapshot';
    volume: string;
    snapshot: string;
} | {
    type: 'list_snapshots';
    volume: string;
} | {
    type: 'restore_snapshot';
    volume: string;
    snapshot: string;
} | {
    type: 'clone_snapshot';
    config: SnapshotCloneConfig;
} | {
    type: 'configure_protocol';
    config: ProtocolConfig;
} | {
    type: 'list_shares';
} | {
    type: 'set_quota';
    config: NASQuotaConfig;
} | {
    type: 'get_quota';
    volume: string;
    quota_type: QuotaType;
    target: string;
} | {
    type: 'list_quotas';
    volume: string;
};
/**
 * NAS operation result
 */
export interface NASOperationResult extends OperationResult {
    readonly operation: NASOperation;
}
/**
 * Cluster orchestrator type
 */
export type ClusterType = 'kubernetes' | 'docker_swarm';
/**
 * Cluster health status
 */
export type ClusterHealthStatus = 'healthy' | 'degraded' | 'unhealthy' | 'unknown';
/**
 * Node status
 */
export type NodeStatus = 'ready' | 'not_ready' | 'unknown' | 'cordoned' | 'draining';
/**
 * Workload status
 */
export type WorkloadStatus = 'running' | 'pending' | 'failed' | 'succeeded' | 'unknown';
/**
 * Base cluster information
 */
export interface ClusterInfo {
    /** Cluster name */
    readonly name: string;
    /** Cluster type */
    readonly type: ClusterType;
    /** Cluster version */
    readonly version: string;
    /** Cluster endpoint */
    readonly endpoint: string;
    /** Number of nodes */
    readonly node_count: number;
    /** Cluster health */
    readonly health: ClusterHealthStatus;
}
/**
 * Base node information
 */
export interface Node {
    /** Node name */
    readonly name: string;
    /** Node status */
    readonly status: NodeStatus;
    /** Node roles */
    readonly roles: string[];
    /** Node age */
    readonly age: string;
    /** Node version */
    readonly version: string;
    /** Node IP addresses */
    readonly addresses: {
        readonly internal: string;
        readonly external?: string;
    };
    /** Resource capacity */
    readonly capacity: {
        readonly cpu: string;
        readonly memory: string;
        readonly pods?: number;
    };
    /** Resource allocatable */
    readonly allocatable: {
        readonly cpu: string;
        readonly memory: string;
        readonly pods?: number;
    };
}
/**
 * Base workload information
 */
export interface Workload {
    /** Workload name */
    readonly name: string;
    /** Workload type */
    readonly type: string;
    /** Workload status */
    readonly status: WorkloadStatus;
    /** Desired replicas */
    readonly desired_replicas: number;
    /** Current replicas */
    readonly current_replicas: number;
    /** Ready replicas */
    readonly ready_replicas: number;
    /** Creation time */
    readonly created_at: Date;
}
/**
 * Kubernetes cluster information
 */
export interface K8sClusterInfo extends ClusterInfo {
    readonly type: 'kubernetes';
    /** API server version */
    readonly api_version: string;
    /** Number of namespaces */
    readonly namespace_count: number;
    /** Platform (cloud provider or on-prem) */
    readonly platform?: string;
}
/**
 * Kubernetes namespace
 */
export interface K8sNamespace {
    /** Namespace name */
    readonly name: string;
    /** Namespace status */
    readonly status: 'Active' | 'Terminating';
    /** Creation time */
    readonly created_at: Date;
    /** Resource quotas */
    readonly quotas?: Array<{
        readonly name: string;
        readonly hard: Record<string, string>;
        readonly used: Record<string, string>;
    }>;
    /** Labels */
    readonly labels?: Record<string, string>;
}
/**
 * Kubernetes pod information
 */
export interface K8sPod extends Workload {
    readonly type: 'Pod';
    /** Namespace */
    readonly namespace: string;
    /** Pod phase */
    readonly phase: 'Pending' | 'Running' | 'Succeeded' | 'Failed' | 'Unknown';
    /** Node name */
    readonly node: string;
    /** Pod IP */
    readonly ip: string;
    /** Container statuses */
    readonly containers: Array<{
        readonly name: string;
        readonly ready: boolean;
        readonly restart_count: number;
        readonly image: string;
    }>;
    /** Conditions */
    readonly conditions: Array<{
        readonly type: string;
        readonly status: boolean;
        readonly reason?: string;
    }>;
}
/**
 * Kubernetes deployment information
 */
export interface K8sDeployment extends Workload {
    readonly type: 'Deployment';
    /** Namespace */
    readonly namespace: string;
    /** Strategy */
    readonly strategy: 'RollingUpdate' | 'Recreate';
    /** Selector labels */
    readonly selector: Record<string, string>;
    /** Template spec */
    readonly template: {
        readonly containers: Array<{
            readonly name: string;
            readonly image: string;
            readonly ports?: Array<{
                readonly name?: string;
                readonly protocol: string;
                readonly container_port: number;
            }>;
        }>;
    };
    /** Conditions */
    readonly conditions: Array<{
        readonly type: string;
        readonly status: boolean;
        readonly reason?: string;
    }>;
}
/**
 * Kubernetes service information
 */
export interface K8sService {
    /** Service name */
    readonly name: string;
    /** Namespace */
    readonly namespace: string;
    /** Service type */
    readonly type: 'ClusterIP' | 'NodePort' | 'LoadBalancer' | 'ExternalName';
    /** Cluster IP */
    readonly cluster_ip: string;
    /** External IPs */
    readonly external_ips?: string[];
    /** Load balancer IP */
    readonly load_balancer_ip?: string;
    /** Ports */
    readonly ports: Array<{
        readonly name?: string;
        readonly protocol: string;
        readonly port: number;
        readonly target_port: number | string;
        readonly node_port?: number;
    }>;
    /** Selector */
    readonly selector: Record<string, string>;
    /** Creation time */
    readonly created_at: Date;
}
/**
 * Kubernetes ConfigMap
 */
export interface K8sConfigMap {
    /** ConfigMap name */
    readonly name: string;
    /** Namespace */
    readonly namespace: string;
    /** Data */
    readonly data: Record<string, string>;
    /** Binary data */
    readonly binary_data?: Record<string, string>;
    /** Creation time */
    readonly created_at: Date;
}
/**
 * Kubernetes Secret
 */
export interface K8sSecret {
    /** Secret name */
    readonly name: string;
    /** Namespace */
    readonly namespace: string;
    /** Secret type */
    readonly type: string;
    /** Data keys (values not exposed) */
    readonly data_keys: string[];
    /** Creation time */
    readonly created_at: Date;
}
/**
 * Kubernetes health status
 */
export interface K8sHealthStatus {
    /** Overall status */
    readonly status: ClusterHealthStatus;
    /** API server healthy */
    readonly api_server_healthy: boolean;
    /** Controller manager healthy */
    readonly controller_manager_healthy: boolean;
    /** Scheduler healthy */
    readonly scheduler_healthy: boolean;
    /** etcd healthy */
    readonly etcd_healthy: boolean;
    /** Node statuses */
    readonly nodes: {
        readonly total: number;
        readonly ready: number;
        readonly not_ready: number;
    };
    /** Issues */
    readonly issues: string[];
}
/**
 * Kubernetes metrics
 */
export interface K8sMetrics {
    /** CPU usage */
    readonly cpu: {
        readonly used_cores: number;
        readonly total_cores: number;
        readonly usage_percent: number;
    };
    /** Memory usage */
    readonly memory: {
        readonly used_bytes: number;
        readonly total_bytes: number;
        readonly usage_percent: number;
    };
    /** Pod metrics */
    readonly pods: {
        readonly total: number;
        readonly running: number;
        readonly pending: number;
        readonly failed: number;
    };
}
/**
 * Docker Swarm cluster information
 */
export interface SwarmInfo extends ClusterInfo {
    readonly type: 'docker_swarm';
    /** Swarm ID */
    readonly swarm_id: string;
    /** Manager count */
    readonly managers: number;
    /** Worker count */
    readonly workers: number;
    /** Swarm creation time */
    readonly created_at: Date;
    /** Swarm updated time */
    readonly updated_at: Date;
}
/**
 * Docker Swarm node information
 */
export interface SwarmNode extends Node {
    /** Node ID */
    readonly id: string;
    /** Node availability */
    readonly availability: 'active' | 'pause' | 'drain';
    /** Manager status */
    readonly manager_status?: {
        readonly leader: boolean;
        readonly reachability: 'reachable' | 'unreachable';
        readonly addr: string;
    };
    /** Engine version */
    readonly engine_version: string;
    /** Platform */
    readonly platform: {
        readonly os: string;
        readonly architecture: string;
    };
}
/**
 * Docker Swarm service
 */
export interface SwarmService {
    /** Service ID */
    readonly id: string;
    /** Service name */
    readonly name: string;
    /** Service mode */
    readonly mode: 'replicated' | 'global';
    /** Replicas (for replicated mode) */
    readonly replicas?: {
        readonly desired: number;
        readonly running: number;
    };
    /** Image */
    readonly image: string;
    /** Ports */
    readonly ports: Array<{
        readonly protocol: 'tcp' | 'udp';
        readonly target_port: number;
        readonly published_port?: number;
        readonly publish_mode?: 'ingress' | 'host';
    }>;
    /** Networks */
    readonly networks: string[];
    /** Mounts */
    readonly mounts?: Array<{
        readonly type: 'bind' | 'volume';
        readonly source: string;
        readonly target: string;
        readonly readonly: boolean;
    }>;
    /** Environment variables */
    readonly env?: string[];
    /** Creation time */
    readonly created_at: Date;
    /** Updated time */
    readonly updated_at: Date;
}
/**
 * Docker Swarm stack
 */
export interface SwarmStack {
    /** Stack name */
    readonly name: string;
    /** Services count */
    readonly services: number;
    /** Networks count */
    readonly networks: number;
    /** Volumes count */
    readonly volumes: number;
}
/**
 * Docker Swarm network
 */
export interface SwarmNetwork {
    /** Network ID */
    readonly id: string;
    /** Network name */
    readonly name: string;
    /** Driver */
    readonly driver: string;
    /** Scope */
    readonly scope: 'local' | 'swarm';
    /** Attachable */
    readonly attachable: boolean;
    /** Ingress */
    readonly ingress: boolean;
    /** IPv4 subnet */
    readonly ipv4_subnet?: string;
    /** IPv6 subnet */
    readonly ipv6_subnet?: string;
    /** Creation time */
    readonly created_at: Date;
}
/**
 * Docker Swarm volume
 */
export interface SwarmVolume {
    /** Volume name */
    readonly name: string;
    /** Driver */
    readonly driver: string;
    /** Mount point */
    readonly mount_point: string;
    /** Labels */
    readonly labels: Record<string, string>;
    /** Scope */
    readonly scope: 'local' | 'global';
    /** Creation time */
    readonly created_at: Date;
}
/**
 * Docker Swarm health status
 */
export interface SwarmHealthStatus {
    /** Overall status */
    readonly status: ClusterHealthStatus;
    /** Swarm active */
    readonly swarm_active: boolean;
    /** Manager nodes */
    readonly managers: {
        readonly total: number;
        readonly healthy: number;
    };
    /** Worker nodes */
    readonly workers: {
        readonly total: number;
        readonly active: number;
    };
    /** Issues */
    readonly issues: string[];
}
/**
 * Docker Swarm metrics
 */
export interface SwarmMetrics {
    /** Node metrics */
    readonly nodes: {
        readonly total: number;
        readonly managers: number;
        readonly workers: number;
    };
    /** Service metrics */
    readonly services: {
        readonly total: number;
        readonly running: number;
        readonly failed: number;
    };
    /** Container metrics */
    readonly containers: {
        readonly total: number;
        readonly running: number;
        readonly stopped: number;
    };
}
/**
 * Cluster operation types (discriminated union)
 */
export type ClusterOperation = {
    type: 'get_info';
    cluster_type: ClusterType;
} | {
    type: 'get_health';
    cluster_type: ClusterType;
} | {
    type: 'list_nodes';
    cluster_type: ClusterType;
} | {
    type: 'get_node';
    cluster_type: ClusterType;
    name: string;
} | {
    type: 'drain_node';
    cluster_type: ClusterType;
    name: string;
} | {
    type: 'list_workloads';
    cluster_type: ClusterType;
    namespace?: string;
} | {
    type: 'scale_workload';
    cluster_type: ClusterType;
    name: string;
    namespace?: string;
    replicas: number;
} | {
    type: 'list_services';
    cluster_type: ClusterType;
    namespace?: string;
} | {
    type: 'get_metrics';
    cluster_type: ClusterType;
};
/**
 * Cluster operation result
 */
export interface ClusterOperationResult extends OperationResult {
    readonly operation: ClusterOperation;
    readonly cluster_type: ClusterType;
}
/**
 * Package manager type
 */
export type PackageManager = 'nix' | 'apt' | 'yum' | 'dnf' | 'pacman';
/**
 * Package status
 */
export type PackageStatus = 'installed' | 'not_installed' | 'upgradable' | 'broken';
/**
 * Service manager type
 */
export type ServiceManager = 'systemd' | 'initd' | 'upstart';
/**
 * Service state
 */
export type ServiceState = 'running' | 'stopped' | 'failed' | 'inactive' | 'unknown';
/**
 * Service enable state
 */
export type ServiceEnableState = 'enabled' | 'disabled' | 'static' | 'masked';
/**
 * Service action
 */
export type ServiceAction = 'start' | 'stop' | 'restart' | 'reload' | 'enable' | 'disable' | 'status';
/**
 * Firewall backend
 */
export type FirewallBackend = 'iptables' | 'nftables' | 'firewalld' | 'ufw' | 'nixos';
/**
 * Firewall protocol
 */
export type FirewallProtocol = 'tcp' | 'udp' | 'icmp' | 'all';
/**
 * Firewall action
 */
export type FirewallAction = 'allow' | 'deny' | 'reject' | 'drop';
/**
 * Package information
 */
export interface PackageInfo {
    /** Package name */
    readonly name: string;
    /** Package version */
    readonly version: string;
    /** Package status */
    readonly status: PackageStatus;
    /** Package description */
    readonly description?: string;
    /** Package size in bytes */
    readonly size?: number;
    /** Installation time */
    readonly installed_at?: Date;
    /** Available version */
    readonly available_version?: string;
    /** Package repository */
    readonly repository?: string;
}
/**
 * Package operation configuration
 */
export interface PackageOperation {
    /** Operation type */
    readonly action: 'install' | 'remove' | 'update' | 'search' | 'info';
    /** Package names */
    readonly packages?: string[];
    /** Search query */
    readonly query?: string;
    /** Force operation */
    readonly force?: boolean;
    /** Skip confirmation */
    readonly yes?: boolean;
}
/**
 * Service status
 */
export interface ServiceStatus {
    /** Service name */
    readonly name: string;
    /** Service state */
    readonly state: ServiceState;
    /** Enable state */
    readonly enable_state: ServiceEnableState;
    /** Service description */
    readonly description?: string;
    /** PID if running */
    readonly pid?: number;
    /** Memory usage in bytes */
    readonly memory_bytes?: number;
    /** CPU usage percent */
    readonly cpu_percent?: number;
    /** Service uptime in seconds */
    readonly uptime_seconds?: number;
    /** Restart count */
    readonly restart_count?: number;
    /** Last start time */
    readonly started_at?: Date;
}
/**
 * Service operation
 */
export interface ServiceOperation {
    /** Service name */
    readonly name: string;
    /** Service action */
    readonly action: ServiceAction;
    /** Force operation */
    readonly force?: boolean;
}
/**
 * Firewall rule
 */
export interface FirewallRule {
    /** Rule name/description */
    readonly name?: string;
    /** Protocol */
    readonly protocol: FirewallProtocol;
    /** Port or port range */
    readonly port?: number | string;
    /** Source IP or CIDR */
    readonly source?: string;
    /** Destination IP or CIDR */
    readonly destination?: string;
    /** Action */
    readonly action: FirewallAction;
    /** Interface */
    readonly interface?: string;
    /** Direction */
    readonly direction?: 'in' | 'out' | 'forward';
    /** Priority */
    readonly priority?: number;
}
/**
 * Firewall status
 */
export interface FirewallStatus {
    /** Firewall enabled */
    readonly enabled: boolean;
    /** Firewall backend */
    readonly backend: FirewallBackend;
    /** Default policy */
    readonly default_policy: {
        readonly input: FirewallAction;
        readonly output: FirewallAction;
        readonly forward: FirewallAction;
    };
    /** Number of rules */
    readonly rule_count: number;
    /** Active rules */
    readonly rules: FirewallRule[];
}
/**
 * System information
 */
export interface SystemInfo {
    /** Hostname */
    readonly hostname: string;
    /** Operating system */
    readonly os: string;
    /** OS version */
    readonly os_version: string;
    /** Kernel version */
    readonly kernel: string;
    /** Distribution */
    readonly distro: Distro;
    /** Architecture */
    readonly architecture: string;
    /** CPU information */
    readonly cpu: {
        readonly model: string;
        readonly cores: number;
        readonly threads: number;
        readonly frequency_mhz: number;
    };
    /** Memory information */
    readonly memory: {
        readonly total_bytes: number;
        readonly available_bytes: number;
        readonly used_bytes: number;
        readonly usage_percent: number;
    };
    /** Disk information */
    readonly disks: Array<{
        readonly device: string;
        readonly mount_point: string;
        readonly filesystem: string;
        readonly total_bytes: number;
        readonly used_bytes: number;
        readonly available_bytes: number;
        readonly usage_percent: number;
    }>;
    /** Network interfaces */
    readonly network: Array<{
        readonly name: string;
        readonly ipv4?: string;
        readonly ipv6?: string;
        readonly mac: string;
        readonly status: 'up' | 'down';
    }>;
    /** Uptime in seconds */
    readonly uptime_seconds: number;
    /** Load average */
    readonly load_average: {
        readonly one_minute: number;
        readonly five_minutes: number;
        readonly fifteen_minutes: number;
    };
}
/**
 * System metrics
 */
export interface SystemMetrics {
    /** Timestamp */
    readonly timestamp: Date;
    /** CPU metrics */
    readonly cpu: {
        readonly usage_percent: number;
        readonly user_percent: number;
        readonly system_percent: number;
        readonly idle_percent: number;
        readonly iowait_percent: number;
    };
    /** Memory metrics */
    readonly memory: {
        readonly total_bytes: number;
        readonly used_bytes: number;
        readonly available_bytes: number;
        readonly cached_bytes: number;
        readonly buffers_bytes: number;
        readonly usage_percent: number;
    };
    /** Swap metrics */
    readonly swap: {
        readonly total_bytes: number;
        readonly used_bytes: number;
        readonly free_bytes: number;
        readonly usage_percent: number;
    };
    /** Disk I/O metrics */
    readonly disk_io: {
        readonly read_bytes: number;
        readonly write_bytes: number;
        readonly read_ops: number;
        readonly write_ops: number;
    };
    /** Network metrics */
    readonly network: {
        readonly bytes_sent: number;
        readonly bytes_recv: number;
        readonly packets_sent: number;
        readonly packets_recv: number;
        readonly errors_in: number;
        readonly errors_out: number;
    };
    /** Process metrics */
    readonly processes: {
        readonly total: number;
        readonly running: number;
        readonly sleeping: number;
        readonly zombie: number;
    };
}
/**
 * Server health status
 */
export interface ServerHealth {
    /** Overall status */
    readonly status: 'healthy' | 'warning' | 'critical';
    /** System reachable */
    readonly reachable: boolean;
    /** Response time in ms */
    readonly response_time_ms: number;
    /** CPU health */
    readonly cpu_ok: boolean;
    /** Memory health */
    readonly memory_ok: boolean;
    /** Disk health */
    readonly disk_ok: boolean;
    /** Services health */
    readonly services_ok: boolean;
    /** Issues */
    readonly issues: string[];
    /** Last check */
    readonly last_check: Date;
}
/**
 * Server provisioning configuration
 */
export interface ServerProvisionConfig {
    /** Server hostname */
    readonly hostname: string;
    /** Packages to install */
    readonly packages?: string[];
    /** Services to enable */
    readonly services?: string[];
    /** Firewall rules to add */
    readonly firewall_rules?: FirewallRule[];
    /** Users to create */
    readonly users?: Array<{
        readonly username: string;
        readonly groups?: string[];
        readonly shell?: string;
        readonly ssh_keys?: string[];
    }>;
    /** Files to create/update */
    readonly files?: Array<{
        readonly path: string;
        readonly content: string;
        readonly mode?: string;
        readonly owner?: string;
        readonly group?: string;
    }>;
    /** Commands to run */
    readonly commands?: string[];
}
/**
 * Server operation types (discriminated union)
 */
export type ServerOperation = {
    type: 'package';
    operation: PackageOperation;
} | {
    type: 'service';
    operation: ServiceOperation;
} | {
    type: 'firewall_add_rule';
    rule: FirewallRule;
} | {
    type: 'firewall_remove_rule';
    rule: FirewallRule;
} | {
    type: 'firewall_list_rules';
} | {
    type: 'get_system_info';
} | {
    type: 'get_metrics';
} | {
    type: 'get_health';
} | {
    type: 'provision';
    config: ServerProvisionConfig;
} | {
    type: 'reboot';
    delay_seconds?: number;
};
/**
 * Server operation result
 */
export interface ServerOperationResult extends OperationResult {
    readonly operation: ServerOperation;
}
/**
 * Infrastructure operation category
 */
export type OperationCategory = 'nfs' | 'nas' | 'cluster' | 'server' | 'system';
/**
 * Operation severity
 */
export type OperationSeverity = 'info' | 'warning' | 'error' | 'critical';
/**
 * Audit log entry
 */
export interface AuditLogEntry {
    /** Log entry ID */
    readonly id: string;
    /** Timestamp */
    readonly timestamp: Date;
    /** Operation category */
    readonly category: OperationCategory;
    /** Operation type */
    readonly operation: string;
    /** User */
    readonly user: string;
    /** Execution context */
    readonly context: ExecutionContext;
    /** Operation success */
    readonly success: boolean;
    /** Error message if failed */
    readonly error?: string;
    /** Operation duration */
    readonly duration_ms: number;
    /** Severity */
    readonly severity: OperationSeverity;
    /** Additional metadata */
    readonly metadata?: Record<string, any>;
}
/**
 * Execution context type guards
 */
export declare function isLocalExecution(context: ExecutionContext): boolean;
export declare function isRemoteExecution(context: ExecutionContext): boolean;
/**
 * NFS type guards
 */
export declare function isNFSMountOperation(op: NFSOperation): op is {
    type: 'mount';
    config: NFSMountConfig;
};
export declare function isNFSExportOperation(op: NFSOperation): op is {
    type: 'add_export';
    config: NFSExportConfig;
};
/**
 * NAS type guards
 */
export declare function isNASVolumeOperation(op: NASOperation): op is {
    type: 'create_volume';
    config: NASVolumeConfig;
};
export declare function isNASSnapshotOperation(op: NASOperation): op is {
    type: 'create_snapshot';
    config: NASSnapshotConfig;
};
export declare function isNFSProtocolConfig(config: ProtocolConfig): config is NFSProtocolConfig;
export declare function isSMBProtocolConfig(config: ProtocolConfig): config is SMBProtocolConfig;
/**
 * Cluster type guards
 */
export declare function isKubernetesCluster(cluster: ClusterInfo): cluster is K8sClusterInfo;
export declare function isDockerSwarmCluster(cluster: ClusterInfo): cluster is SwarmInfo;
/**
 * Validate execution context
 */
export declare function validateExecutionContext(context: ExecutionContext): ValidationResult;
/**
 * Validate NFS mount configuration
 */
export declare function validateNFSMountConfig(config: NFSMountConfig): ValidationResult;
/**
 * Validate NFS export configuration
 */
export declare function validateNFSExportConfig(config: NFSExportConfig): ValidationResult;
/**
 * Validate NAS volume configuration
 */
export declare function validateNASVolumeConfig(config: NASVolumeConfig): ValidationResult;
/**
 * Validate firewall rule
 */
export declare function validateFirewallRule(rule: FirewallRule): ValidationResult;
/**
 * Validate Kubernetes deployment configuration
 */
export declare function validateK8sDeploymentName(name: string): boolean;
//# sourceMappingURL=infrastructure.d.ts.map