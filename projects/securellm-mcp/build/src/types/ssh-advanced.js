/**
 * SSH Advanced Types Specification
 * Advanced type definitions for SSH tools with tunneling, port forwarding,
 * jump hosts, session management, MFA, and connection pooling.
 */
// ===== TYPE GUARDS & VALIDATORS =====
/**
 * Type guard for local tunnel configuration
 */
export function isLocalTunnelConfig(config) {
    return config.type === 'local';
}
/**
 * Type guard for remote tunnel configuration
 */
export function isRemoteTunnelConfig(config) {
    return config.type === 'remote';
}
/**
 * Type guard for dynamic tunnel configuration
 */
export function isDynamicTunnelConfig(config) {
    return config.type === 'dynamic';
}
//# sourceMappingURL=ssh-advanced.js.map