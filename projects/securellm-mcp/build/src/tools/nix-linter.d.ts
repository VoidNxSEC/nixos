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
interface LintIssue {
    file: string;
    line: number;
    column?: number;
    severity: 'error' | 'warning' | 'info';
    category: string;
    message: string;
    fix?: {
        description: string;
        confidence: number;
        auto: boolean;
        apply: () => Promise<void>;
    };
}
interface LintResult {
    file: string;
    issues: LintIssue[];
    stats: {
        errors: number;
        warnings: number;
        info: number;
        fixable: number;
    };
}
export declare class NixOSLinter {
    private rules;
    private fixHistory;
    constructor();
    /**
     * Register built-in linting rules
     */
    private registerBuiltinRules;
    /**
     * Add a custom linting rule
     */
    addRule(rule: LintRule): void;
    /**
     * Lint a single file
     */
    lintFile(filePath: string): Promise<LintResult>;
    /**
     * Lint entire directory
     */
    lintDirectory(dirPath: string, pattern?: string): Promise<LintResult[]>;
    /**
     * Auto-fix issues with high confidence
     */
    autoFix(result: LintResult, minConfidence?: number): Promise<{
        fixed: number;
        failed: number;
    }>;
    /**
     * Generate fix report
     */
    generateReport(results: LintResult[]): string;
    /**
     * Get fix history
     */
    getFixHistory(limit?: number): typeof this.fixHistory;
}
interface LintRule {
    name: string;
    category: string;
    severity: 'error' | 'warning' | 'info';
    pattern?: RegExp;
    check: (content: string, file: string) => Promise<LintIssue[]>;
}
export declare const nixLinter: NixOSLinter;
export {};
//# sourceMappingURL=nix-linter.d.ts.map