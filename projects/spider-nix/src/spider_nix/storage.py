"""Data storage and export for SpiderNix."""

import json
import csv
import aiosqlite
from pathlib import Path
from typing import Any
from dataclasses import dataclass, field
from datetime import datetime


@dataclass 
class CrawlResult:
    """Single crawl result."""
    
    url: str
    status_code: int
    content: str
    headers: dict[str, str] = field(default_factory=dict)
    metadata: dict[str, Any] = field(default_factory=dict)
    timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    
    def to_dict(self) -> dict[str, Any]:
        return {
            "url": self.url,
            "status_code": self.status_code,
            "content": self.content,
            "headers": self.headers,
            "metadata": self.metadata,
            "timestamp": self.timestamp,
        }


class StorageBackend:
    """Base storage backend."""
    
    async def save(self, result: CrawlResult) -> None:
        raise NotImplementedError
    
    async def save_batch(self, results: list[CrawlResult]) -> None:
        for result in results:
            await self.save(result)
    
    async def close(self) -> None:
        pass


class JsonStorage(StorageBackend):
    """Store results as JSON lines."""
    
    def __init__(self, filepath: str | Path):
        self.filepath = Path(filepath)
        self.filepath.parent.mkdir(parents=True, exist_ok=True)
    
    async def save(self, result: CrawlResult) -> None:
        with open(self.filepath, "a") as f:
            f.write(json.dumps(result.to_dict()) + "\n")


class CsvStorage(StorageBackend):
    """Store results as CSV."""
    
    def __init__(self, filepath: str | Path):
        self.filepath = Path(filepath)
        self.filepath.parent.mkdir(parents=True, exist_ok=True)
        self._headers_written = self.filepath.exists()
    
    async def save(self, result: CrawlResult) -> None:
        data = result.to_dict()
        # Flatten nested dicts
        flat = {
            "url": data["url"],
            "status_code": data["status_code"],
            "content_length": len(data["content"]),
            "timestamp": data["timestamp"],
        }
        
        with open(self.filepath, "a", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=flat.keys())
            if not self._headers_written:
                writer.writeheader()
                self._headers_written = True
            writer.writerow(flat)


class SqliteStorage(StorageBackend):
    """Store results in SQLite with FTS5 search."""
    
    def __init__(self, filepath: str | Path):
        self.filepath = Path(filepath)
        self.filepath.parent.mkdir(parents=True, exist_ok=True)
        self._conn: aiosqlite.Connection | None = None
    
    async def _ensure_connection(self) -> aiosqlite.Connection:
        if self._conn is None:
            self._conn = await aiosqlite.connect(self.filepath)
            await self._conn.execute("""
                CREATE TABLE IF NOT EXISTS crawl_results (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT NOT NULL,
                    status_code INTEGER,
                    content TEXT,
                    headers TEXT,
                    metadata TEXT,
                    timestamp TEXT
                )
            """)
            await self._conn.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS crawl_fts USING fts5(
                    url, content, content='crawl_results', content_rowid='id'
                )
            """)
            await self._conn.commit()
        return self._conn
    
    async def save(self, result: CrawlResult) -> None:
        conn = await self._ensure_connection()
        await conn.execute(
            """INSERT INTO crawl_results (url, status_code, content, headers, metadata, timestamp)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                result.url,
                result.status_code,
                result.content,
                json.dumps(result.headers),
                json.dumps(result.metadata),
                result.timestamp,
            )
        )
        await conn.commit()
    
    async def search(self, query: str, limit: int = 100) -> list[dict]:
        """Full-text search across crawl results."""
        conn = await self._ensure_connection()
        cursor = await conn.execute(
            """SELECT r.* FROM crawl_results r
               JOIN crawl_fts f ON r.id = f.rowid
               WHERE crawl_fts MATCH ?
               LIMIT ?""",
            (query, limit)
        )
        rows = await cursor.fetchall()
        return [dict(zip([d[0] for d in cursor.description], row)) for row in rows]
    
    async def close(self) -> None:
        if self._conn:
            await self._conn.close()
            self._conn = None


def get_storage(output_path: str, format: str = "json") -> StorageBackend:
    """Factory to create storage backend."""
    path = Path(output_path)
    
    if format == "json":
        return JsonStorage(path.with_suffix(".jsonl"))
    elif format == "csv":
        return CsvStorage(path.with_suffix(".csv"))
    elif format == "sqlite":
        return SqliteStorage(path.with_suffix(".db"))
    else:
        raise ValueError(f"Unknown format: {format}")
