// Type definitions for Knowledge Management

export interface Session {
  id: string;
  created_at: string;
  last_active: string;
  summary: string | null;
  entry_count: number;
  metadata: Record<string, any>;
}

export interface KnowledgeEntry {
  id: number;
  session_id: string;
  timestamp: string;
  entry_type: 'insight' | 'code' | 'decision' | 'reference' | 'question' | 'answer';
  content: string;
  tags: string[];
  priority: 'low' | 'medium' | 'high';
  metadata: Record<string, any>;
}

export interface SearchResult {
  entry: KnowledgeEntry;
  relevance: number;
  snippet: string;
}

export interface SessionStats {
  total_sessions: number;
  total_entries: number;
  recent_sessions: number;
  storage_size_mb: number;
}

export interface CreateSessionInput {
  summary?: string;
  metadata?: Record<string, any>;
}

export interface SaveKnowledgeInput {
  session_id?: string;
  content: string;
  type: KnowledgeEntry['entry_type'];
  tags?: string[];
  priority?: KnowledgeEntry['priority'];
  metadata?: Record<string, any>;
}

export interface SearchKnowledgeInput {
  query: string;
  session_id?: string;
  entry_type?: KnowledgeEntry['entry_type'];
  limit?: number;
}

export interface KnowledgeDatabase {
  // Session operations
  createSession(input: CreateSessionInput): Promise<Session>;
  getSession(id: string): Promise<Session | null>;
  listSessions(limit?: number, offset?: number): Promise<Session[]>;
  updateSession(id: string, updates: Partial<Session>): Promise<void>;
  deleteSession(id: string): Promise<void>;
  
  // Knowledge operations
  saveKnowledge(input: SaveKnowledgeInput): Promise<KnowledgeEntry>;
  getKnowledgeEntry(id: number): Promise<KnowledgeEntry | null>;
  searchKnowledge(input: SearchKnowledgeInput): Promise<SearchResult[]>;
  getRecentKnowledge(session_id?: string, limit?: number): Promise<KnowledgeEntry[]>;
  deleteKnowledgeEntry(id: number): Promise<void>;
  
  // Stats
  getStats(): Promise<SessionStats>;
  
  // Cleanup
  cleanupOldSessions(days: number): Promise<number>;
  
  // Close
  close(): void;
}