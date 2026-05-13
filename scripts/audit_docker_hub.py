import os
from pathlib import Path

ROOT_DIR = "docker-hub"

def find_stacks():
    stacks = []
    
    # 1. Check Root
    if (Path(ROOT_DIR) / "docker-compose.yml").exists():
        stacks.append({
            "name": "docker-hub-root",
            "path": ROOT_DIR,
            "type": "Root Orchestrator",
            "desc": "Main entry point (check docker-compose.yml)"
        })

    # 2. Check ml-clusters
    ml_clusters = Path(ROOT_DIR) / "ml-clusters"
    if ml_clusters.exists():
        if (ml_clusters / "docker-compose.yml").exists() or (ml_clusters / "docker-compose.yml.deprecated").exists():
             stacks.append({
                "name": "ml-clusters-core",
                "path": str(ml_clusters),
                "type": "ML Infrastructure",
                "desc": "Core ML Cluster (ComfyUI, Ollama, API)"
            })
            
        # 3. Check Kits (The real treasure trove)
        kits_dir = ml_clusters / "kits"
        if kits_dir.exists():
            for kit in kits_dir.iterdir():
                if kit.is_dir():
                    # Determine type
                    kit_type = "Kit/Stack"
                    desc = "Standard Kit"
                    
                    # Look for clues
                    files = [f.name for f in kit.iterdir()]
                    if "docker-compose.yml" in files:
                        desc = "Ready-to-run Docker Compose stack"
                    elif "Dockerfile" in files:
                        desc = "Docker build context"
                    
                    # Try to read README if exists
                    readme_path = kit / "README.md"
                    if readme_path.exists():
                        try:
                            with open(readme_path, 'r') as f:
                                line = f.readline().strip()
                                if line: desc = line[:80]
                        except: pass

                    stacks.append({
                        "name": f"kit/{kit.name}",
                        "path": str(kit),
                        "type": kit_type,
                        "desc": desc
                    })

    # 4. Check gpu-jup-queries
    gpu_jup = Path(ROOT_DIR) / "gpu-jup-queries"
    if gpu_jup.exists():
        stacks.append({
            "name": "gpu-jup-queries",
            "path": str(gpu_jup),
            "type": "Experimentation",
            "desc": "Jupyter Notebooks & NVIDIA Queries"
        })

    return stacks

def print_report(stacks):
    print(f"{'Stack Name':<25} | {'Type':<20} | {'Location':<40} | {'Description'}")
    print("-" * 130)
    for s in stacks:
        print(f"{s['name']:<25} | {s['type']:<20} | {s['path']:<40} | {s['desc']}")

if __name__ == "__main__":
    stacks = find_stacks()
    print_report(stacks)
