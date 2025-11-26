/**
 * Emergency Framework Tools
 *
 * MCP tools for emergency response and system recovery
 */
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);
export const emergencyTools = [
    {
        name: "emergency_status",
        description: "Get comprehensive emergency system status (CPU, memory, SWAP, thermal, load)",
        // Core tool - always loaded
        inputSchema: {
            type: "object",
            properties: {},
        },
    },
    {
        name: "emergency_abort",
        description: "Emergency abort: Kill all NIX builds and heavy processes",
        defer_loading: true,
        inputSchema: {
            type: "object",
            properties: {
                force: {
                    type: "boolean",
                    description: "Force kill without confirmation (default: false)",
                    default: false,
                },
            },
        },
    },
    {
        name: "emergency_cooldown",
        description: "Force CPU cooldown (powersave governor, disable turbo)",
        defer_loading: true,
        inputSchema: {
            type: "object",
            properties: {},
        },
    },
    {
        name: "emergency_nuke",
        description: "Nuclear option: Kill ALL heavy processes (compilers, indexers, etc)",
        defer_loading: true,
        inputSchema: {
            type: "object",
            properties: {
                confirm: {
                    type: "boolean",
                    description: "Must be true to execute (safety check)",
                    default: false,
                },
            },
        },
    },
    {
        name: "emergency_swap",
        description: "Emergency SWAP cleanup: Free critical SWAP memory",
        defer_loading: true,
        inputSchema: {
            type: "object",
            properties: {},
        },
    },
    {
        name: "system_health_check",
        description: "Comprehensive system health check (thermal, CPU, memory, disk, SWAP)",
        // Core tool - always loaded
        inputSchema: {
            type: "object",
            properties: {
                detailed: {
                    type: "boolean",
                    description: "Include detailed diagnostics (default: false)",
                    default: false,
                },
            },
        },
    },
    {
        name: "safe_rebuild_check",
        description: "Check if it's safe to run nixos-rebuild (temperature, load, memory)",
        // Core tool - always loaded
        inputSchema: {
            type: "object",
            properties: {},
        },
    },
];
export async function handleEmergencyStatus() {
    try {
        const { stdout } = await execAsync('bash /etc/nixos/scripts/nix-emergency.sh status');
        // Parse output to extract metrics
        const result = {
            status: 'ok',
            timestamp: new Date().toISOString(),
            metrics: {
                cpu: { load: 0, cores: 0, thermal: 0, governor: 'unknown' },
                memory: { used_gb: 0, available_gb: 0, percentage: 0 },
                swap: { used_gb: 0, total_gb: 0, percentage: 0 },
                disk: { used_percentage: 0, available_gb: 0 },
            },
            alerts: [],
            recommendations: [],
        };
        // Parse CPU metrics
        const loadMatch = stdout.match(/Load Average:\s+(\d+\.?\d*)/);
        if (loadMatch)
            result.metrics.cpu.load = parseFloat(loadMatch[1]);
        const coresMatch = stdout.match(/CPU Cores:\s+(\d+)/);
        if (coresMatch)
            result.metrics.cpu.cores = parseInt(coresMatch[1]);
        const tempMatch = stdout.match(/CPU Temperature:\s+(\d+)°C/);
        if (tempMatch)
            result.metrics.cpu.thermal = parseInt(tempMatch[1]);
        const govMatch = stdout.match(/Governor:\s+(\w+)/);
        if (govMatch)
            result.metrics.cpu.governor = govMatch[1];
        // Parse memory
        const memMatch = stdout.match(/Memory:\s+(\d+\.?\d*)GB\s+used.*?(\d+\.?\d*)GB\s+available/);
        if (memMatch) {
            result.metrics.memory.used_gb = parseFloat(memMatch[1]);
            result.metrics.memory.available_gb = parseFloat(memMatch[2]);
            const total = result.metrics.memory.used_gb + result.metrics.memory.available_gb;
            result.metrics.memory.percentage = Math.round((result.metrics.memory.used_gb / total) * 100);
        }
        // Parse SWAP
        const swapMatch = stdout.match(/SWAP:\s+(\d+\.?\d*)GB.*?(\d+\.?\d*)GB/);
        if (swapMatch) {
            result.metrics.swap.used_gb = parseFloat(swapMatch[1]);
            result.metrics.swap.total_gb = parseFloat(swapMatch[2]);
            result.metrics.swap.percentage = Math.round((result.metrics.swap.used_gb / result.metrics.swap.total_gb) * 100);
        }
        // Determine status
        if (result.metrics.cpu.thermal > 90 || result.metrics.swap.percentage > 90) {
            result.status = 'emergency';
            result.alerts.push('EMERGENCY: Critical system conditions detected!');
        }
        else if (result.metrics.cpu.thermal > 80 || result.metrics.swap.percentage > 70) {
            result.status = 'critical';
            result.alerts.push('CRITICAL: System under severe stress');
        }
        else if (result.metrics.cpu.thermal > 75 || result.metrics.swap.percentage > 50) {
            result.status = 'warning';
            result.alerts.push('WARNING: System under moderate stress');
        }
        // Add recommendations
        if (result.metrics.cpu.thermal > 75) {
            result.recommendations.push('Consider running: emergency_cooldown');
        }
        if (result.metrics.swap.percentage > 50) {
            result.recommendations.push('Consider running: emergency_swap');
        }
        if (result.metrics.cpu.load > 20) {
            result.recommendations.push('Consider running: emergency_abort to kill heavy builds');
        }
        return result;
    }
    catch (error) {
        throw new Error(`Failed to get emergency status: ${error.message}`);
    }
}
export async function handleEmergencyAbort(force = false) {
    try {
        const { stdout, stderr } = await execAsync('bash /etc/nixos/scripts/nix-emergency.sh abort');
        // Parse output to count killed processes
        const killCount = (stdout.match(/killed/gi) || []).length;
        return {
            success: true,
            processes_killed: killCount,
            message: `Emergency abort complete. Killed ${killCount} processes. ${stdout}`,
        };
    }
    catch (error) {
        return {
            success: false,
            processes_killed: 0,
            message: `Emergency abort failed: ${error.message}`,
        };
    }
}
export async function handleEmergencyCooldown() {
    try {
        const { stdout } = await execAsync('bash /etc/nixos/scripts/nix-emergency.sh cooldown');
        return {
            success: true,
            message: stdout.trim() || 'CPU cooldown activated (powersave governor, turbo disabled)',
        };
    }
    catch (error) {
        return {
            success: false,
            message: `Cooldown failed: ${error.message}`,
        };
    }
}
export async function handleEmergencyNuke(confirm) {
    if (!confirm) {
        return {
            success: false,
            processes_killed: 0,
            message: 'Nuke operation requires confirm=true (safety check)',
        };
    }
    try {
        const { stdout } = await execAsync('bash /etc/nixos/scripts/nix-emergency.sh nuke');
        const killCount = (stdout.match(/killed/gi) || []).length;
        return {
            success: true,
            processes_killed: killCount,
            message: `Nuclear option executed. Killed ${killCount} processes.`,
        };
    }
    catch (error) {
        return {
            success: false,
            processes_killed: 0,
            message: `Nuke operation failed: ${error.message}`,
        };
    }
}
export async function handleEmergencySwap() {
    try {
        const { stdout } = await execAsync('bash /etc/nixos/scripts/nix-emergency.sh swap-emergency');
        // Try to extract freed memory from output
        const freedMatch = stdout.match(/freed\s+(\d+)\s*MB/i);
        const freedMb = freedMatch ? parseInt(freedMatch[1]) : 0;
        return {
            success: true,
            freed_mb: freedMb,
            message: stdout.trim() || 'SWAP emergency cleanup complete',
        };
    }
    catch (error) {
        return {
            success: false,
            freed_mb: 0,
            message: `SWAP cleanup failed: ${error.message}`,
        };
    }
}
export async function handleSystemHealthCheck(detailed = false) {
    try {
        // Use emergency status + additional checks
        const status = await handleEmergencyStatus();
        const checks = [];
        let score = 100;
        // Thermal check
        if (status.metrics.cpu.thermal < 75) {
            checks.push({ category: 'Thermal', status: 'pass', message: `CPU: ${status.metrics.cpu.thermal}°C (healthy)` });
        }
        else if (status.metrics.cpu.thermal < 85) {
            checks.push({ category: 'Thermal', status: 'warning', message: `CPU: ${status.metrics.cpu.thermal}°C (warm)` });
            score -= 20;
        }
        else {
            checks.push({ category: 'Thermal', status: 'fail', message: `CPU: ${status.metrics.cpu.thermal}°C (critical!)` });
            score -= 40;
        }
        // Memory check
        if (status.metrics.memory.percentage < 80) {
            checks.push({ category: 'Memory', status: 'pass', message: `${status.metrics.memory.percentage}% used (healthy)` });
        }
        else if (status.metrics.memory.percentage < 90) {
            checks.push({ category: 'Memory', status: 'warning', message: `${status.metrics.memory.percentage}% used (high)` });
            score -= 15;
        }
        else {
            checks.push({ category: 'Memory', status: 'fail', message: `${status.metrics.memory.percentage}% used (critical!)` });
            score -= 30;
        }
        // SWAP check
        if (status.metrics.swap.percentage < 50) {
            checks.push({ category: 'SWAP', status: 'pass', message: `${status.metrics.swap.percentage}% used (healthy)` });
        }
        else if (status.metrics.swap.percentage < 80) {
            checks.push({ category: 'SWAP', status: 'warning', message: `${status.metrics.swap.percentage}% used (high)` });
            score -= 15;
        }
        else {
            checks.push({ category: 'SWAP', status: 'fail', message: `${status.metrics.swap.percentage}% used (critical!)` });
            score -= 30;
        }
        // Load check
        const loadPerCore = status.metrics.cpu.load / status.metrics.cpu.cores;
        if (loadPerCore < 2) {
            checks.push({ category: 'CPU Load', status: 'pass', message: `${status.metrics.cpu.load} (${loadPerCore.toFixed(1)}/core - healthy)` });
        }
        else if (loadPerCore < 4) {
            checks.push({ category: 'CPU Load', status: 'warning', message: `${status.metrics.cpu.load} (${loadPerCore.toFixed(1)}/core - high)` });
            score -= 10;
        }
        else {
            checks.push({ category: 'CPU Load', status: 'fail', message: `${status.metrics.cpu.load} (${loadPerCore.toFixed(1)}/core - critical!)` });
            score -= 20;
        }
        // Determine verdict
        let verdict;
        if (score >= 80)
            verdict = 'HEALTHY';
        else if (score >= 60)
            verdict = 'WARNING';
        else
            verdict = 'CRITICAL';
        return {
            verdict,
            score: Math.max(0, score),
            checks,
            timestamp: new Date().toISOString(),
        };
    }
    catch (error) {
        throw new Error(`Health check failed: ${error.message}`);
    }
}
export async function handleSafeRebuildCheck() {
    try {
        const status = await handleEmergencyStatus();
        const reasons = [];
        let safe = true;
        // Temperature check (< 75°C)
        if (status.metrics.cpu.thermal >= 75) {
            safe = false;
            reasons.push(`Temperature too high: ${status.metrics.cpu.thermal}°C (limit: 75°C)`);
        }
        // Load check (< 20)
        if (status.metrics.cpu.load >= 20) {
            safe = false;
            reasons.push(`Load too high: ${status.metrics.cpu.load} (limit: 20)`);
        }
        // Memory check (< 90%)
        if (status.metrics.memory.percentage >= 90) {
            safe = false;
            reasons.push(`Memory too high: ${status.metrics.memory.percentage}% (limit: 90%)`);
        }
        // SWAP check (< 70%)
        if (status.metrics.swap.percentage >= 70) {
            safe = false;
            reasons.push(`SWAP too high: ${status.metrics.swap.percentage}% (limit: 70%)`);
        }
        return {
            safe,
            reason: safe ? 'All checks passed - safe to rebuild' : reasons.join('; '),
            metrics: status.metrics,
        };
    }
    catch (error) {
        throw new Error(`Safe rebuild check failed: ${error.message}`);
    }
}
//# sourceMappingURL=index.js.map