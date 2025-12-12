/**
 * SSH Jump Host Manager - Multi-Hop Connection Management
 * Manages SSH connections through multiple bastions/jump hosts with intelligent routing
 */
import { SSHConnectionManager } from './connection-manager.js';
import type { JumpChainConfig, JumpHostConfig, JumpChainResult, JumpChainStatus, ValidationResult } from '../../types/ssh-advanced.js';
/**
 * Jump Host Manager Class
 * Handles multi-hop SSH connections through bastion servers
 */
export declare class JumpHostManager {
    private chains;
    private connectionManager;
    private pathCache;
    constructor(connectionManager: SSHConnectionManager);
    /**
     * Main method: Connect through jump hosts to target
     */
    connectThroughJumps(config: JumpChainConfig): Promise<JumpChainResult>;
    /**
     * Strategy: Sequential - Connect through jumps in order
     */
    private connectSequential;
    /**
     * Strategy: Optimal - Find best path based on probing
     */
    private connectOptimal;
    /**
     * Strategy: Failover - Try alternative paths on failure
     */
    private connectWithFailover;
    /**
     * Probe a single jump host to measure latency and availability
     */
    private probeJump;
    /**
     * Connect to target through established jump path
     */
    private connectThroughPath;
    /**
     * Cache successful path for reuse
     */
    private cachePath;
    /**
     * Get cached path if available and not expired
     */
    private getCachedPath;
    /**
     * Calculate total latency from path hops
     */
    private calculateTotalLatency;
    /**
     * Generate unique chain ID
     */
    private generateChainId;
    /**
     * Get jump chain status
     */
    getJumpChainStatus(chainId: string): Promise<JumpChainStatus | null>;
    /**
     * Validate jump chain configuration
     */
    validateJumpChain(jumps: readonly JumpHostConfig[]): Promise<ValidationResult>;
    /**
     * Close jump chain and cleanup connections
     */
    closeJumpChain(chainId: string): Promise<void>;
    /**
     * List all active jump chains
     */
    listJumpChains(): JumpChainStatus[];
    /**
     * Clear path cache
     */
    clearPathCache(): void;
    /**
     * Cleanup method for graceful shutdown
     */
    cleanup(): Promise<void>;
}
/**
 * MCP Tool Schema for SSH Jump Host
 */
export declare const sshJumpHostSchema: {
    name: string;
    description: string;
    inputSchema: {
        type: string;
        properties: {
            target: {
                type: string;
                description: string;
                properties: {
                    host: {
                        type: string;
                        description: string;
                    };
                    port: {
                        type: string;
                        description: string;
                    };
                    username: {
                        type: string;
                        description: string;
                    };
                    auth_method: {
                        type: string;
                        enum: string[];
                    };
                    key_path: {
                        type: string;
                        description: string;
                    };
                    password: {
                        type: string;
                        description: string;
                    };
                };
                required: string[];
            };
            jumps: {
                type: string;
                description: string;
                items: {
                    type: string;
                    properties: {
                        host: {
                            type: string;
                            description: string;
                        };
                        port: {
                            type: string;
                            description: string;
                        };
                        username: {
                            type: string;
                            description: string;
                        };
                        auth_method: {
                            type: string;
                            enum: string[];
                        };
                        key_path: {
                            type: string;
                            description: string;
                        };
                        password: {
                            type: string;
                            description: string;
                        };
                        forward_agent: {
                            type: string;
                            description: string;
                        };
                        max_latency_ms: {
                            type: string;
                            description: string;
                        };
                        priority: {
                            type: string;
                            description: string;
                        };
                    };
                    required: string[];
                };
            };
            strategy: {
                type: string;
                enum: string[];
                description: string;
            };
            max_total_latency_ms: {
                type: string;
                description: string;
            };
            timeout_per_hop_ms: {
                type: string;
                description: string;
            };
            parallel_probe: {
                type: string;
                description: string;
            };
            cache_successful_path: {
                type: string;
                description: string;
            };
            cache_duration_minutes: {
                type: string;
                description: string;
            };
        };
        required: string[];
    };
};
//# sourceMappingURL=jump-host-manager.d.ts.map