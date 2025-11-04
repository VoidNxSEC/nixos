#!/usr/bin/env python3
"""
ML Model Registry

Scans filesystem for ML models and maintains SQLite database with metadata:
- Model name, path, format (GGUF, SafeTensors, Ollama)
- Size (GB), estimated VRAM usage (GB)
- Compatible backends, architecture info
- Last used timestamp, usage count

Usage:
    python registry.py scan --models-path /var/lib/ml-models --db-path /var/lib/ml-offload/registry.db
    python registry.py list --db-path /var/lib/ml-offload/registry.db
    python registry.py info <model_id> --db-path /var/lib/ml-offload/registry.db
"""

import argparse
import json
import os
import re
import sqlite3
import struct
import sys
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Dict, Set


@dataclass
class ModelMetadata:
    """Model metadata structure"""
    id: Optional[int] = None
    name: str = ""
    path: str = ""
    format: str = ""  # GGUF, SafeTensors, Ollama, PyTorch, ONNX
    size_gb: float = 0.0
    vram_estimate_gb: float = 0.0
    architecture: str = ""  # llama, mistral, qwen, etc.
    quantization: str = ""  # Q4_K_M, Q5_K_S, fp16, etc.
    parameter_count: str = ""  # 7B, 13B, 70B, etc.
    context_length: int = 0
    compatible_backends: str = ""  # JSON list: ["llamacpp", "ollama"]
    last_scanned: str = ""
    last_used: Optional[str] = None
    usage_count: int = 0
    priority: str = "medium"  # low, medium, high
    tags: str = ""  # JSON list of tags
    notes: str = ""


class RegistryDatabase:
    """SQLite database handler for model registry"""

    SCHEMA = """
    CREATE TABLE IF NOT EXISTS models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        path TEXT NOT NULL UNIQUE,
        format TEXT NOT NULL,
        size_gb REAL NOT NULL,
        vram_estimate_gb REAL NOT NULL,
        architecture TEXT,
        quantization TEXT,
        parameter_count TEXT,
        context_length INTEGER DEFAULT 0,
        compatible_backends TEXT,  -- JSON array
        last_scanned TEXT NOT NULL,
        last_used TEXT,
        usage_count INTEGER DEFAULT 0,
        priority TEXT DEFAULT 'medium',
        tags TEXT,  -- JSON array
        notes TEXT,
        UNIQUE(path)
    );

    CREATE INDEX IF NOT EXISTS idx_models_name ON models(name);
    CREATE INDEX IF NOT EXISTS idx_models_format ON models(format);
    CREATE INDEX IF NOT EXISTS idx_models_priority ON models(priority);
    CREATE INDEX IF NOT EXISTS idx_models_last_used ON models(last_used);
    """

    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn: Optional[sqlite3.Connection] = None

    def __enter__(self):
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.executescript(self.SCHEMA)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.conn:
            self.conn.close()

    def upsert_model(self, model: ModelMetadata) -> int:
        """Insert or update model metadata"""
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO models (
                name, path, format, size_gb, vram_estimate_gb,
                architecture, quantization, parameter_count, context_length,
                compatible_backends, last_scanned, last_used, usage_count,
                priority, tags, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(path) DO UPDATE SET
                name = excluded.name,
                format = excluded.format,
                size_gb = excluded.size_gb,
                vram_estimate_gb = excluded.vram_estimate_gb,
                architecture = excluded.architecture,
                quantization = excluded.quantization,
                parameter_count = excluded.parameter_count,
                context_length = excluded.context_length,
                compatible_backends = excluded.compatible_backends,
                last_scanned = excluded.last_scanned,
                tags = excluded.tags,
                notes = excluded.notes
        """, (
            model.name, model.path, model.format, model.size_gb, model.vram_estimate_gb,
            model.architecture, model.quantization, model.parameter_count,
            model.context_length, model.compatible_backends, model.last_scanned,
            model.last_used, model.usage_count, model.priority, model.tags, model.notes
        ))
        self.conn.commit()
        return cursor.lastrowid

    def get_all_models(self) -> List[ModelMetadata]:
        """Get all models from registry"""
        cursor = self.conn.cursor()
        rows = cursor.execute("SELECT * FROM models ORDER BY name").fetchall()
        return [ModelMetadata(**dict(row)) for row in rows]

    def get_model_by_id(self, model_id: int) -> Optional[ModelMetadata]:
        """Get model by ID"""
        cursor = self.conn.cursor()
        row = cursor.execute("SELECT * FROM models WHERE id = ?", (model_id,)).fetchone()
        return ModelMetadata(**dict(row)) if row else None

    def get_model_by_path(self, path: str) -> Optional[ModelMetadata]:
        """Get model by file path"""
        cursor = self.conn.cursor()
        row = cursor.execute("SELECT * FROM models WHERE path = ?", (path,)).fetchone()
        return ModelMetadata(**dict(row)) if row else None

    def delete_missing_models(self, existing_paths: Set[str]) -> int:
        """Delete models that no longer exist on filesystem"""
        cursor = self.conn.cursor()
        all_models = self.get_all_models()
        deleted_count = 0

        for model in all_models:
            if model.path not in existing_paths:
                cursor.execute("DELETE FROM models WHERE id = ?", (model.id,))
                deleted_count += 1
                print(f"  Deleted missing model: {model.name}")

        self.conn.commit()
        return deleted_count


class ModelScanner:
    """Scans filesystem for ML models and extracts metadata"""

    # Supported model formats and extensions
    GGUF_EXTENSIONS = {".gguf", ".ggml"}
    SAFETENSORS_EXTENSIONS = {".safetensors"}
    PYTORCH_EXTENSIONS = {".pt", ".pth", ".bin"}
    ONNX_EXTENSIONS = {".onnx"}

    # GGUF quantization patterns
    GGUF_QUANT_PATTERN = re.compile(r"(Q\d+_[KMS](?:_[LMS])?|F16|F32)", re.IGNORECASE)

    # Parameter count patterns (7B, 13B, 70B, etc.)
    PARAM_PATTERN = re.compile(r"(\d+\.?\d*[BMK])", re.IGNORECASE)

    # Architecture patterns
    ARCH_PATTERNS = {
        "llama": re.compile(r"llama|l3|mistral|mixtral", re.IGNORECASE),
        "qwen": re.compile(r"qwen|qwq", re.IGNORECASE),
        "phi": re.compile(r"phi-?\d+", re.IGNORECASE),
        "gemma": re.compile(r"gemma", re.IGNORECASE),
        "falcon": re.compile(r"falcon", re.IGNORECASE),
    }

    def __init__(self, models_path: str):
        self.models_path = Path(models_path)

    def scan(self) -> List[ModelMetadata]:
        """Scan models directory and return metadata"""
        print(f"Scanning models in: {self.models_path}")
        models = []

        for root, dirs, files in os.walk(self.models_path):
            # Skip cache directories
            dirs[:] = [d for d in dirs if d not in {".cache", "cache", "tmp"}]

            for file in files:
                file_path = Path(root) / file
                ext = file_path.suffix.lower()

                # Detect format
                if ext in self.GGUF_EXTENSIONS:
                    metadata = self._scan_gguf(file_path)
                elif ext in self.SAFETENSORS_EXTENSIONS:
                    metadata = self._scan_safetensors(file_path)
                elif ext in self.PYTORCH_EXTENSIONS:
                    metadata = self._scan_pytorch(file_path)
                elif ext in self.ONNX_EXTENSIONS:
                    metadata = self._scan_onnx(file_path)
                elif file == "Modelfile":  # Ollama model
                    metadata = self._scan_ollama(file_path)
                else:
                    continue

                if metadata:
                    models.append(metadata)
                    print(f"  Found: {metadata.name} ({metadata.format}, {metadata.size_gb:.2f}GB)")

        return models

    def _scan_gguf(self, file_path: Path) -> Optional[ModelMetadata]:
        """Scan GGUF model file"""
        try:
            size_gb = file_path.stat().st_size / (1024 ** 3)
            filename = file_path.stem

            # Extract metadata from filename
            quant_match = self.GGUF_QUANT_PATTERN.search(filename)
            quantization = quant_match.group(1).upper() if quant_match else "Unknown"

            param_match = self.PARAM_PATTERN.search(filename)
            parameter_count = param_match.group(1).upper() if param_match else ""

            # Detect architecture
            architecture = "unknown"
            for arch, pattern in self.ARCH_PATTERNS.items():
                if pattern.search(filename):
                    architecture = arch
                    break

            # Estimate VRAM usage (rough estimate based on size)
            # GGUF models typically use ~size + 500MB overhead
            vram_estimate = size_gb + 0.5

            # Compatible backends
            backends = ["llamacpp", "ollama"]

            return ModelMetadata(
                name=filename,
                path=str(file_path.absolute()),
                format="GGUF",
                size_gb=round(size_gb, 2),
                vram_estimate_gb=round(vram_estimate, 2),
                architecture=architecture,
                quantization=quantization,
                parameter_count=parameter_count,
                context_length=0,  # Would need to parse GGUF header
                compatible_backends=json.dumps(backends),
                last_scanned=datetime.now().isoformat(),
                priority="medium",
                tags=json.dumps([]),
                notes=""
            )
        except Exception as e:
            print(f"  Error scanning GGUF {file_path}: {e}", file=sys.stderr)
            return None

    def _scan_safetensors(self, file_path: Path) -> Optional[ModelMetadata]:
        """Scan SafeTensors model file"""
        try:
            size_gb = file_path.stat().st_size / (1024 ** 3)
            filename = file_path.stem

            # Extract metadata from filename
            param_match = self.PARAM_PATTERN.search(filename)
            parameter_count = param_match.group(1).upper() if param_match else ""

            # Detect architecture
            architecture = "unknown"
            for arch, pattern in self.ARCH_PATTERNS.items():
                if pattern.search(filename):
                    architecture = arch
                    break

            # SafeTensors typically fp16 or bf16
            # VRAM estimate: size * 1.2 (model + kv cache)
            vram_estimate = size_gb * 1.2

            backends = ["vllm", "tgi"]

            return ModelMetadata(
                name=filename,
                path=str(file_path.absolute()),
                format="SafeTensors",
                size_gb=round(size_gb, 2),
                vram_estimate_gb=round(vram_estimate, 2),
                architecture=architecture,
                quantization="fp16",  # Assume fp16
                parameter_count=parameter_count,
                context_length=0,
                compatible_backends=json.dumps(backends),
                last_scanned=datetime.now().isoformat(),
                priority="medium",
                tags=json.dumps([]),
                notes=""
            )
        except Exception as e:
            print(f"  Error scanning SafeTensors {file_path}: {e}", file=sys.stderr)
            return None

    def _scan_pytorch(self, file_path: Path) -> Optional[ModelMetadata]:
        """Scan PyTorch model file"""
        try:
            size_gb = file_path.stat().st_size / (1024 ** 3)
            filename = file_path.stem

            param_match = self.PARAM_PATTERN.search(filename)
            parameter_count = param_match.group(1).upper() if param_match else ""

            architecture = "unknown"
            for arch, pattern in self.ARCH_PATTERNS.items():
                if pattern.search(filename):
                    architecture = arch
                    break

            vram_estimate = size_gb * 1.2

            backends = ["pytorch"]

            return ModelMetadata(
                name=filename,
                path=str(file_path.absolute()),
                format="PyTorch",
                size_gb=round(size_gb, 2),
                vram_estimate_gb=round(vram_estimate, 2),
                architecture=architecture,
                quantization="fp32",
                parameter_count=parameter_count,
                context_length=0,
                compatible_backends=json.dumps(backends),
                last_scanned=datetime.now().isoformat(),
                priority="medium",
                tags=json.dumps([]),
                notes=""
            )
        except Exception as e:
            print(f"  Error scanning PyTorch {file_path}: {e}", file=sys.stderr)
            return None

    def _scan_onnx(self, file_path: Path) -> Optional[ModelMetadata]:
        """Scan ONNX model file"""
        try:
            size_gb = file_path.stat().st_size / (1024 ** 3)
            filename = file_path.stem

            param_match = self.PARAM_PATTERN.search(filename)
            parameter_count = param_match.group(1).upper() if param_match else ""

            vram_estimate = size_gb * 1.1

            backends = ["onnx"]

            return ModelMetadata(
                name=filename,
                path=str(file_path.absolute()),
                format="ONNX",
                size_gb=round(size_gb, 2),
                vram_estimate_gb=round(vram_estimate, 2),
                architecture="unknown",
                quantization="",
                parameter_count=parameter_count,
                context_length=0,
                compatible_backends=json.dumps(backends),
                last_scanned=datetime.now().isoformat(),
                priority="medium",
                tags=json.dumps([]),
                notes=""
            )
        except Exception as e:
            print(f"  Error scanning ONNX {file_path}: {e}", file=sys.stderr)
            return None

    def _scan_ollama(self, file_path: Path) -> Optional[ModelMetadata]:
        """Scan Ollama model (Modelfile)"""
        try:
            # Ollama models are in directories with Modelfile
            model_dir = file_path.parent
            model_name = model_dir.name

            # Calculate total size of model directory
            total_size = sum(f.stat().st_size for f in model_dir.rglob("*") if f.is_file())
            size_gb = total_size / (1024 ** 3)

            # Read Modelfile for metadata (if available)
            # This is a simplified version; full parsing would be more complex

            vram_estimate = size_gb + 0.5

            backends = ["ollama"]

            return ModelMetadata(
                name=model_name,
                path=str(model_dir.absolute()),
                format="Ollama",
                size_gb=round(size_gb, 2),
                vram_estimate_gb=round(vram_estimate, 2),
                architecture="unknown",
                quantization="",
                parameter_count="",
                context_length=0,
                compatible_backends=json.dumps(backends),
                last_scanned=datetime.now().isoformat(),
                priority="medium",
                tags=json.dumps([]),
                notes="Ollama model directory"
            )
        except Exception as e:
            print(f"  Error scanning Ollama {file_path}: {e}", file=sys.stderr)
            return None


def cmd_scan(args):
    """Scan models and update registry"""
    scanner = ModelScanner(args.models_path)
    models = scanner.scan()

    if not models:
        print("No models found")
        return 0

    print(f"\nFound {len(models)} models")
    print(f"Updating registry database: {args.db_path}")

    with RegistryDatabase(args.db_path) as db:
        existing_paths = {model.path for model in models}

        # Upsert all scanned models
        for model in models:
            db.upsert_model(model)

        # Delete models that no longer exist
        deleted = db.delete_missing_models(existing_paths)
        if deleted > 0:
            print(f"Removed {deleted} missing models from registry")

    print("Registry update complete")
    return 0


def cmd_list(args):
    """List all models in registry"""
    with RegistryDatabase(args.db_path) as db:
        models = db.get_all_models()

    if not models:
        print("No models in registry")
        return 0

    print(f"{'ID':<5} {'Name':<50} {'Format':<12} {'Size (GB)':<10} {'VRAM (GB)':<10}")
    print("=" * 100)
    for model in models:
        print(f"{model.id:<5} {model.name:<50} {model.format:<12} {model.size_gb:<10.2f} {model.vram_estimate_gb:<10.2f}")

    print(f"\nTotal models: {len(models)}")
    return 0


def cmd_info(args):
    """Show detailed info for a model"""
    with RegistryDatabase(args.db_path) as db:
        model = db.get_model_by_id(args.model_id)

    if not model:
        print(f"Model ID {args.model_id} not found", file=sys.stderr)
        return 1

    print(json.dumps(asdict(model), indent=2))
    return 0


def main():
    parser = argparse.ArgumentParser(description="ML Model Registry Manager")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Scan command
    scan_parser = subparsers.add_parser("scan", help="Scan models directory")
    scan_parser.add_argument("--models-path", required=True, help="Path to models directory")
    scan_parser.add_argument("--db-path", required=True, help="Path to registry database")

    # List command
    list_parser = subparsers.add_parser("list", help="List all models")
    list_parser.add_argument("--db-path", required=True, help="Path to registry database")

    # Info command
    info_parser = subparsers.add_parser("info", help="Show model details")
    info_parser.add_argument("model_id", type=int, help="Model ID")
    info_parser.add_argument("--db-path", required=True, help="Path to registry database")

    args = parser.parse_args()

    if args.command == "scan":
        return cmd_scan(args)
    elif args.command == "list":
        return cmd_list(args)
    elif args.command == "info":
        return cmd_info(args)


if __name__ == "__main__":
    sys.exit(main())
