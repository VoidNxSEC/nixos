/**
 * System Health Check Tool
 * Comprehensive system health monitoring
 */
import { exec } from 'child_process';
import { promisify } from 'util';
// @ts-ignore - systeminformation doesn't have type definitions
import * as si from 'systeminformation';
const execAsync = promisify(exec);
export class SystemHealthCheckTool {
    projectRoot;
    constructor(projectRoot) {
        this.projectRoot = projectRoot;
    }
    async execute(args) {
        const startTime = Date.now();
        const detailed = args.detailed ?? true;
        const components = args.components ?? ['cpu', 'memory', 'disk', 'network', 'services'];
        try {
            const healthData = {
                system: {
                    hostname: (await si.osInfo()).hostname,
                    platform: (await si.osInfo()).platform,
                    uptime: (await si.time()).uptime,
                }
            };
            // CPU Check
            if (components.includes('cpu')) {
                const cpuData = await si.currentLoad();
                const cpuInfo = await si.cpu();
                healthData.cpu = {
                    usage: Math.round(cpuData.currentLoad),
                    load: [cpuData.currentLoad, cpuData.avgLoad],
                    cores: cpuInfo.physicalCores,
                    model: cpuInfo.brand,
                    speed: cpuInfo.speed,
                    temperature: detailed ? await this.getCPUTemp() : undefined,
                };
            }
            // Memory Check
            if (components.includes('memory')) {
                const memData = await si.mem();
                healthData.memory = {
                    used: Math.round(memData.used / (1024 ** 3) * 100) / 100, // GB
                    total: Math.round(memData.total / (1024 ** 3) * 100) / 100, // GB
                    percentage: Math.round((memData.used / memData.total) * 100),
                    available: Math.round(memData.available / (1024 ** 3) * 100) / 100, // GB
                    swap: {
                        used: Math.round(memData.swapused / (1024 ** 3) * 100) / 100,
                        total: Math.round(memData.swaptotal / (1024 ** 3) * 100) / 100,
                    }
                };
            }
            // Disk Check
            if (components.includes('disk')) {
                const diskData = await si.fsSize();
                healthData.disk = diskData.map((d) => ({
                    mount: d.mount,
                    filesystem: d.fs,
                    used: Math.round(d.used / (1024 ** 3) * 100) / 100, // GB
                    total: Math.round(d.size / (1024 ** 3) * 100) / 100, // GB
                    percentage: Math.round(d.use),
                    available: Math.round((d.size - d.used) / (1024 ** 3) * 100) / 100, // GB
                }));
            }
            // Network Check
            if (components.includes('network')) {
                const netData = await si.networkStats();
                healthData.network = {
                    interfaces: netData.map((n) => ({
                        name: n.iface,
                        rx_bytes: n.rx_bytes,
                        tx_bytes: n.tx_bytes,
                        rx_sec: n.rx_sec,
                        tx_sec: n.tx_sec,
                    }))
                };
            }
            // Services Check (NixOS systemd services)
            if (components.includes('services')) {
                healthData.services = await this.checkCriticalServices();
            }
            // Health Assessment
            const warnings = [];
            if (healthData.cpu?.usage > 90) {
                warnings.push(`High CPU usage: ${healthData.cpu.usage}%`);
            }
            if (healthData.memory?.percentage > 90) {
                warnings.push(`High memory usage: ${healthData.memory.percentage}%`);
            }
            healthData.disk?.forEach((d) => {
                if (d.percentage > 90) {
                    warnings.push(`Disk ${d.mount} almost full: ${d.percentage}%`);
                }
            });
            const duration = Date.now() - startTime;
            return {
                success: true,
                data: healthData,
                warnings: warnings.length > 0 ? warnings : undefined,
                timestamp: new Date().toISOString(),
                metadata: {
                    duration_ms: duration,
                    components_checked: components.length,
                }
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Health check failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
    async getCPUTemp() {
        try {
            const tempData = await si.cpuTemperature();
            return tempData.main;
        }
        catch {
            return undefined;
        }
    }
    async checkCriticalServices() {
        const criticalServices = [
            'sshd',
            'systemd-journald',
            'systemd-logind',
            'dbus',
            'NetworkManager',
        ];
        const services = [];
        for (const service of criticalServices) {
            try {
                const { stdout } = await execAsync(`systemctl is-active ${service}`);
                const status = stdout.trim();
                let uptime;
                if (status === 'active') {
                    try {
                        const { stdout: uptimeOut } = await execAsync(`systemctl show ${service} --property=ActiveEnterTimestamp --value`);
                        const startTime = new Date(uptimeOut.trim()).getTime();
                        uptime = Math.floor((Date.now() - startTime) / 1000);
                    }
                    catch {
                        // Ignore uptime errors
                    }
                }
                services.push({ name: service, status, uptime });
            }
            catch (error) {
                services.push({ name: service, status: 'inactive' });
            }
        }
        return services;
    }
}
export const healthCheckSchema = {
    name: "system_health_check",
    description: "Comprehensive system health check including CPU, memory, disk, network, and services",
    inputSchema: {
        type: "object",
        properties: {
            detailed: {
                type: "boolean",
                description: "Include detailed metrics (default: true)",
            },
            components: {
                type: "array",
                items: {
                    type: "string",
                    enum: ["cpu", "memory", "disk", "network", "services"],
                },
                description: "Components to check (default: all)",
            },
        },
    },
};
//# sourceMappingURL=health-check.js.map