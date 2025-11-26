/**
 * Context Inference Types
 *
 * Types for analyzing user input and project state to provide
 * environmental awareness and intelligent context enrichment.
 */
/**
 * User input intent classification
 */
export type Intent = 'query' | 'command' | 'edit' | 'create' | 'debug' | 'refactor' | 'test' | 'build' | 'deploy' | 'unknown';
/**
 * Confidence level for classifications
 */
export type Confidence = 'high' | 'medium' | 'low';
/**
 * Entity extracted from input
 */
export interface Entity {
    /** Entity type */
    type: 'file' | 'function' | 'module' | 'variable' | 'error' | 'package' | 'command';
    /** Entity value/name */
    value: string;
    /** Position in input text */
    position: {
        start: number;
        end: number;
    };
    /** Confidence of extraction */
    confidence: Confidence;
}
/**
 * Topic extracted from input
 */
export interface Topic {
    /** Topic name */
    name: string;
    /** Relevance score (0-1) */
    relevance: number;
    /** Related keywords */
    keywords: string[];
}
/**
 * Result of input analysis
 */
export interface InputAnalysis {
    /** Detected intent */
    intent: Intent;
    /** Intent confidence */
    intentConfidence: Confidence;
    /** Extracted entities */
    entities: Entity[];
    /** Identified topics */
    topics: Topic[];
    /** Input text */
    text: string;
    /** Analysis timestamp */
    timestamp: number;
}
/**
 * Git repository state
 */
export interface GitState {
    /** Current branch */
    branch: string;
    /** Modified files */
    modified: string[];
    /** Staged files */
    staged: string[];
    /** Untracked files */
    untracked: string[];
    /** Is repository dirty */
    isDirty: boolean;
    /** Last commit hash */
    lastCommit?: string;
    /** Last commit message */
    lastCommitMessage?: string;
}
/**
 * Build state
 */
export interface BuildState {
    /** Is build passing */
    success: boolean;
    /** Build errors */
    errors: string[];
    /** Build warnings */
    warnings: string[];
    /** Last build timestamp */
    timestamp: number;
}
/**
 * Project state snapshot
 */
export interface ProjectState {
    /** Project root directory */
    root: string;
    /** Git state */
    git: GitState | null;
    /** Build state */
    build: BuildState | null;
    /** Recently modified files */
    recentFiles: string[];
    /** File count by type */
    fileTypes: Record<string, number>;
    /** Timestamp */
    timestamp: number;
}
/**
 * Detected pattern in history
 */
export interface Pattern {
    /** Pattern ID */
    id: string;
    /** Pattern type */
    type: 'workflow' | 'command_sequence' | 'error_recovery' | 'refactor';
    /** Pattern description */
    description: string;
    /** Frequency of occurrence */
    frequency: number;
    /** Steps in pattern */
    steps: string[];
    /** Success rate */
    successRate: number;
    /** Last seen timestamp */
    lastSeen: number;
}
/**
 * Enriched context combining input + project state + patterns
 */
export interface EnrichedContext {
    /** Input analysis */
    input: InputAnalysis;
    /** Project state */
    project: ProjectState;
    /** Relevant patterns */
    patterns: Pattern[];
    /** Relevance scores for stored knowledge */
    relevantKnowledge: Array<{
        id: number;
        score: number;
    }>;
    /** Context quality score (0-1) */
    quality: number;
}
//# sourceMappingURL=context-inference.d.ts.map