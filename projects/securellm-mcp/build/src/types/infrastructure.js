/**
 * Infrastructure Types Specification
 * Complete type definitions for NFS, NAS, Cluster, and Server management tools.
 *
 * This follows the same pattern as ssh-advanced.ts for consistency.
 */
// ============================================================================
// TYPE GUARDS
// ============================================================================
/**
 * Execution context type guards
 */
export function isLocalExecution(context) {
    return context.mode === 'local' || context.target === undefined;
}
export function isRemoteExecution(context) {
    return context.mode === 'remote' && context.target !== undefined;
}
/**
 * NFS type guards
 */
export function isNFSMountOperation(op) {
    return op.type === 'mount';
}
export function isNFSExportOperation(op) {
    return op.type === 'add_export';
}
/**
 * NAS type guards
 */
export function isNASVolumeOperation(op) {
    return op.type === 'create_volume';
}
export function isNASSnapshotOperation(op) {
    return op.type === 'create_snapshot';
}
export function isNFSProtocolConfig(config) {
    return config.type === 'nfs';
}
export function isSMBProtocolConfig(config) {
    return config.type === 'smb';
}
/**
 * Cluster type guards
 */
export function isKubernetesCluster(cluster) {
    return cluster.type === 'kubernetes';
}
export function isDockerSwarmCluster(cluster) {
    return cluster.type === 'docker_swarm';
}
// ============================================================================
// VALIDATION FUNCTIONS
// ============================================================================
/**
 * Validate execution context
 */
export function validateExecutionContext(context) {
    const errors = [];
    const warnings = [];
    if (context.mode === 'remote' && !context.target) {
        errors.push('Remote execution requires target hostname');
    }
    if (context.mode === 'remote' && !context.ssh_connection_id) {
        warnings.push('No SSH connection ID specified for remote execution');
    }
    if (context.sudo_required && context.user === 'root') {
        warnings.push('Sudo requested but already running as root');
    }
    return { valid: errors.length === 0, errors, warnings };
}
/**
 * Validate NFS mount configuration
 */
export function validateNFSMountConfig(config) {
    const errors = [];
    const warnings = [];
    // Validate source format (server:/path)
    if (!config.source.includes(':')) {
        errors.push('Invalid NFS source format. Expected: server:/export/path');
    }
    // Validate target path
    if (!config.target.startsWith('/')) {
        errors.push('Mount target must be absolute path');
    }
    // Check conflicting options
    if (config.options?.hard && config.options?.soft) {
        errors.push('Cannot specify both hard and soft mount options');
    }
    if (config.options?.sync && config.options?.async) {
        errors.push('Cannot specify both sync and async mount options');
    }
    return { valid: errors.length === 0, errors, warnings };
}
/**
 * Validate NFS export configuration
 */
export function validateNFSExportConfig(config) {
    const errors = [];
    const warnings = [];
    // Validate export path
    if (!config.path.startsWith('/')) {
        errors.push('Export path must be absolute');
    }
    // Validate clients
    if (config.clients.length === 0) {
        errors.push('At least one client must be specified');
    }
    // Check conflicting options
    if (config.options.rw && config.options.ro) {
        errors.push('Cannot specify both rw and ro options');
    }
    if (config.options.sync && config.options.async) {
        errors.push('Cannot specify both sync and async options');
    }
    return { valid: errors.length === 0, errors, warnings };
}
/**
 * Validate NAS volume configuration
 */
export function validateNASVolumeConfig(config) {
    const errors = [];
    const warnings = [];
    // Validate volume name
    if (!/^[a-zA-Z0-9_-]+$/.test(config.name)) {
        errors.push('Volume name must contain only alphanumeric characters, hyphens, and underscores');
    }
    // Validate size
    if (config.size_gb <= 0) {
        errors.push('Volume size must be positive');
    }
    if (config.size_gb > 10000) {
        warnings.push('Very large volume size specified (>10TB)');
    }
    // Validate encryption
    if (config.encryption && !config.encryption_key) {
        warnings.push('Encryption enabled but no key provided - will use default key');
    }
    return { valid: errors.length === 0, errors, warnings };
}
/**
 * Validate firewall rule
 */
export function validateFirewallRule(rule) {
    const errors = [];
    const warnings = [];
    // Validate port
    if (rule.port) {
        if (typeof rule.port === 'number') {
            if (rule.port < 1 || rule.port > 65535) {
                errors.push('Port must be between 1 and 65535');
            }
        }
        else {
            // Port range validation
            const parts = rule.port.split('-');
            if (parts.length !== 2) {
                errors.push('Invalid port range format. Expected: start-end');
            }
            else {
                const start = parseInt(parts[0]);
                const end = parseInt(parts[1]);
                if (isNaN(start) || isNaN(end) || start < 1 || end > 65535 || start >= end) {
                    errors.push('Invalid port range');
                }
            }
        }
    }
    // Validate CIDR if specified
    if (rule.source && rule.source.includes('/')) {
        const [, mask] = rule.source.split('/');
        const maskNum = parseInt(mask);
        if (maskNum < 0 || maskNum > 32) {
            errors.push('Invalid CIDR mask');
        }
    }
    return { valid: errors.length === 0, errors, warnings };
}
/**
 * Validate Kubernetes deployment configuration
 */
export function validateK8sDeploymentName(name) {
    return /^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/.test(name);
}
//# sourceMappingURL=infrastructure.js.map