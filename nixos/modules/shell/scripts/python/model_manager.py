#!/usr/bin/env python3
"""
Model Manager - Gerenciador unificado de modelos AI
Suporta: Ollama, HuggingFace, modelos locais

Comandos:
  model-search <query>              : Busca modelos HF/Ollama
  model-install <model>             : Instala modelo
  model-list                        : Lista modelos instalados
  model-remove <model>              : Remove modelo
  model-cache-clean                 : Limpa cache
  model-info <model>                : Informações do modelo
"""

import os
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Model:
    """Representação de um modelo AI"""
    name: str
    source: str  # ollama, huggingface, local
    size: Optional[int] = None
    path: Optional[str] = None
    installed_at: Optional[str] = None
    last_used: Optional[str] = None


class ModelManager:
    """Gerenciador central de modelos AI"""

    def __init__(self):
        self.cache_dir = Path.home() / ".cache" / "ai-models"
        self.config_file = self.cache_dir / "models.json"
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.models = self._load_models()

    def _load_models(self) -> Dict[str, Model]:
        """Carrega lista de modelos do cache"""
        if not self.config_file.exists():
            return {}

        try:
            with open(self.config_file, 'r') as f:
                data = json.load(f)
                return {
                    name: Model(**model_data)
                    for name, model_data in data.items()
                }
        except Exception as e:
            print(f"Warning: Failed to load models cache: {e}", file=sys.stderr)
            return {}

    def _save_models(self):
        """Salva lista de modelos"""
        try:
            data = {
                name: model.__dict__
                for name, model in self.models.items()
            }
            with open(self.config_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Warning: Failed to save models cache: {e}", file=sys.stderr)

    # ──────────────────────────────────────────────────────
    # OLLAMA OPERATIONS
    # ──────────────────────────────────────────────────────

    def ollama_list(self) -> List[Model]:
        """Lista modelos Ollama instalados"""
        try:
            result = subprocess.run(
                ["ollama", "list"],
                capture_output=True,
                text=True,
                check=True
            )

            models = []
            for line in result.stdout.split('\n')[1:]:  # Skip header
                if not line.strip():
                    continue

                parts = line.split()
                if len(parts) >= 3:
                    name = parts[0]
                    size_str = parts[2]

                    # Parse size (e.g., "4.7 GB")
                    try:
                        size_val = float(size_str.split()[0])
                        size_unit = size_str.split()[1]
                        size_bytes = int(size_val * (1024**3 if size_unit == "GB" else 1024**2))
                    except:
                        size_bytes = None

                    models.append(Model(
                        name=name,
                        source="ollama",
                        size=size_bytes
                    ))

            return models

        except subprocess.CalledProcessError:
            return []
        except FileNotFoundError:
            print("✗ Ollama not found. Install with: nix-env -iA nixpkgs.ollama-cuda", file=sys.stderr)
            return []

    def ollama_pull(self, model_name: str) -> bool:
        """Baixa modelo do Ollama"""
        try:
            print(f"📥 Downloading {model_name} via Ollama...")
            result = subprocess.run(
                ["ollama", "pull", model_name],
                check=True
            )

            if result.returncode == 0:
                # Adiciona ao cache
                self.models[model_name] = Model(
                    name=model_name,
                    source="ollama",
                    installed_at=datetime.now().isoformat()
                )
                self._save_models()
                print(f"✓ {model_name} installed successfully")
                return True

            return False

        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to download {model_name}: {e}", file=sys.stderr)
            return False

    def ollama_remove(self, model_name: str) -> bool:
        """Remove modelo do Ollama"""
        try:
            print(f"🗑️  Removing {model_name}...")
            result = subprocess.run(
                ["ollama", "rm", model_name],
                check=True
            )

            if result.returncode == 0:
                if model_name in self.models:
                    del self.models[model_name]
                    self._save_models()
                print(f"✓ {model_name} removed")
                return True

            return False

        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to remove {model_name}: {e}", file=sys.stderr)
            return False

    # ──────────────────────────────────────────────────────
    # HUGGINGFACE OPERATIONS
    # ──────────────────────────────────────────────────────

    def huggingface_search(self, query: str, limit: int = 10) -> List[Dict]:
        """Busca modelos no Hugging Face"""
        try:
            # Usando API simples com curl
            result = subprocess.run(
                [
                    "curl", "-s",
                    f"https://huggingface.co/api/models?search={query}&limit={limit}"
                ],
                capture_output=True,
                text=True,
                check=True
            )

            models = json.loads(result.stdout)
            return models

        except Exception as e:
            print(f"✗ Failed to search HuggingFace: {e}", file=sys.stderr)
            return []

    def huggingface_download(self, repo_id: str, cache_dir: Optional[str] = None) -> bool:
        """Baixa modelo do HuggingFace usando git-lfs"""
        try:
            cache_dir = cache_dir or str(self.cache_dir / "huggingface")
            Path(cache_dir).mkdir(parents=True, exist_ok=True)

            model_dir = Path(cache_dir) / repo_id.replace("/", "_")

            if model_dir.exists():
                print(f"✓ Model already exists: {model_dir}")
                return True

            print(f"📥 Downloading {repo_id} from HuggingFace...")
            print(f"   Target: {model_dir}")

            # Clone with git-lfs
            result = subprocess.run(
                [
                    "git", "clone",
                    f"https://huggingface.co/{repo_id}",
                    str(model_dir)
                ],
                check=True
            )

            if result.returncode == 0:
                self.models[repo_id] = Model(
                    name=repo_id,
                    source="huggingface",
                    path=str(model_dir),
                    installed_at=datetime.now().isoformat()
                )
                self._save_models()
                print(f"✓ {repo_id} downloaded to {model_dir}")
                return True

            return False

        except subprocess.CalledProcessError as e:
            print(f"✗ Failed to download {repo_id}: {e}", file=sys.stderr)
            return False

    # ──────────────────────────────────────────────────────
    # GENERAL OPERATIONS
    # ──────────────────────────────────────────────────────

    def list_all(self):
        """Lista todos modelos conhecidos"""
        print("╔════════════════════════════════════════╗")
        print("║         Installed Models              ║")
        print("╚════════════════════════════════════════╝")
        print()

        # Ollama models
        ollama_models = self.ollama_list()
        if ollama_models:
            print("📦 Ollama Models:")
            for model in ollama_models:
                size_str = f"{model.size / 1024**3:.1f} GB" if model.size else "Unknown"
                print(f"  - {model.name} ({size_str})")
            print()

        # Cached models
        if self.models:
            print("💾 Cached Models:")
            for name, model in self.models.items():
                if model.source != "ollama":  # Evita duplicatas
                    print(f"  - {name} ({model.source})")
            print()

        if not ollama_models and not self.models:
            print("No models installed.")
            print()

    def search(self, query: str):
        """Busca modelos em múltiplas fontes"""
        print(f"🔍 Searching for '{query}'...\n")

        # Search HuggingFace
        print("📚 HuggingFace Models:")
        hf_models = self.huggingface_search(query, limit=5)
        if hf_models:
            for model in hf_models[:5]:
                name = model.get('modelId', 'Unknown')
                downloads = model.get('downloads', 0)
                print(f"  - {name} ({downloads:,} downloads)")
        else:
            print("  No results")
        print()

        # Search Ollama (via library website conhecida)
        print("🦙 Ollama Models:")
        print(f"  Search at: https://ollama.com/library?search={query}")
        print()

    def cache_info(self):
        """Mostra informações do cache"""
        total_size = 0

        if self.cache_dir.exists():
            for item in self.cache_dir.rglob('*'):
                if item.is_file():
                    total_size += item.stat().st_size

        print("╔════════════════════════════════════════╗")
        print("║         Cache Information             ║")
        print("╚════════════════════════════════════════╝")
        print()
        print(f"Cache directory: {self.cache_dir}")
        print(f"Total size: {total_size / 1024**3:.2f} GB")
        print(f"Models tracked: {len(self.models)}")
        print()

    def cache_clean(self):
        """Limpa cache de modelos"""
        import shutil

        print("🗑️  Cleaning cache...")

        if self.cache_dir.exists():
            try:
                shutil.rmtree(self.cache_dir)
                self.cache_dir.mkdir(parents=True, exist_ok=True)
                self.models = {}
                self._save_models()
                print("✓ Cache cleaned")
            except Exception as e:
                print(f"✗ Failed to clean cache: {e}", file=sys.stderr)
        else:
            print("✓ Cache already empty")


def main():
    """Entry point"""
    manager = ModelManager()

    if len(sys.argv) < 2:
        print("Usage: model-manager <command> [args]")
        print("\nCommands:")
        print("  search <query>        - Search models")
        print("  install <model>       - Install model")
        print("  list                  - List installed models")
        print("  remove <model>        - Remove model")
        print("  cache-info            - Show cache info")
        print("  cache-clean           - Clean cache")
        sys.exit(1)

    command = sys.argv[1]

    if command == "search":
        if len(sys.argv) < 3:
            print("Usage: model-manager search <query>")
            sys.exit(1)
        manager.search(sys.argv[2])

    elif command == "install":
        if len(sys.argv) < 3:
            print("Usage: model-manager install <model>")
            sys.exit(1)

        model_name = sys.argv[2]

        # Detecta source (ollama vs huggingface)
        if "/" in model_name:  # HuggingFace format (org/repo)
            manager.huggingface_download(model_name)
        else:  # Ollama format
            manager.ollama_pull(model_name)

    elif command == "list":
        manager.list_all()

    elif command == "remove":
        if len(sys.argv) < 3:
            print("Usage: model-manager remove <model>")
            sys.exit(1)
        manager.ollama_remove(sys.argv[2])

    elif command == "cache-info":
        manager.cache_info()

    elif command == "cache-clean":
        manager.cache_clean()

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
