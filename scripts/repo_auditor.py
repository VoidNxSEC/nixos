import os
import json
import subprocess
from pathlib import Path
from datetime import datetime

ROOT_DIR = "."

def get_git_info(path):
    try:
        # Check if git repo
        if not (path / ".git").exists():
            return {"is_git": False, "last_commit": "N/A", "commit_count_1y": 0}
        
        # Last commit date
        last_commit = subprocess.check_output(
            ["git", "log", "-1", "--format=%cd", "--date=short"], 
            cwd=path, stderr=subprocess.DEVNULL
        ).decode().strip()
        
        # Commits in last year
        count = subprocess.check_output(
            ["git", "rev-list", "--count", "--since=1.year.ago", "HEAD"], 
            cwd=path, stderr=subprocess.DEVNULL
        ).decode().strip()
        
        return {"is_git": True, "last_commit": last_commit, "commit_count_1y": int(count) if count else 0}
    except:
        return {"is_git": False, "last_commit": "Error", "commit_count_1y": 0}

def analyze_tech_stack(path):
    stack = []
    deps_count = 0
    complexity_score = 0
    
    if (path / "flake.nix").exists():
        stack.append("Nix")
        complexity_score += 2
        
    if (path / "Cargo.toml").exists():
        stack.append("Rust")
        complexity_score += 2
        try:
            with open(path / "Cargo.toml") as f:
                content = f.read()
                deps_count += content.count("version =") # Very rough heuristic
        except: pass

    if (path / "package.json").exists():
        stack.append("Node/JS")
        complexity_score += 1
        try:
            with open(path / "package.json") as f:
                data = json.load(f)
                deps = data.get("dependencies", {})
                dev_deps = data.get("devDependencies", {})
                deps_count += len(deps) + len(dev_deps)
        except: pass

    if (path / "requirements.txt").exists():
        stack.append("Python")
        try:
            with open(path / "requirements.txt") as f:
                deps_count += len([l for l in f.readlines() if l.strip() and not l.startswith('#')])
        except: pass
    elif (path / "pyproject.toml").exists():
         stack.append("Python")
    
    if (path / "go.mod").exists():
        stack.append("Go")
        complexity_score += 1

    if (path / "docker-compose.yml").exists():
        stack.append("Docker")
        complexity_score += 1

    return {
        "stack": ", ".join(stack), 
        "deps_count": deps_count, 
        "complexity": complexity_score
    }

def get_readme_summary(path):
    readme_candidates = ["README.md", "readme.md", "README.txt", "README"]
    for r in readme_candidates:
        fpath = path / r
        if fpath.exists():
            try:
                with open(fpath, encoding="utf-8", errors="ignore") as f:
                    lines = [l.strip() for l in f.readlines() if l.strip()]
                    # Return first useful line (skipping title if it matches dirname)
                    if lines:
                        return lines[0][:100]
            except:
                pass
    return "No README"

def audit_repos():
    results = []
    subdirs = [d for d in Path(ROOT_DIR).iterdir() if d.is_dir() and not d.name.startswith(".")]
    
    for d in subdirs:
        # Skip hidden folders or unrelated
        if d.name in ["node_modules", "target", "build", "dist"]:
            continue
            
        git_info = get_git_info(d)
        tech_info = analyze_tech_stack(d)
        summary = get_readme_summary(d)
        
        # Calculate a relevance score (simple heuristic)
        # Recent activity + complexity + documentation
        score = 0
        if git_info["is_git"]:
            score += 1
        if git_info["commit_count_1y"] > 10:
            score += 2
        if git_info["commit_count_1y"] > 50:
            score += 2
        if "No README" not in summary:
            score += 1
        if tech_info["stack"]:
            score += 1
            
        results.append({
            "name": d.name,
            "tech": tech_info["stack"],
            "deps": tech_info["deps_count"],
            "last_commit": git_info["last_commit"],
            "commits_1y": git_info["commit_count_1y"],
            "readme": summary,
            "score": score
        })
        
    # Sort by score descending
    results.sort(key=lambda x: x["score"], reverse=True)
    
    # Print CSV-like structure for easy LLM parsing
    print(f"{'Name':<30} | {'Tech':<25} | {'Deps':<5} | {'Last Commit':<12} | {'Commits':<8} | {'Score':<5} | {'Summary'}")
    print("-" * 130)
    for r in results:
        print(f"{r['name']:<30} | {r['tech']:<25} | {r['deps']:<5} | {r['last_commit']:<12} | {r['commits_1y']:<8} | {r['score']:<5} | {r['readme']}")

if __name__ == "__main__":
    audit_repos()
