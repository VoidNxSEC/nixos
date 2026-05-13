import os
import re
import json
import csv
import time
import math
from pathlib import Path
from datetime import datetime, timedelta

# --- CONFIGURATION ---
TARGET_DIRS = ["Projects", "."]  # Scan Projects/ and Root
OUTPUT_JSON = "project_inventory.json"
OUTPUT_CSV = "project_inventory.csv"

# Keywords that boost "Potential Value" score
HOT_TOPICS = [
    "llm", "ai", "agent", "nix", "nixos", "rust", "wasm", "security", 
    "encryption", "docker", "kubernetes", "react", "nextjs", "tauri"
]

class ProjectAnalyzer:
    def __init__(self, root_path):
        self.root_path = Path(root_path)
        
    def analyze_directory(self, dir_path):
        """Main analysis pipeline for a single project directory."""
        if not dir_path.is_dir() or dir_path.name.startswith("."):
            return None

        # 1. Basic Metadata
        stats = self._get_fs_stats(dir_path)
        git_info = self._get_git_info(dir_path)
        
        # 2. Tech Stack Identification
        tech_stack = self._identify_tech(dir_path)
        
        # 3. Readme Analysis
        readme_data = self._analyze_readme(dir_path)
        
        # 4. Scoring
        complexity = self._calculate_complexity(stats, tech_stack, readme_data)
        relevance = self._calculate_relevance(git_info, readme_data, tech_stack)
        
        return {
            "name": dir_path.name,
            "path": str(dir_path),
            "location": "Projects/" if "Projects" in str(dir_path) else "Root",
            "technologies": list(tech_stack["langs"]),
            "frameworks": list(tech_stack["frameworks"]),
            "last_updated": git_info["date"] or stats["last_modified"],
            "days_inactive": git_info["days_since"] if git_info["days_since"] is not None else stats["days_since"],
            "complexity_score": round(complexity, 1),
            "relevance_score": round(relevance, 1),
            "summary": readme_data["summary"],
            "action_recommendation": self._recommend_action(relevance, complexity, git_info["days_since"])
        }

    def _get_fs_stats(self, path):
        """Get file system statistics."""
        try:
            files = list(path.rglob("*"))
            file_count = len([f for f in files if f.is_file() and not ".git" in str(f)])
            
            # Last modified (fallback if no git)
            mtime = path.stat().st_mtime
            dt = datetime.fromtimestamp(mtime)
            days_since = (datetime.now() - dt).days
            
            return {"file_count": file_count, "last_modified": dt.strftime("%Y-%m-%d"), "days_since": days_since}
        except:
            return {"file_count": 0, "last_modified": "N/A", "days_since": 999}

    def _get_git_info(self, path):
        """Extract git metadata."""
        git_dir = path / ".git"
        if not git_dir.exists():
            return {"date": None, "days_since": None, "commits": 0}
        
        try:
            # Get last commit date
            import subprocess
            cmd = ["git", "log", "-1", "--format=%ct"]
            ts = subprocess.check_output(cmd, cwd=path, stderr=subprocess.DEVNULL).decode().strip()
            dt = datetime.fromtimestamp(int(ts))
            days = (datetime.now() - dt).days
            
            # Get roughly number of commits (activity density)
            cmd_count = ["git", "rev-list", "--count", "HEAD"]
            count = subprocess.check_output(cmd_count, cwd=path, stderr=subprocess.DEVNULL).decode().strip()
            
            return {"date": dt.strftime("%Y-%m-%d"), "days_since": days, "commits": int(count)}
        except:
            return {"date": None, "days_since": None, "commits": 0}

    def _identify_tech(self, path):
        """Identify languages and frameworks based on file signatures."""
        langs = set()
        frameworks = set()
        
        # Signatures
        if (path / "Cargo.toml").exists():
            langs.add("Rust")
        if (path / "package.json").exists():
            langs.add("JavaScript/Node")
            # Peek inside for frameworks
            try:
                with open(path / "package.json") as f:
                    content = f.read().lower()
                    if "react" in content: frameworks.add("React")
                    if "next" in content: frameworks.add("Next.js")
                    if "svelte" in content: frameworks.add("Svelte")
                    if "vue" in content: frameworks.add("Vue")
                    if "tauri" in content: frameworks.add("Tauri")
                    if "express" in content: frameworks.add("Express")
            except: pass
            
        if (path / "flake.nix").exists():
            langs.add("Nix")
        if (path / "requirements.txt").exists() or (path / "pyproject.toml").exists() or list(path.glob("*.py")):
            langs.add("Python")
        if (path / "go.mod").exists():
            langs.add("Go")
        if (path / "docker-compose.yml").exists() or (path / "Dockerfile").exists():
            frameworks.add("Docker")
            
        return {"langs": langs, "frameworks": frameworks}

    def _analyze_readme(self, path):
        """Extract summary and complexity signals from README."""
        readme_candidates = ["README.md", "readme.md", "README.txt", "README"]
        content = ""
        summary = "No documentation found."
        
        for r in readme_candidates:
            if (path / r).exists():
                try:
                    with open(path / r, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        lines = content.split('\n')
                        # Heuristic: Find first non-header non-empty line
                        for line in lines[:10]:
                            clean = line.strip()
                            if clean and not clean.startswith("#") and not clean.startswith("[!"):
                                summary = clean[:100] + "..."
                                break
                    break
                except: pass
        
        return {
            "length": len(content),
            "summary": summary,
            "has_images": "![" in content or "<img" in content,
            "has_code": "```" in content
        }

    def _calculate_complexity(self, stats, tech, readme):
        """Calculate a complexity score (0-100)."""
        score = 0
        
        # Codebase size
        score += math.log(max(stats["file_count"], 1)) * 5
        
        # Tech Stack weight
        if "Rust" in tech["langs"]: score += 15
        if "Nix" in tech["langs"]: score += 10
        if "Docker" in tech["frameworks"]: score += 5
        
        # Documentation depth
        score += min(readme["length"] / 500, 20) # Up to 20 pts for detailed readme
        
        return min(score, 100)

    def _calculate_relevance(self, git, readme, tech):
        """Calculate relevance/potential score (0-100)."""
        score = 50 # Base score
        
        # Recency (High penalty for zombies)
        days = git["days_since"]
        if days is not None:
            if days < 7: score += 20
            elif days < 30: score += 10
            elif days > 365: score -= 20
            elif days > 700: score -= 40
        
        # Hot Topics
        all_tech = " ".join(tech["langs"]) + " " + " ".join(tech["frameworks"]) + " " + readme["summary"]
        for topic in HOT_TOPICS:
            if topic.lower() in all_tech.lower():
                score += 5
                
        # Documentation penalty
        if readme["length"] < 50: score -= 15
        
        return max(0, min(score, 100))

    def _recommend_action(self, relevance, complexity, days_inactive):
        if days_inactive is not None and days_inactive > 365:
            return "ARCHIVE/DELETE"
        if relevance > 70:
            return "KEEP & INVEST"
        if relevance > 40:
            return "REVIEW"
        return "AUDIT"

def run_scan():
    all_projects = []
    
    # 1. Scan Projects/ subdirectories
    projects_dir = Path("Projects")
    if projects_dir.exists():
        for d in projects_dir.iterdir():
            if d.is_dir():
                analyzer = ProjectAnalyzer(".")
                result = analyzer.analyze_directory(d)
                if result: all_projects.append(result)

    # 2. Scan Root Directories (excluding preserved system ones)
    ignored_root = [".gemini", "Projects", "_ARCHIVE_2025_12_10", ".git", "node_modules"]
    root = Path(".")
    for d in root.iterdir():
        if d.is_dir() and d.name not in ignored_root:
            analyzer = ProjectAnalyzer(".")
            result = analyzer.analyze_directory(d)
            if result: all_projects.append(result)

    # Sort by Relevance
    all_projects.sort(key=lambda x: x["relevance_score"], reverse=True)

    # Output JSON
    with open(OUTPUT_JSON, "w") as f:
        json.dump(all_projects, f, indent=2)
        
    # Print Report
    print(f"{'PROJECT':<30} | {'LOC':<8} | {'TECH':<25} | {'UPDATED':<10} | {'SCORE':<5} | {'ACTION'}")
    print("-" * 110)
    for p in all_projects:
        tech_str = ", ".join(p["technologies"][:2])
        if not tech_str: tech_str = "None"
        date_str = str(p["last_updated"])
        print(f"{p['name']:<30} | {p['location']:<8} | {tech_str:<25} | {date_str:<10} | {p['relevance_score']:<5} | {p['action_recommendation']}")

    print(f"\nFull report saved to {OUTPUT_JSON}")

if __name__ == "__main__":
    run_scan()
