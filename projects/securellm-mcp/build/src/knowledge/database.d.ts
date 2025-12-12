import type { KnowledgeDatabase, Session, KnowledgeEntry, SearchResult, SessionStats, CreateSessionInput, SaveKnowledgeInput, SearchKnowledgeInput } from '../types/knowledge.js';
export declare class SQLiteKnowledgeDatabase implements KnowledgeDatabase {
    private db;
    constructor(dbPath: string);
    private initialize;
    /**
     * Initialize context inference tables
     */
    private initContextTables;
    createSession(input: CreateSessionInput): Promise<Session>;
    getSession(id: string): Promise<Session | null>;
    listSessions(limit?: number, offset?: number): Promise<Session[]>;
    updateSession(id: string, updates: Partial<Session>): Promise<void>;
    deleteSession(id: string): Promise<void>;
    saveKnowledge(input: SaveKnowledgeInput): Promise<KnowledgeEntry>;
    getKnowledgeEntry(id: number): Promise<KnowledgeEntry | null>;
    searchKnowledge(input: SearchKnowledgeInput): Promise<SearchResult[]>;
    getRecentKnowledge(session_id?: string, limit?: number): Promise<KnowledgeEntry[]>;
    deleteKnowledgeEntry(id: number): Promise<void>;
    getStats(): Promise<SessionStats>;
    /**
     * Store a pattern
     */
    storePattern(pattern: {
        id: string;
        type: string;
        description: string;
        frequency: number;
        steps: string[];
        successRate: number;
    }): void;
    /**
     * Get patterns by type
     */
    getPatterns(type?: string, limit?: number): any[];
    /**
     * Store project state snapshot
     */
    storeProjectState(state: {
        root: string;
        gitBranch?: string;
        gitDirty: boolean;
        buildSuccess: boolean;
        recentFiles: string[];
        fileTypes: Record<string, number>;
    }): void;
    /**
     * Get recent project states
     */
    getRecentProjectStates(limit?: number): any[];
    cleanupOldSessions(days: number): Promise<number>;
    private generateSessionId;
    private rowToSession;
    private rowToKnowledgeEntry;
    private createSnippet;
    close(): void;
}
export declare function createKnowledgeDatabase(dbPath: string): KnowledgeDatabase;
//# sourceMappingURL=database.d.ts.map