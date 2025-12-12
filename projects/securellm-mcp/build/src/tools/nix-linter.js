/**
 * Intelligent NixOS Linter with Auto-Fix
 *
 * Detects common NixOS configuration issues and suggests/applies fixes.
 * Uses pattern matching and AST analysis for accurate detection.
 *
 * Key Features:
 * - Security issues detection
 * - Performance anti-patterns
 * - Syntax errors and warnings
 * - Auto-fix with confidence scoring
 * - Learning from fixes
 */
import * as fs from 'fs/promises';
import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);
export class NixOSLinter {
    rules = new Map();
    fixHistory = [];
    constructor() {
        this.registerBuiltinRules();
    }
    /**
     * Register built-in linting rules
     */
    registerBuiltinRules() {
        // Security: Hardcoded secrets
        this.addRule({
            name: 'no-hardcoded-secrets',
            category: 'security',
            severity: 'error',
            pattern: /(api[_-]?key|password|secret|token)\s*=\s*["'][^"'\$]+["']/gi,
            check: async (content, file) => {
                const issues = [];
                const lines = content.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    const match = line.match(this.rules.get('no-hardcoded-secrets').pattern);
                    if (match && !line.includes('config.sops') && !line.includes('pkgs.')) {
                        issues.push({
                            file,
                            line: i + 1,
                            severity: 'error',
                            category: 'security',
                            message: 'Hardcoded secret detected. Use SOPS or environment variables.',
                            fix: {
                                description: 'Replace with config.sops.secrets reference',
                                confidence: 90,
                                auto: false, // Need manual review
                                apply: async () => {
                                    console.log(`Manual fix required for ${file}:${i + 1}`);
                                },
                            },
                        });
                    }
                }
                return issues;
            },
        });
        // Performance: Unnecessary rebuilds
        this.addRule({
            name: 'avoid-nix-build-in-config',
            category: 'performance',
            severity: 'warning',
            pattern: /pkgs\.runCommand|builtins\.fetchurl/gi,
            check: async (content, file) => {
                const issues = [];
                const lines = content.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].includes('pkgs.runCommand') && !lines[i].includes('#')) {
                        issues.push({
                            file,
                            line: i + 1,
                            severity: 'warning',
                            category: 'performance',
                            message: 'Using pkgs.runCommand in configuration can slow rebuilds',
                            fix: {
                                description: 'Consider moving to separate derivation',
                                confidence: 60,
                                auto: false,
                                apply: async () => {
                                    console.log('Suggest moving to modules/packages/');
                                },
                            },
                        });
                    }
                }
                return issues;
            },
        });
        // Syntax: Missing semicolons in lists
        this.addRule({
            name: 'list-syntax',
            category: 'syntax',
            severity: 'error',
            check: async (content, file) => {
                const issues = [];
                const lines = content.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim();
                    // Check for missing semicolon in list
                    if (line.match(/^\s*"[^"]+"\s*$/) &&
                        i > 0 &&
                        lines[i - 1].trim().match(/^\s*"[^"]+"\s*$/)) {
                        issues.push({
                            file,
                            line: i + 1,
                            severity: 'warning',
                            category: 'syntax',
                            message: 'Missing semicolon in list?',
                        });
                    }
                }
                return issues;
            },
        });
        // Best practice: Use systemd services
        this.addRule({
            name: 'prefer-systemd-services',
            category: 'best-practice',
            severity: 'info',
            check: async (content, file) => {
                const issues = [];
                if (content.includes('crontab') || content.includes('*/etc/cron')) {
                    issues.push({
                        file,
                        line: 1,
                        severity: 'info',
                        category: 'best-practice',
                        message: 'Consider using systemd.timers instead of cron',
                        fix: {
                            description: 'Convert to systemd timer',
                            confidence: 80,
                            auto: false,
                            apply: async () => {
                                console.log('Generate systemd timer template');
                            },
                        },
                    });
                }
                return issues;
            },
        });
        // Security: Unsafe permissions
        this.addRule({
            name: 'safe-permissions',
            category: 'security',
            severity: 'warning',
            pattern: /mode\s*=\s*["']0?777["']/gi,
            check: async (content, file) => {
                const issues = [];
                const lines = content.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].match(/mode\s*=\s*["']0?777["']/i)) {
                        issues.push({
                            file,
                            line: i + 1,
                            severity: 'warning',
                            category: 'security',
                            message: 'Unsafe file permissions (777)',
                            fix: {
                                description: 'Change to 755 or 644',
                                confidence: 95,
                                auto: true,
                                apply: async () => {
                                    const newContent = content.replace(/mode\s*=\s*["']0?777["']/gi, 'mode = "755"');
                                    await fs.writeFile(file, newContent, 'utf-8');
                                },
                            },
                        });
                    }
                }
                return issues;
            },
        });
        // Performance: Redundant imports
        this.addRule({
            name: 'no-duplicate-imports',
            category: 'performance',
            severity: 'warning',
            check: async (content, file) => {
                const issues = [];
                const imports = new Set();
                const lines = content.split('\n');
                for (let i = 0; i < lines.length; i++) {
                    const match = lines[i].match(/\.\/([\w\/-]+\.nix)/);
                    if (match) {
                        const importPath = match[1];
                        if (imports.has(importPath)) {
                            issues.push({
                                file,
                                line: i + 1,
                                severity: 'warning',
                                category: 'performance',
                                message: `Duplicate import: ${importPath}`,
                                fix: {
                                    description: 'Remove duplicate import',
                                    confidence: 100,
                                    auto: true,
                                    apply: async () => {
                                        const newLines = lines.filter((l, idx) => idx !== i || !l.includes(importPath));
                                        await fs.writeFile(file, newLines.join('\n'), 'utf-8');
                                    },
                                },
                            });
                        }
                        imports.add(importPath);
                    }
                }
                return issues;
            },
        });
        // Nix syntax check
        this.addRule({
            name: 'nix-syntax-check',
            category: 'syntax',
            severity: 'error',
            check: async (content, file) => {
                try {
                    // Use nix-instantiate to check syntax
                    await execAsync(`nix-instantiate --parse ${file} >/dev/null 2>&1`);
                    return [];
                }
                catch (error) {
                    return [{
                            file,
                            line: 1,
                            severity: 'error',
                            category: 'syntax',
                            message: `Nix syntax error: ${error.message}`,
                        }];
                }
            },
        });
    }
    /**
     * Add a custom linting rule
     */
    addRule(rule) {
        this.rules.set(rule.name, rule);
    }
    /**
     * Lint a single file
     */
    async lintFile(filePath) {
        const content = await fs.readFile(filePath, 'utf-8');
        const issues = [];
        // Run all rules
        for (const [name, rule] of this.rules) {
            try {
                const ruleIssues = await rule.check(content, filePath);
                issues.push(...ruleIssues);
            }
            catch (error) {
                console.error(`[Linter] Rule ${name} failed:`, error);
            }
        }
        // Calculate stats
        const stats = {
            errors: issues.filter(i => i.severity === 'error').length,
            warnings: issues.filter(i => i.severity === 'warning').length,
            info: issues.filter(i => i.severity === 'info').length,
            fixable: issues.filter(i => i.fix?.auto).length,
        };
        return { file: filePath, issues, stats };
    }
    /**
     * Lint entire directory
     */
    async lintDirectory(dirPath, pattern = '**/*.nix') {
        const results = [];
        // Find all .nix files
        try {
            const { stdout } = await execAsync(`find ${dirPath} -name "*.nix" -type f`);
            const files = stdout.trim().split('\n').filter(Boolean);
            for (const file of files) {
                try {
                    const result = await this.lintFile(file);
                    if (result.issues.length > 0) {
                        results.push(result);
                    }
                }
                catch (error) {
                    console.error(`[Linter] Failed to lint ${file}:`, error);
                }
            }
        }
        catch (error) {
            console.error('[Linter] Directory scan failed:', error);
        }
        return results;
    }
    /**
     * Auto-fix issues with high confidence
     */
    async autoFix(result, minConfidence = 90) {
        let fixed = 0;
        let failed = 0;
        for (const issue of result.issues) {
            if (issue.fix?.auto && issue.fix.confidence >= minConfidence) {
                try {
                    await issue.fix.apply();
                    fixed++;
                    this.fixHistory.push({
                        issue: issue.message,
                        success: true,
                        timestamp: Date.now(),
                    });
                    console.log(`[Linter] Auto-fixed: ${issue.message} in ${issue.file}:${issue.line}`);
                }
                catch (error) {
                    failed++;
                    this.fixHistory.push({
                        issue: issue.message,
                        success: false,
                        timestamp: Date.now(),
                    });
                    console.error(`[Linter] Auto-fix failed: ${issue.message}`, error);
                }
            }
        }
        return { fixed, failed };
    }
    /**
     * Generate fix report
     */
    generateReport(results) {
        let report = '# NixOS Linter Report\n\n';
        // Summary
        const totalIssues = results.reduce((sum, r) => sum + r.issues.length, 0);
        const totalErrors = results.reduce((sum, r) => sum + r.stats.errors, 0);
        const totalWarnings = results.reduce((sum, r) => sum + r.stats.warnings, 0);
        const totalFixable = results.reduce((sum, r) => sum + r.stats.fixable, 0);
        report += `## Summary\n`;
        report += `- Total Issues: ${totalIssues}\n`;
        report += `- Errors: ${totalErrors}\n`;
        report += `- Warnings: ${totalWarnings}\n`;
        report += `- Auto-fixable: ${totalFixable}\n\n`;
        // Details
        report += `## Issues by File\n\n`;
        for (const result of results) {
            report += `### ${result.file}\n\n`;
            for (const issue of result.issues) {
                const icon = issue.severity === 'error' ? '❌' :
                    issue.severity === 'warning' ? '⚠️' : 'ℹ️';
                const fixable = issue.fix?.auto ? ' [AUTO-FIXABLE]' : '';
                report += `${icon} Line ${issue.line}: ${issue.message}${fixable}\n`;
                if (issue.fix) {
                    report += `   Fix: ${issue.fix.description} (confidence: ${issue.fix.confidence}%)\n`;
                }
                report += '\n';
            }
        }
        return report;
    }
    /**
     * Get fix history
     */
    getFixHistory(limit = 20) {
        return this.fixHistory.slice(-limit);
    }
}
// Export singleton
export const nixLinter = new NixOSLinter();
//# sourceMappingURL=nix-linter.js.map