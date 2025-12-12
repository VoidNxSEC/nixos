/**
 * Wildcard Command System - Swiss Army Knife for Terminals
 *
 * Dynamic command generation based on context and problem type.
 * Agents can request commands like:
 * - "fix {error-type}"
 * - "debug {service}"
 * - "optimize {component}"
 *
 * And get executable, context-aware commands instantly.
 */
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);
export class WildcardCommandSystem {
    templates = new Map();
    executionHistory = [];
    constructor() {
        this.registerBuiltinTemplates();
    }
    /**
     * Register built-in command templates
     */
    registerBuiltinTemplates() {
        // NixOS rebuild fixes
        this.register('nix-fix-rebuild', {
            pattern: /^nix-fix\s+(rebuild|build)$/i,
            generator: () => [
                'sudo rm -rf /nix/var/nix/gcroots/auto/*',
                'nix-collect-garbage -d',
                'sudo nixos-rebuild switch --fast --max-jobs 2 --cores 4',
            ],
            description: 'Fix NixOS rebuild issues (cleanup + rebuild)',
            riskLevel: 'medium',
        });
        // Service debugging
        this.register('debug-service', {
            pattern: /^debug\s+(.+?)$/i,
            generator: (match) => {
                const service = match[1];
                return [
                    `systemctl status ${service}`,
                    `journalctl -u ${service} --no-pager -n 50`,
                    `systemctl cat ${service}`,
                ];
            },
            description: 'Debug systemd service (status + logs + config)',
            riskLevel: 'safe',
        });
        // Network troubleshooting
        this.register('net-diagnose', {
            pattern: /^net-diagnose\s*(.+?)?$/i,
            generator: (match) => {
                const target = match[1] || '';
                return [
                    'ip addr show',
                    'ip route show',
                    'resolvectl status',
                    target ? `ping -c 4 ${target}` : 'ping -c 4 8.8.8.8',
                    target ? `traceroute ${target}` : '',
                ].filter(Boolean);
            },
            description: 'Complete network diagnostics',
            riskLevel: 'safe',
        });
        // Disk space emergency
        this.register('disk-emergency', {
            pattern: /^disk-emergency$/i,
            generator: () => [
                'df -h',
                'du -sh /nix/store 2>/dev/null || echo "Checking store..."',
                'nix-collect-garbage -d',
                'sudo journalctl --vacuum-time=7d',
                'df -h',
            ],
            description: 'Emergency disk space cleanup',
            riskLevel: 'medium',
        });
        // Process kill patterns
        this.register('kill-pattern', {
            pattern: /^kill\s+(.+?)$/i,
            generator: (match) => {
                const pattern = match[1];
                return [
                    `pgrep -f "${pattern}" || echo "No processes found"`,
                    `pkill -9 -f "${pattern}"`,
                    `pgrep -f "${pattern}" || echo "Successfully killed"`,
                ];
            },
            description: 'Kill processes matching pattern',
            riskLevel: 'dangerous',
        });
        // Git operations
        this.register('git-fix', {
            pattern: /^git-fix\s+(conflict|merge|rebase)$/i,
            generator: (match) => {
                const issue = match[1].toLowerCase();
                if (issue === 'conflict') {
                    return [
                        'git status',
                        'git diff --name-only --diff-filter=U',
                        'echo "# Resolve conflicts in listed files"',
                    ];
                }
                else if (issue === 'merge') {
                    return [
                        'git merge --abort || echo "No merge in progress"',
                        'git status',
                    ];
                }
                else {
                    return [
                        'git rebase --abort || echo "No rebase in progress"',
                        'git status',
                    ];
                }
            },
            description: 'Fix git issues (conflicts, merge, rebase)',
            riskLevel: 'medium',
        });
        // Docker cleanup
        this.register('docker-cleanup', {
            pattern: /^docker-cleanup$/i,
            generator: () => [
                'docker ps -a',
                'docker system prune -af --volumes',
                'docker images',
            ],
            description: 'Complete Docker cleanup (containers, images, volumes)',
            riskLevel: 'dangerous',
        });
        // Temperature check
        this.register('temp-check', {
            pattern: /^temp-check$/i,
            generator: () => [
                'sensors 2>/dev/null || cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo "No temperature sensors"',
                'uptime',
            ],
            description: 'Check system temperature and load',
            riskLevel: 'safe',
        });
        // Port investigation
        this.register('port-check', {
            pattern: /^port-check\s+(\d+)$/i,
            generator: (match) => {
                const port = match[1];
                return [
                    `sudo lsof -i :${port}`,
                    `sudo netstat -tulpn | grep :${port}`,
                    `sudo ss -tulpn | grep :${port}`,
                ];
            },
            description: 'Check what is using a specific port',
            riskLevel: 'safe',
        });
        // Service restart patterns
        this.register('restart-service', {
            pattern: /^restart\s+(.+?)$/i,
            generator: (match) => {
                const service = match[1];
                return [
                    `sudo systemctl restart ${service}`,
                    `sudo systemctl status ${service}`,
                ];
            },
            description: 'Restart service and check status',
            riskLevel: 'medium',
        });
        // Log analysis
        this.register('analyze-logs', {
            pattern: /^analyze-logs\s+(.+?)\s*(\d+)?$/i,
            generator: (match) => {
                const service = match[1];
                const lines = match[2] || '100';
                return [
                    `journalctl -u ${service} --no-pager -n ${lines}`,
                    `journalctl -u ${service} --no-pager -p err -n 20`,
                ];
            },
            description: 'Analyze service logs (recent + errors)',
            riskLevel: 'safe',
        });
        // Nix build with safety
        this.register('safe-build', {
            pattern: /^safe-build\s+(.+?)$/i,
            generator: (match) => {
                const target = match[1];
                return [
                    'emergency-status || true',
                    `nix build ${target} --max-jobs 2 --cores 4 --keep-going`,
                    'emergency-status || true',
                ];
            },
            description: 'Safe Nix build with resource limits',
            riskLevel: 'medium',
        });
    }
    /**
     * Register new command template
     */
    register(name, template) {
        this.templates.set(name, template);
    }
    /**
     * Match command against all templates
     */
    matchTemplate(command) {
        for (const [name, template] of this.templates) {
            const match = command.match(template.pattern);
            if (match) {
                return { name, template, match };
            }
        }
        return null;
    }
    /**
     * Generate commands from wildcard pattern
     */
    generate(wildcardCommand, context = {}) {
        const matched = this.matchTemplate(wildcardCommand);
        if (!matched) {
            return null;
        }
        const { name, template, match } = matched;
        const commands = template.generator(match, context);
        return {
            commands,
            description: template.description,
            riskLevel: template.riskLevel,
        };
    }
    /**
     * Execute wildcard command
     */
    async execute(wildcardCommand, context = {}) {
        const generated = this.generate(wildcardCommand, context);
        if (!generated) {
            return {
                success: false,
                output: '',
                error: `No matching template for: ${wildcardCommand}`,
                commands: [],
                riskLevel: 'safe',
            };
        }
        const { commands, description, riskLevel } = generated;
        console.log(`[WildcardCmd] Executing: ${description} (${riskLevel})`);
        let output = '';
        let hasError = false;
        for (const cmd of commands) {
            if (!cmd)
                continue;
            try {
                console.log(`[WildcardCmd] Running: ${cmd}`);
                const result = await execAsync(cmd, {
                    timeout: 30000,
                    maxBuffer: 10 * 1024 * 1024, // 10MB
                });
                output += `$ ${cmd}\n${result.stdout}\n`;
                if (result.stderr) {
                    output += `STDERR: ${result.stderr}\n`;
                }
            }
            catch (error) {
                hasError = true;
                output += `$ ${cmd}\nERROR: ${error.message}\n`;
                console.error(`[WildcardCmd] Command failed: ${cmd}`, error.message);
            }
            output += '\n---\n\n';
        }
        // Record in history
        this.executionHistory.push({
            pattern: wildcardCommand,
            commands,
            success: !hasError,
            timestamp: Date.now(),
        });
        return {
            success: !hasError,
            output: output.trim(),
            error: hasError ? 'Some commands failed (see output)' : undefined,
            commands,
            riskLevel,
        };
    }
    /**
     * List all available wildcard commands
     */
    listCommands() {
        return Array.from(this.templates.entries()).map(([name, template]) => ({
            pattern: template.pattern.source,
            description: template.description,
            riskLevel: template.riskLevel,
        }));
    }
    /**
     * Get execution history
     */
    getHistory(limit = 10) {
        return this.executionHistory.slice(-limit);
    }
    /**
     * Learn from successful executions
     * (Track which commands solve which problems)
     */
    learnFromSuccess(problem, commands) {
        // TODO: Store in vector database for future reference
        console.log(`[WildcardCmd] Learned solution for: ${problem}`);
    }
}
// Export singleton instance
export const wildcardCommands = new WildcardCommandSystem();
//# sourceMappingURL=wildcard-commands.js.map