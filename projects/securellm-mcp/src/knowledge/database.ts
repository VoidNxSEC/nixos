// Knowledge Database Implementation with SQLite + FTS5

import Database from 'better-sqlite3';
import { randomBytes } from 'crypto';
import { mkdirSync, existsSync } from 'fs';
import { dirname } from 'path';
import type {
  KnowledgeDatabase,
  Session,
  KnowledgeEntry,
  SearchResult,
  SessionStats,
  CreateSessionInput,
  SaveKnowledgeInput,
  SearchKnowledgeInput,
} from '../types/knowledge.js';

export class SQLiteKnowledgeDatabase implements KnowledgeDatabase {
  private db: Database.Database;

  constructor(dbPath: string) {
    // Ensure directory exists before creating database
    const dir = dirname(dbPath);
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
      console.error(`[Knowledge DB] Created directory: ${dir}`);
    }
    
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.db.pragma('foreign_keys = ON');
    this.initialize();
    this.initContextTables();
  }

  private initialize(): void {
    // Create sessions table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        last_active TEXT NOT NULL DEFAULT (datetime('now')),
        summary TEXT,
        entry_count INTEGER NOT NULL DEFAULT 0,
        metadata TEXT NOT NULL DEFAULT '{}'
      );
    `);

    // Create knowledge_entries table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS knowledge_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        entry_type TEXT NOT NULL CHECK(entry_type IN ('insight', 'code', 'decision', 'reference', 'question', 'answer')),
        content TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high')),
        metadata TEXT NOT NULL DEFAULT '{}',
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      );
    `);

    // Create FTS5 virtual table for full-text search
    this.db.exec(`
      CREATE VIRTUAL TABLE IF NOT EXISTS knowledge_fts USING fts5(
        entry_id UNINDEXED,
        content,
        tags,
        tokenize = 'porter unicode61'
      );
    `);

    // Create trigger to keep FTS in sync
    this.db.exec(`
      CREATE TRIGGER IF NOT EXISTS knowledge_entries_ai AFTER INSERT ON knowledge_entries BEGIN
        INSERT INTO knowledge_fts(entry_id, content, tags)
        VALUES (NEW.id, NEW.content, NEW.tags);
      END;
    `);

    this.db.exec(`
      CREATE TRIGGER IF NOT EXISTS knowledge_entries_ad AFTER DELETE ON knowledge_entries BEGIN
        DELETE FROM knowledge_fts WHERE entry_id = OLD.id;
      END;
    `);

    this.db.exec(`
      CREATE TRIGGER IF NOT EXISTS knowledge_entries_au AFTER UPDATE ON knowledge_entries BEGIN
        UPDATE knowledge_fts
        SET content = NEW.content, tags = NEW.tags
        WHERE entry_id = NEW.id;
      END;
    `);

    // Create indexes for performance
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_entries_session ON knowledge_entries(session_id);
      CREATE INDEX IF NOT EXISTS idx_entries_type ON knowledge_entries(entry_type);
      CREATE INDEX IF NOT EXISTS idx_entries_timestamp ON knowledge_entries(timestamp DESC);
      CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(last_active DESC);
    `);

    console.error('[Knowledge DB] Database initialized successfully');
  }

  /**
   * Initialize context inference tables
   */
  private initContextTables(): void {
    // Patterns table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS patterns (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        frequency INTEGER DEFAULT 1,
        steps TEXT NOT NULL,
        success_rate REAL DEFAULT 1.0,
        last_seen INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    `);

    // Project states table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS project_states (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        root TEXT NOT NULL,
        git_branch TEXT,
        git_dirty BOOLEAN,
        build_success BOOLEAN,
        recent_files TEXT,
        file_types TEXT,
        timestamp INTEGER NOT NULL
      )
    `);

    // Create indexes
    this.db.exec(`
      CREATE INDEX IF NOT EXISTS idx_patterns_type ON patterns(type);
      CREATE INDEX IF NOT EXISTS idx_patterns_last_seen ON patterns(last_seen);
      CREATE INDEX IF NOT EXISTS idx_project_states_timestamp ON project_states(timestamp);
    `);
  }

  // ===== SESSION OPERATIONS =====

  async createSession(input: CreateSessionInput): Promise<Session> {
    const id = this.generateSessionId();
    const metadata = JSON.stringify(input.metadata || {});
    
    const stmt = this.db.prepare(`
      INSERT INTO sessions (id, summary, metadata)
      VALUES (?, ?, ?)
    `);
    
    stmt.run(id, input.summary || null, metadata);
    
    const session = await this.getSession(id);
    if (!session) {
      throw new Error('Failed to create session');
    }
    
    return session;
  }

  async getSession(id: string): Promise<Session | null> {
    const stmt = this.db.prepare(`
      SELECT * FROM sessions WHERE id = ?
    `);
    
    const row = stmt.get(id) as any;
    if (!row) return null;
    
    return this.rowToSession(row);
  }

  async listSessions(limit = 50, offset = 0): Promise<Session[]> {
    const stmt = this.db.prepare(`
      SELECT * FROM sessions
      ORDER BY last_active DESC
      LIMIT ? OFFSET ?
    `);
    
    const rows = stmt.all(limit, offset) as any[];
    return rows.map(row => this.rowToSession(row));
  }

  async updateSession(id: string, updates: Partial<Session>): Promise<void> {
    const fields: string[] = [];
    const values: any[] = [];
    
    if (updates.summary !== undefined) {
      fields.push('summary = ?');
      values.push(updates.summary);
    }
    
    if (updates.metadata !== undefined) {
      fields.push('metadata = ?');
      values.push(JSON.stringify(updates.metadata));
    }
    
    // Always update last_active
    fields.push('last_active = datetime(\'now\')');
    
    if (fields.length === 0) return;
    
    values.push(id);
    
    const stmt = this.db.prepare(`
      UPDATE sessions
      SET ${fields.join(', ')}
      WHERE id = ?
    `);
    
    stmt.run(...values);
  }

  async deleteSession(id: string): Promise<void> {
    const stmt = this.db.prepare('DELETE FROM sessions WHERE id = ?');
    stmt.run(id);
  }

  // ===== KNOWLEDGE OPERATIONS =====

  async saveKnowledge(input: SaveKnowledgeInput): Promise<KnowledgeEntry> {
    // Create session if not provided
    let sessionId = input.session_id;
    if (!sessionId) {
      const session = await this.createSession({});
      sessionId = session.id;
    }
    
    const tags = JSON.stringify(input.tags || []);
    const metadata = JSON.stringify(input.metadata || {});
    const priority = input.priority || 'medium';
    
    const stmt = this.db.prepare(`
      INSERT INTO knowledge_entries (session_id, entry_type, content, tags, priority, metadata)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    
    const result = stmt.run(sessionId, input.type, input.content, tags, priority, metadata);
    
    // Update session entry count and last_active
    this.db.prepare(`
      UPDATE sessions
      SET entry_count = entry_count + 1,
          last_active = datetime('now')
      WHERE id = ?
    `).run(sessionId);
    
    const entry = await this.getKnowledgeEntry(result.lastInsertRowid as number);
    if (!entry) {
      throw new Error('Failed to create knowledge entry');
    }
    
    return entry;
  }

  async getKnowledgeEntry(id: number): Promise<KnowledgeEntry | null> {
    const stmt = this.db.prepare(`
      SELECT * FROM knowledge_entries WHERE id = ?
    `);
    
    const row = stmt.get(id) as any;
    if (!row) return null;
    
    return this.rowToKnowledgeEntry(row);
  }

  async searchKnowledge(input: SearchKnowledgeInput): Promise<SearchResult[]> {
    let query = `
      SELECT 
        ke.*,
        kf.rank
      FROM knowledge_entries ke
      JOIN knowledge_fts kf ON ke.id = kf.entry_id
      WHERE knowledge_fts MATCH ?
    `;
    
    const params: any[] = [input.query];
    
    if (input.session_id) {
      query += ' AND ke.session_id = ?';
      params.push(input.session_id);
    }
    
    if (input.entry_type) {
      query += ' AND ke.entry_type = ?';
      params.push(input.entry_type);
    }
    
    query += ' ORDER BY kf.rank LIMIT ?';
    params.push(input.limit || 10);
    
    const stmt = this.db.prepare(query);
    const rows = stmt.all(...params) as any[];
    
    return rows.map(row => ({
      entry: this.rowToKnowledgeEntry(row),
      relevance: -row.rank, // FTS5 rank is negative
      snippet: this.createSnippet(row.content, input.query),
    }));
  }

  async getRecentKnowledge(session_id?: string, limit = 20): Promise<KnowledgeEntry[]> {
    let query = 'SELECT * FROM knowledge_entries';
    const params: any[] = [];
    
    if (session_id) {
      query += ' WHERE session_id = ?';
      params.push(session_id);
    }
    
    query += ' ORDER BY timestamp DESC LIMIT ?';
    params.push(limit);
    
    const stmt = this.db.prepare(query);
    const rows = stmt.all(...params) as any[];
    
    return rows.map(row => this.rowToKnowledgeEntry(row));
  }

  async deleteKnowledgeEntry(id: number): Promise<void> {
    const stmt = this.db.prepare('DELETE FROM knowledge_entries WHERE id = ?');
    stmt.run(id);
  }

  // ===== STATS =====

  async getStats(): Promise<SessionStats> {
    const stats = this.db.prepare(`
      SELECT
        COUNT(DISTINCT s.id) as total_sessions,
        COUNT(ke.id) as total_entries,
        COUNT(DISTINCT CASE WHEN s.last_active >= datetime('now', '-7 days') THEN s.id END) as recent_sessions
      FROM sessions s
      LEFT JOIN knowledge_entries ke ON s.id = ke.session_id
    `).get() as any;
    
    const dbSize = this.db.prepare(`
      SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()
    `).get() as any;
    
    return {
      total_sessions: stats.total_sessions || 0,
      total_entries: stats.total_entries || 0,
      recent_sessions: stats.recent_sessions || 0,
      storage_size_mb: (dbSize.size || 0) / (1024 * 1024),
    };
  }

  // ===== CONTEXT INFERENCE OPERATIONS =====

  /**
   * Store a pattern
   */
  public storePattern(pattern: {
    id: string;
    type: string;
    description: string;
    frequency: number;
    steps: string[];
    successRate: number;
  }): void {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO patterns (id, type, description, frequency, steps, success_rate, last_seen, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      pattern.id,
      pattern.type,
      pattern.description,
      pattern.frequency,
      JSON.stringify(pattern.steps),
      pattern.successRate,
      Date.now(),
      Date.now()
    );
  }

  /**
   * Get patterns by type
   */
  public getPatterns(type?: string, limit: number = 10): any[] {
    let query = 'SELECT * FROM patterns';
    const params: any[] = [];

    if (type) {
      query += ' WHERE type = ?';
      params.push(type);
    }

    query += ' ORDER BY frequency DESC, last_seen DESC LIMIT ?';
    params.push(limit);

    const stmt = this.db.prepare(query);
    const rows = stmt.all(...params);

    return rows.map((row: any) => ({
      id: row.id,
      type: row.type,
      description: row.description,
      frequency: row.frequency,
      steps: JSON.parse(row.steps),
      successRate: row.success_rate,
      lastSeen: row.last_seen,
    }));
  }

  /**
   * Store project state snapshot
   */
  public storeProjectState(state: {
    root: string;
    gitBranch?: string;
    gitDirty: boolean;
    buildSuccess: boolean;
    recentFiles: string[];
    fileTypes: Record<string, number>;
  }): void {
    const stmt = this.db.prepare(`
      INSERT INTO project_states (root, git_branch, git_dirty, build_success, recent_files, file_types, timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      state.root,
      state.gitBranch || null,
      state.gitDirty ? 1 : 0,
      state.buildSuccess ? 1 : 0,
      JSON.stringify(state.recentFiles),
      JSON.stringify(state.fileTypes),
      Date.now()
    );
  }

  /**
   * Get recent project states
   */
  public getRecentProjectStates(limit: number = 10): any[] {
    const stmt = this.db.prepare(`
      SELECT * FROM project_states
      ORDER BY timestamp DESC
      LIMIT ?
    `);

    const rows = stmt.all(limit);

    return rows.map((row: any) => ({
      id: row.id,
      root: row.root,
      gitBranch: row.git_branch,
      gitDirty: Boolean(row.git_dirty),
      buildSuccess: Boolean(row.build_success),
      recentFiles: JSON.parse(row.recent_files),
      fileTypes: JSON.parse(row.file_types),
      timestamp: row.timestamp,
    }));
  }

  // ===== CLEANUP =====

  async cleanupOldSessions(days: number): Promise<number> {
    const stmt = this.db.prepare(`
      DELETE FROM sessions
      WHERE last_active < datetime('now', '-' || ? || ' days')
    `);
    
    const result = stmt.run(days);
    return result.changes;
  }

  // ===== HELPERS =====

  private generateSessionId(): string {
    return `sess_${randomBytes(16).toString('hex')}`;
  }

  private rowToSession(row: any): Session {
    return {
      id: row.id,
      created_at: row.created_at,
      last_active: row.last_active,
      summary: row.summary,
      entry_count: row.entry_count,
      metadata: JSON.parse(row.metadata),
    };
  }

  private rowToKnowledgeEntry(row: any): KnowledgeEntry {
    return {
      id: row.id,
      session_id: row.session_id,
      timestamp: row.timestamp,
      entry_type: row.entry_type,
      content: row.content,
      tags: JSON.parse(row.tags),
      priority: row.priority,
      metadata: JSON.parse(row.metadata),
    };
  }

  private createSnippet(content: string, query: string, maxLength = 200): string {
    const words = query.toLowerCase().split(/\s+/);
    const contentLower = content.toLowerCase();
    
    // Find first occurrence of any query word
    let startIdx = -1;
    for (const word of words) {
      const idx = contentLower.indexOf(word);
      if (idx !== -1 && (startIdx === -1 || idx < startIdx)) {
        startIdx = idx;
      }
    }
    
    if (startIdx === -1) {
      // No match found, return beginning
      return content.substring(0, maxLength) + (content.length > maxLength ? '...' : '');
    }
    
    // Create snippet around match
    const snippetStart = Math.max(0, startIdx - 50);
    const snippetEnd = Math.min(content.length, startIdx + maxLength);
    
    let snippet = content.substring(snippetStart, snippetEnd);
    
    if (snippetStart > 0) snippet = '...' + snippet;
    if (snippetEnd < content.length) snippet = snippet + '...';
    
    return snippet;
  }

  close(): void {
    this.db.close();
  }
}

// Factory function
export function createKnowledgeDatabase(dbPath: string): KnowledgeDatabase {
  return new SQLiteKnowledgeDatabase(dbPath);
}