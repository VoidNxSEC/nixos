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
interface CommandTemplate {
    pattern: RegExp;
    generator: (match: RegExpMatchArray, context: any) => string[];
    description: string;
    riskLevel: 'safe' | 'medium' | 'dangerous';
}
interface ExecutionResult {
    success: boolean;
    output: string;
    error?: string;
    commands: string[];
    riskLevel: string;
}
export declare class WildcardCommandSystem {
    private templates;
    private executionHistory;
    constructor();
    /**
     * Register built-in command templates
     */
    private registerBuiltinTemplates;
    /**
     * Register new command template
     */
    register(name: string, template: CommandTemplate): void;
    /**
     * Match command against all templates
     */
    private matchTemplate;
    /**
     * Generate commands from wildcard pattern
     */
    generate(wildcardCommand: string, context?: any): {
        commands: string[];
        description: string;
        riskLevel: string;
    } | null;
    /**
     * Execute wildcard command
     */
    execute(wildcardCommand: string, context?: any): Promise<ExecutionResult>;
    /**
     * List all available wildcard commands
     */
    listCommands(): Array<{
        pattern: string;
        description: string;
        riskLevel: string;
    }>;
    /**
     * Get execution history
     */
    getHistory(limit?: number): typeof this.executionHistory;
    /**
     * Learn from successful executions
     * (Track which commands solve which problems)
     */
    learnFromSuccess(problem: string, commands: string[]): void;
}
export declare const wildcardCommands: WildcardCommandSystem;
export {};
//# sourceMappingURL=wildcard-commands.d.ts.map