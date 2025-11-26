/**
 * System Resource Monitor Tool
 * Monitor system resources over time
 */
// @ts-ignore
import * as si from 'systeminformation';
export class SystemResourceMonitorTool {
    async execute(args) {
        const duration = args.duration_seconds || 60;
        const interval = args.interval_seconds || 5;
        const resources = args.resources || ['cpu', 'memory', 'disk', 'network'];
        try {
            const samples = [];
            const iterations = Math.min(duration / interval, 12); // Max 12 samples
            for (let i = 0; i < iterations; i++) {
                const sample = { timestamp: new Date().toISOString() };
                if (resources.includes('cpu')) {
                    const cpu = await si.currentLoad();
                    sample.cpu = Math.round(cpu.currentLoad);
                }
                if (resources.includes('memory')) {
                    const mem = await si.mem();
                    sample.memory = Math.round((mem.used / mem.total) * 100);
                }
                if (resources.includes('disk')) {
                    const disk = await si.fsSize();
                    sample.disk = disk[0] ? Math.round(disk[0].use) : 0;
                }
                if (resources.includes('network')) {
                    const net = await si.networkStats();
                    sample.network = { rx_sec: net[0]?.rx_sec || 0, tx_sec: net[0]?.tx_sec || 0 };
                }
                samples.push(sample);
                if (i < iterations - 1) {
                    await new Promise(resolve => setTimeout(resolve, interval * 1000));
                }
            }
            return {
                success: true,
                data: {
                    samples,
                    duration_seconds: duration,
                    interval_seconds: interval,
                    resources_monitored: resources,
                },
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Resource monitoring failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
export const resourceMonitorSchema = {
    name: "system_resource_monitor",
    description: "Monitor system resources over time (CPU, memory, disk, network)",
    inputSchema: {
        type: "object",
        properties: {
            duration_seconds: { type: "number", description: "Monitoring duration (default: 60)" },
            interval_seconds: { type: "number", description: "Sample interval (default: 5)" },
            resources: {
                type: "array",
                items: { type: "string", enum: ["cpu", "memory", "disk", "network"] },
                description: "Resources to monitor",
            },
        },
    },
};
//# sourceMappingURL=resource-monitor.js.map