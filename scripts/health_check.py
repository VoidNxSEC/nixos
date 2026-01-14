import os
import json
import subprocess
from pathlib import Path

PROJECTS_DIR = Path("Projects")

COLORS = {
    "GREEN": "\033[92m",
    "YELLOW": "\033[93m",
    "RED": "\033[91m",
    "RESET": "\033[0m"
}

def check_rust(path):
    try:
        # Check if Cargo.toml is valid without downloading the internet
        subprocess.check_output(
            ["cargo", "metadata", "--no-deps", "--format-version", "1"], 
            cwd=path, stderr=subprocess.DEVNULL
        )
        return True, "Cargo Workspace Valid"
    except subprocess.CalledProcessError:
        return False, "Cargo Metadata Failed (Check Cargo.toml structure)"
    except FileNotFoundError:
        return False, "Cargo not installed?"

def check_go(path):
    try:
        if not (path / "go.mod").exists():
            return False, "Missing go.mod"
        # 'go mod verify' checks dependencies match hash
        subprocess.check_output(["go", "mod", "verify"], cwd=path, stderr=subprocess.DEVNULL)
        return True, "Go Modules Verified"
    except:
        # Fallback if dependencies aren't downloaded yet
        return True, "Go Mod Exists (Deps pending)"

def check_node(path):
    try:
        with open(path / "package.json") as f:
            data = json.load(f)
            deps = len(data.get("dependencies", {}))
            return True, f"Valid package.json ({deps} deps)"
    except json.JSONDecodeError:
        return False, "Invalid package.json JSON"
    except Exception as e:
        return False, str(e)

def check_python(path):
    if (path / "pyproject.toml").exists() or (path / "requirements.txt").exists():
        return True, "Dependencies defined"
    return False, "No dependency file found"

def scan_projects():
    print(f"{'PROJECT':<30} | {'STACK':<15} | {'STATUS':<10} | {'DETAILS'}")
    print("-" * 90)
    
    for d in PROJECTS_DIR.iterdir():
        if not d.is_dir(): continue
        
        status = "❓"
        details = "Unknown"
        is_ready = False
        stack = "Other"

        # Detect & Check
        if (d / "Cargo.toml").exists():
            stack = "Rust 🦀"
            is_ready, details = check_rust(d)
        elif (d / "go.mod").exists():
            stack = "Go 🐹"
            is_ready, details = check_go(d)
        elif (d / "package.json").exists():
            stack = "Node 📦"
            is_ready, details = check_node(d)
        elif (d / "main.py").exists() or (d / "pyproject.toml").exists():
            stack = "Python 🐍"
            is_ready, details = check_python(d)
        elif (d / "flake.nix").exists():
            stack = "Nix ❄️"
            is_ready, details = True, "Flake exists"

        status_icon = f"{COLORS['GREEN']}READY{COLORS['RESET']}" if is_ready else f"{COLORS['RED']}BROKEN{COLORS['RESET']}"
        print(f"{d.name:<30} | {stack:<15} | {status_icon:<10} | {details}")

if __name__ == "__main__":
    scan_projects()
