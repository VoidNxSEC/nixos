import type { KnowledgeDatabase, Session, KnowledgeEntry, SearchResult, SessionStats, CreateSessionInput, SaveKnowledgeInput, SearchKnowledgeInput } from '../types/knowledge.js';
export declare class SQLiteKnowledgeDatabase implements KnowledgeDatabase {
    private db;
    constructor(dbPath: string);
    private initialize;
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
    cleanupOldSessions(days: number): Promise<number>;
    private generateSessionId;
    private rowToSession;
    private rowToKnowledgeEntry;
    private createSnippet;
    close(): void;
}
export declare function createKnowledgeDatabase(dbPath: string): KnowledgeDatabase;
//# sourceMappingURL=database.d.ts.map