/**
 * System Log Analyzer Tool
 * Analyze systemd journal logs with intelligent filtering
 */
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);
export class SystemLogAnalyzerTool {
    async execute(args) {
        try {
            const service = args.service;
            const since = args.since || '1 hour ago';
            const until = args.until;
            const level = args.level;
            const lines = args.lines || 100;
            const pattern = args.pattern;
            let cmd = `journalctl --no-pager -n ${lines}`;
            if (service)
                cmd += ` -u ${service}`;
            if (since)
                cmd += ` --since "${since}"`;
            if (until)
                cmd += ` --until "${until}"`;
            if (level)
                cmd += ` -p ${level}`;
            if (pattern)
                cmd += ` | grep -i "${pattern}"`;
            const { stdout, stderr } = await execAsync(cmd);
            // Parse log entries
            const logEntries = stdout.split('\n').filter(l => l.trim()).map(line => {
                const match = line.match(/^(\w+\s+\d+\s+\d+:\d+:\d+)\s+(\S+)\s+(.+)$/);
                if (match) {
                    return {
                        timestamp: match[1],
                        host: match[2],
                        message: match[3],
                    };
                }
                return { raw: line };
            });
            // Analyze patterns
            const errorCount = logEntries.filter(e => e.message?.toLowerCase().includes('error') ||
                e.message?.toLowerCase().includes('failed')).length;
            const warningCount = logEntries.filter(e => e.message?.toLowerCase().includes('warning') ||
                e.message?.toLowerCase().includes('warn')).length;
            return {
                success: true,
                data: {
                    entries: logEntries,
                    total_entries: logEntries.length,
                    error_count: errorCount,
                    warning_count: warningCount,
                    service,
                    time_range: { since, until },
                },
                warnings: errorCount > 10 ? [`High error count detected: ${errorCount} errors`] : undefined,
                timestamp: new Date().toISOString(),
            };
        }
        catch (error) {
            return {
                success: false,
                error: `Log analysis failed: ${error.message}`,
                timestamp: new Date().toISOString(),
            };
        }
    }
}
export const logAnalyzerSchema = {
    name: "system_log_analyzer",
    description: "Analyze system logs with filtering by service, time, level, and pattern",
    inputSchema: {
        type: "object",
        properties: {
            service: { type: "string", description: "Service name to filter" },
            since: { type: "string", description: "Start time (e.g., '1 hour ago', '2024-01-01')" },
            until: { type: "string", description: "End time" },
            level: { type: "string", enum: ["error", "warning", "info", "debug"] },
            lines: { type: "number", description: "Max lines to return (default: 100)" },
            pattern: { type: "string", description: "Grep pattern to filter logs" },
        },
    },
};
//# sourceMappingURL=log-analyzer.js.map