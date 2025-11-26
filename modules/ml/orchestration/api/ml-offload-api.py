#!/usr/bin/env python3
"""
ML Offload Manager - REST API

Unified API for ML model offloading across multiple backends.
Provides centralized control for Ollama, llama.cpp, vLLM, TGI, and more.

API Endpoints:
- GET  /health              - Health check
- GET  /backends            - List backends
- GET  /models              - List models from registry
- POST /load                - Load model on backend
- POST /unload              - Unload model
- POST /switch              - Switch model (hot-reload)
- GET  /status              - Real-time status
- GET  /vram                - VRAM details
- POST /schedule            - Schedule model load

Author: kernelcore
License: MIT
"""

import os
import sys
import json
import sqlite3
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional, Any

from fastapi import FastAPI, HTTPException, BackgroundTasks, Query
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


# =============================================================================
# Configuration
# =============================================================================

DATA_DIR = Path(os.getenv("ML_OFFLOAD_DATA_DIR", "/var/lib/ml-offload"))
MODELS_PATH = Path(os.getenv("ML_OFFLOAD_MODELS_PATH", "/var/lib/ml-models"))
DB_PATH = Path(os.getenv("ML_OFFLOAD_DB_PATH", DATA_DIR / "registry.db"))
STATE_FILE = Path(os.getenv("ML_OFFLOAD_STATE_FILE", DATA_DIR / "vram-state.json"))
LOG_DIR = Path(os.getenv("ML_OFFLOAD_LOG_DIR", DATA_DIR / "logs"))


# =============================================================================
# FastAPI Application
# =============================================================================

app = FastAPI(
    title="ML Offload Manager API",
    description="Unified API for ML model offloading across multiple backends",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware (if enabled via environment)
if os.getenv("ML_OFFLOAD_CORS_ENABLED", "false").lower() == "true":
    origins = os.getenv("ML_OFFLOAD_CORS_ORIGINS", "http://localhost:3000").split(",")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# =============================================================================
# Pydantic Models
# =============================================================================

class HealthResponse(BaseModel):
    status: str = Field(..., description="Service status")
    timestamp: str = Field(..., description="Current timestamp")
    version: str = Field(..., description="API version")
    services: Dict[str, bool] = Field(..., description="Dependent service status")


class BackendInfo(BaseModel):
    name: str = Field(..., description="Backend name (ollama, llamacpp, vllm, tgi)")
    status: str = Field(..., description="Backend status (active, inactive, error)")
    type: str = Field(..., description="Backend type (systemd, docker, api)")
    host: str = Field(..., description="Backend host")
    port: int = Field(..., description="Backend port")
    loaded_model: Optional[str] = Field(None, description="Currently loaded model")
    vram_usage_mb: Optional[int] = Field(None, description="VRAM usage in MB")


class ModelInfo(BaseModel):
    id: int
    name: str
    path: str
    format: str
    size_gb: float
    vram_estimate_gb: float
    architecture: str
    quantization: str
    parameter_count: str
    compatible_backends: List[str]
    last_scanned: str
    last_used: Optional[str] = None
    usage_count: int
    priority: str
    tags: List[str]


class LoadRequest(BaseModel):
    model_id: Optional[int] = Field(None, description="Model ID from registry")
    model_path: Optional[str] = Field(None, description="Direct model path")
    backend: str = Field(..., description="Backend to load on (ollama, llamacpp, etc.)")
    priority: str = Field("medium", description="Load priority (high, medium, low)")
    gpu_layers: Optional[int] = Field(None, description="Number of GPU layers (GGUF only)")


class UnloadRequest(BaseModel):
    backend: str = Field(..., description="Backend to unload from")


class SwitchRequest(BaseModel):
    backend: str = Field(..., description="Backend to switch model on")
    model_id: Optional[int] = Field(None, description="Model ID from registry")
    model_path: Optional[str] = Field(None, description="Direct model path")
    gpu_layers: Optional[int] = Field(None, description="Number of GPU layers (GGUF only)")


class StatusResponse(BaseModel):
    timestamp: str
    vram: Dict[str, Any]
    backends: List[BackendInfo]
    loaded_models: List[Dict[str, Any]]
    pending_queue: List[Dict[str, Any]]


class VRAMResponse(BaseModel):
    timestamp: str
    total_gb: float
    used_gb: float
    free_gb: float
    utilization_percent: float
    gpus: List[Dict[str, Any]]
    processes: List[Dict[str, Any]]


# =============================================================================
# Database Helper
# =============================================================================

def get_db_connection():
    """Get SQLite database connection"""
    if not DB_PATH.exists():
        raise HTTPException(status_code=503, detail="Registry database not found")
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn


def get_vram_state() -> Dict[str, Any]:
    """Get current VRAM state from state file"""
    if not STATE_FILE.exists():
        return {
            "total_gb": 0.0,
            "used_gb": 0.0,
            "free_gb": 0.0,
            "utilization_percent": 0.0,
            "gpus": [],
            "last_update": None
        }

    try:
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Error reading VRAM state: {e}", file=sys.stderr)
        return {}


# =============================================================================
# Backend Drivers (Stub - TODO: Implement in Phase 2)
# =============================================================================

class BackendDriver:
    """Base backend driver interface"""

    @staticmethod
    def get_backends() -> List[BackendInfo]:
        """Get list of available backends"""
        # TODO: Implement backend detection
        # For now, return hardcoded list
        backends = []

        # Check if Ollama is running
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "ollama.service"],
                capture_output=True,
                text=True,
                timeout=2
            )
            ollama_status = "active" if result.returncode == 0 else "inactive"
        except:
            ollama_status = "unknown"

        backends.append(BackendInfo(
            name="ollama",
            status=ollama_status,
            type="systemd",
            host="127.0.0.1",
            port=11434,
            loaded_model=None,
            vram_usage_mb=None
        ))

        # Check if llamacpp is running
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "llamacpp.service"],
                capture_output=True,
                text=True,
                timeout=2
            )
            llamacpp_status = "active" if result.returncode == 0 else "inactive"
        except:
            llamacpp_status = "unknown"

        backends.append(BackendInfo(
            name="llamacpp",
            status=llamacpp_status,
            type="systemd",
            host="127.0.0.1",
            port=8080,
            loaded_model=None,
            vram_usage_mb=None
        ))

        return backends

    @staticmethod
    def load_model(backend: str, model_path: str, **kwargs) -> bool:
        """Load model on backend"""
        # TODO: Implement in Phase 2
        raise HTTPException(status_code=501, detail="Model loading not yet implemented")

    @staticmethod
    def unload_model(backend: str) -> bool:
        """Unload model from backend"""
        # TODO: Implement in Phase 2
        raise HTTPException(status_code=501, detail="Model unloading not yet implemented")

    @staticmethod
    def switch_model(backend: str, model_path: str, **kwargs) -> bool:
        """Switch model on backend (hot-reload)"""
        # TODO: Implement in Phase 2
        raise HTTPException(status_code=501, detail="Model switching not yet implemented")


# =============================================================================
# API Endpoints
# =============================================================================

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    services = {
        "registry_db": DB_PATH.exists(),
        "vram_monitor": STATE_FILE.exists(),
        "models_path": MODELS_PATH.exists(),
    }

    return HealthResponse(
        status="healthy" if all(services.values()) else "degraded",
        timestamp=datetime.now().isoformat(),
        version="0.1.0",
        services=services
    )


@app.get("/backends", response_model=List[BackendInfo])
async def list_backends():
    """List all available ML backends"""
    return BackendDriver.get_backends()


@app.get("/models", response_model=List[ModelInfo])
async def list_models(
    format: Optional[str] = Query(None, description="Filter by format (GGUF, SafeTensors, etc.)"),
    backend: Optional[str] = Query(None, description="Filter by compatible backend"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of results")
):
    """List all models from registry"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        query = "SELECT * FROM models"
        params = []

        # Add filters
        filters = []
        if format:
            filters.append("format = ?")
            params.append(format)
        if backend:
            filters.append("compatible_backends LIKE ?")
            params.append(f"%{backend}%")

        if filters:
            query += " WHERE " + " AND ".join(filters)

        query += " ORDER BY name LIMIT ?"
        params.append(limit)

        cursor.execute(query, params)
        rows = cursor.fetchall()
        conn.close()

        models = []
        for row in rows:
            row_dict = dict(row)
            # Parse JSON fields
            row_dict["compatible_backends"] = json.loads(row_dict.get("compatible_backends", "[]"))
            row_dict["tags"] = json.loads(row_dict.get("tags", "[]"))
            models.append(ModelInfo(**row_dict))

        return models

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error querying models: {str(e)}")


@app.get("/models/{model_id}", response_model=ModelInfo)
async def get_model(model_id: int):
    """Get model details by ID"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM models WHERE id = ?", (model_id,))
        row = cursor.fetchone()
        conn.close()

        if not row:
            raise HTTPException(status_code=404, detail=f"Model {model_id} not found")

        row_dict = dict(row)
        row_dict["compatible_backends"] = json.loads(row_dict.get("compatible_backends", "[]"))
        row_dict["tags"] = json.loads(row_dict.get("tags", "[]"))
        return ModelInfo(**row_dict)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error querying model: {str(e)}")


@app.post("/models/scan")
async def trigger_model_scan(background_tasks: BackgroundTasks):
    """Trigger model registry scan"""
    def run_scan():
        try:
            subprocess.run(
                ["systemctl", "start", "ml-registry-scan.service"],
                check=True,
                timeout=5
            )
        except Exception as e:
            print(f"Error triggering scan: {e}", file=sys.stderr)

    background_tasks.add_task(run_scan)
    return {"status": "scan_triggered", "message": "Model registry scan started in background"}


@app.get("/status", response_model=StatusResponse)
async def get_status():
    """Get real-time system status"""
    vram_state = get_vram_state()
    backends = BackendDriver.get_backends()

    return StatusResponse(
        timestamp=datetime.now().isoformat(),
        vram={
            "total_gb": vram_state.get("total_vram_gb", 0.0),
            "used_gb": vram_state.get("used_vram_gb", 0.0),
            "free_gb": vram_state.get("free_vram_gb", 0.0),
            "utilization_percent": vram_state.get("utilization_percent", 0.0),
        },
        backends=backends,
        loaded_models=[],  # TODO: Query from backends
        pending_queue=[]   # TODO: Get from scheduler
    )


@app.get("/vram", response_model=VRAMResponse)
async def get_vram_details():
    """Get detailed VRAM information"""
    vram_state = get_vram_state()

    if not vram_state:
        raise HTTPException(status_code=503, detail="VRAM monitor not running")

    # Extract GPU processes
    processes = []
    for gpu in vram_state.get("gpus", []):
        for proc in gpu.get("processes", []):
            processes.append({
                "gpu_id": gpu["gpu_id"],
                "pid": proc["pid"],
                "name": proc["name"],
                "memory_mb": proc["memory_mb"]
            })

    return VRAMResponse(
        timestamp=vram_state.get("last_update", ""),
        total_gb=vram_state.get("total_vram_gb", 0.0),
        used_gb=vram_state.get("used_vram_gb", 0.0),
        free_gb=vram_state.get("free_vram_gb", 0.0),
        utilization_percent=vram_state.get("utilization_percent", 0.0),
        gpus=vram_state.get("gpus", []),
        processes=processes
    )


@app.post("/load")
async def load_model(request: LoadRequest):
    """Load model on backend"""
    # Validate request
    if not request.model_id and not request.model_path:
        raise HTTPException(status_code=400, detail="Either model_id or model_path required")

    # Get model path if model_id provided
    model_path = request.model_path
    if request.model_id:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT path FROM models WHERE id = ?", (request.model_id,))
            row = cursor.fetchone()
            conn.close()

            if not row:
                raise HTTPException(status_code=404, detail=f"Model {request.model_id} not found")

            model_path = row["path"]
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error querying model: {str(e)}")

    # Load model (TODO: Implement in Phase 2)
    try:
        BackendDriver.load_model(
            backend=request.backend,
            model_path=model_path,
            gpu_layers=request.gpu_layers
        )
        return {"status": "loaded", "model": model_path, "backend": request.backend}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error loading model: {str(e)}")


@app.post("/unload")
async def unload_model(request: UnloadRequest):
    """Unload model from backend"""
    try:
        BackendDriver.unload_model(backend=request.backend)
        return {"status": "unloaded", "backend": request.backend}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error unloading model: {str(e)}")


@app.post("/switch")
async def switch_model(request: SwitchRequest):
    """Switch model on backend (hot-reload)"""
    # Validate request
    if not request.model_id and not request.model_path:
        raise HTTPException(status_code=400, detail="Either model_id or model_path required")

    # Get model path if model_id provided
    model_path = request.model_path
    if request.model_id:
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT path FROM models WHERE id = ?", (request.model_id,))
            row = cursor.fetchone()
            conn.close()

            if not row:
                raise HTTPException(status_code=404, detail=f"Model {request.model_id} not found")

            model_path = row["path"]
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error querying model: {str(e)}")

    # Switch model (TODO: Implement in Phase 2)
    try:
        BackendDriver.switch_model(
            backend=request.backend,
            model_path=model_path,
            gpu_layers=request.gpu_layers
        )
        return {"status": "switched", "model": model_path, "backend": request.backend}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error switching model: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint - API information"""
    return {
        "name": "ML Offload Manager API",
        "version": "0.1.0",
        "docs": "/docs",
        "health": "/health",
        "endpoints": {
            "backends": "/backends",
            "models": "/models",
            "status": "/status",
            "vram": "/vram",
        }
    }


# =============================================================================
# Main Entry Point
# =============================================================================

if __name__ == "__main__":
    import uvicorn

    host = os.getenv("ML_OFFLOAD_HOST", "127.0.0.1")
    port = int(os.getenv("ML_OFFLOAD_PORT", "9000"))

    print(f"Starting ML Offload Manager API on {host}:{port}")
    print(f"Data directory: {DATA_DIR}")
    print(f"Models path: {MODELS_PATH}")
    print(f"Registry DB: {DB_PATH}")

    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info",
        access_log=False
    )
