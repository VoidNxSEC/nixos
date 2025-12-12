import Database from 'better-sqlite3';
export class VectorStore {
    db;
    llamaCppServer;
    constructor(dbPath, llamaCppServer = 'http://localhost:8080') {
        this.db = new Database(dbPath);
        this.llamaCppServer = llamaCppServer;
        this.initialize();
    }
    /**
     * Initialize vector store schema
     */
    initialize() {
        this.db.exec(`
      CREATE TABLE IF NOT EXISTS vector_documents (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        summary TEXT NOT NULL,
        embedding BLOB NOT NULL,
        metadata TEXT,
        timestamp INTEGER NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_timestamp ON vector_documents(timestamp);
      
      CREATE VIRTUAL TABLE IF NOT EXISTS vector_fts USING fts5(
        id UNINDEXED,
        content,
        summary,
        metadata
      );
    `);
    }
    /**
     * Generate embedding using llama.cpp locally (FREE)
     */
    async generateEmbedding(text) {
        try {
            const response = await fetch(`${this.llamaCppServer}/embedding`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ content: text }),
            });
            if (!response.ok) {
                throw new Error(`llama.cpp embedding failed: ${response.statusText}`);
            }
            const data = await response.json();
            return new Float32Array(data.embedding);
        }
        catch (error) {
            console.error('[VectorStore] Local embedding failed:', error);
            // Fallback: use simple hash-based embedding
            return this.fallbackEmbedding(text);
        }
    }
    /**
     * Fallback embedding if llama.cpp unavailable
     */
    fallbackEmbedding(text) {
        // Simple hash-based embedding (384 dimensions)
        const embedding = new Float32Array(384);
        for (let i = 0; i < text.length; i++) {
            const idx = text.charCodeAt(i) % 384;
            embedding[idx] += 1;
        }
        // Normalize
        const norm = Math.sqrt(embedding.reduce((sum, val) => sum + val * val, 0));
        return embedding.map(val => val / (norm || 1));
    }
    /**
     * Intelligent summarization using llama.cpp (FREE)
     * Reduces content to 20% of original size while keeping key info
     */
    async summarize(content, maxTokens = 200) {
        // Don't summarize if already short
        if (content.length < 500) {
            return content;
        }
        try {
            const response = await fetch(`${this.llamaCppServer}/completion`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    prompt: `Summarize the following in ${maxTokens} tokens, keeping technical details:\n\n${content}\n\nSummary:`,
                    n_predict: maxTokens,
                    temperature: 0.1,
                    stop: ['\n\n'],
                }),
            });
            if (!response.ok) {
                throw new Error(`llama.cpp summarization failed: ${response.statusText}`);
            }
            const data = await response.json();
            return data.content.trim();
        }
        catch (error) {
            console.error('[VectorStore] Local summarization failed:', error);
            // Fallback: simple truncation
            return content.substring(0, maxTokens * 4) + '...';
        }
    }
    /**
     * Store document with automatic embedding and summarization
     */
    async store(id, content, metadata = {}) {
        // Generate summary locally (FREE)
        const summary = await this.summarize(content);
        // Generate embedding locally (FREE)
        const embedding = await this.generateEmbedding(content);
        // Store in database
        const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO vector_documents 
      (id, content, summary, embedding, metadata, timestamp)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
        stmt.run(id, content, summary, Buffer.from(embedding.buffer), JSON.stringify(metadata), Date.now());
        // Update FTS index
        const ftsStmt = this.db.prepare(`
      INSERT OR REPLACE INTO vector_fts (id, content, summary, metadata)
      VALUES (?, ?, ?, ?)
    `);
        ftsStmt.run(id, content, summary, JSON.stringify(metadata));
    }
    /**
     * Semantic search using cosine similarity
     */
    async search(query, limit = 10, threshold = 0.5) {
        // Generate query embedding locally (FREE)
        const queryEmbedding = await this.generateEmbedding(query);
        // Get all documents
        const stmt = this.db.prepare('SELECT * FROM vector_documents');
        const documents = stmt.all();
        // Calculate similarities
        const results = [];
        for (const doc of documents) {
            const embedding = new Float32Array(doc.embedding);
            const similarity = this.cosineSimilarity(queryEmbedding, embedding);
            if (similarity >= threshold) {
                results.push({
                    document: {
                        id: doc.id,
                        content: doc.content,
                        summary: doc.summary,
                        embedding,
                        metadata: JSON.parse(doc.metadata || '{}'),
                        timestamp: doc.timestamp,
                    },
                    similarity,
                });
            }
        }
        // Sort by similarity and limit
        return results
            .sort((a, b) => b.similarity - a.similarity)
            .slice(0, limit);
    }
    /**
     * Hybrid search: semantic + full-text
     */
    async hybridSearch(query, limit = 10) {
        // Semantic search
        const semanticResults = await this.search(query, limit);
        // Full-text search
        const ftsStmt = this.db.prepare(`
      SELECT id FROM vector_fts 
      WHERE vector_fts MATCH ?
      LIMIT ?
    `);
        const ftsResults = ftsStmt.all(query, limit);
        const ftsIds = new Set(ftsResults.map(r => r.id));
        // Merge results, boosting FTS matches
        const merged = semanticResults.map(result => ({
            ...result,
            similarity: ftsIds.has(result.document.id)
                ? result.similarity * 1.2 // Boost if also FTS match
                : result.similarity,
        }));
        return merged.sort((a, b) => b.similarity - a.similarity).slice(0, limit);
    }
    /**
     * Get summarized context for API call
     * Returns only relevant summaries to minimize token usage
     */
    async getRelevantContext(query, maxTokens = 1000) {
        const results = await this.hybridSearch(query, 5);
        let context = '';
        let tokens = 0;
        for (const result of results) {
            const summaryTokens = result.document.summary.length / 4; // Rough estimate
            if (tokens + summaryTokens > maxTokens) {
                break;
            }
            context += `[Relevance: ${(result.similarity * 100).toFixed(0)}%]\n`;
            context += result.document.summary + '\n\n';
            tokens += summaryTokens;
        }
        return context.trim();
    }
    /**
     * Cosine similarity between two vectors
     */
    cosineSimilarity(a, b) {
        if (a.length !== b.length)
            return 0;
        let dotProduct = 0;
        let normA = 0;
        let normB = 0;
        for (let i = 0; i < a.length; i++) {
            dotProduct += a[i] * b[i];
            normA += a[i] * a[i];
            normB += b[i] * b[i];
        }
        return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
    }
    /**
     * Get storage statistics
     */
    getStats() {
        const countStmt = this.db.prepare('SELECT COUNT(*) as count FROM vector_documents');
        const count = countStmt.get().count;
        const sizeStmt = this.db.prepare("SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()");
        const size = sizeStmt.get().size;
        return {
            documentCount: count,
            databaseSize: size,
            averageDocSize: count > 0 ? size / count : 0,
        };
    }
    /**
     * Close database connection
     */
    close() {
        this.db.close();
    }
}
/**
 * Token-efficient context builder
 * Builds minimal context by using summaries and semantic search
 */
export class IntelligentContextBuilder {
    vectorStore;
    constructor(vectorStore) {
        this.vectorStore = vectorStore;
    }
    /**
     * Build context for API call with minimal tokens
     *
     * Traditional approach: Send ALL context (10,000+ tokens)
     * Intelligent approach: Send ONLY relevant summaries (500 tokens)
     *
     * Token savings: 95%!
     */
    async buildContext(query, maxTokens = 1000) {
        const relevantContext = await this.vectorStore.getRelevantContext(query, maxTokens);
        const tokensUsed = relevantContext.length / 4; // Rough estimate
        // Estimate tokens saved vs sending all documents
        const stats = this.vectorStore.getStats();
        const estimatedFullTokens = stats.documentCount * 2000; // Avg doc size
        const tokensSaved = estimatedFullTokens - tokensUsed;
        return {
            context: relevantContext,
            tokensUsed: Math.round(tokensUsed),
            tokensSaved: Math.round(tokensSaved),
        };
    }
}
//# sourceMappingURL=vector-store.js.map