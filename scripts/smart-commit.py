#!/usr/bin/env python3
import subprocess
import json
import urllib.request
import urllib.error
import sys
import os
import re
import argparse
from collections import Counter

# Configuration - llama.cpp TURBO
# Ensure your local LLM is running
API_URL = os.environ.get("LLAMACPP_URL", "http://127.0.0.1:8080") + "/v1/chat/completions"
MODEL_NAME = "unsloth_DeepSeek-R1-0528-Qwen3-8B-GGUF_DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
MAX_DIFF_SIZE = 6000 

def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}\n{e.stderr}")
        sys.exit(1)

def get_staged_files():
    # Returns list of staged files
    return run_command("git diff --name-only --cached").splitlines()

def scope_guard():
    files = get_staged_files()
    if not files:
        print("❌ Nada no stage! Use 'git add <arquivo>' antes de rodar o script.")
        print("   (A proteção automática contra 'git add -A' foi ativada para sua segurança)")
        sys.exit(1)

    # Analyze root directories
    roots = [f.split('/')[0] for f in files if '/' in f]
    root_counts = Counter(roots)

    # If more than 1 distinct root directory
    if len(root_counts) > 1:
        print("\n⚠️  ALERTA DE MIXED CONTEXT DETECTADO ⚠️")
        print("Você está tentando commitar mudanças em escopos muito distintos:")
        for root, count in root_counts.items():
            print(f"  - {root}/ ({count} arquivos)")

        print("\nIsso confunde a IA e gera commits sujos.")
        choice = input("Deseja continuar mesmo assim? [y/N]: ").lower()
        if choice != 'y':
            print("Abortando. Separe seus commits.")
            sys.exit(0)

def get_staged_diff():
    return run_command("git diff --cached")

def get_branch_name():
    return run_command("git rev-parse --abbrev-ref HEAD")

def extract_issue_id(branch_name):
    match = re.search(r'([a-zA-Z]+-\d+|\d+)', branch_name)
    if match:
        return match.group(1)
    return None

def generate_commit_message(diff, hint=None, issue_id=None):
    system_prompt = """You are a Senior SRE and Code Maintainer.
    Your task is to generate a semantic git commit message based on the provided diff.

    CRITICAL RULES:
    1. Format: <type>(<scope>): <subject>
    2. NO HALLUCINATIONS: Do not mention tools unless they explicitly appear in the code diff.
    3. IMPERATIVE MOOD: Start subject with a Verb (Add, Fix, Remove, Refactor).
    4. IF AMBIGUOUS: Rely on the User Hint provided below to understand the intent.
    5. Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
    6. Output strictly JSON: {"type": "...", "scope": "...", "subject": "...", "body": "...", "semver_bump": "..."}
    """

    user_context = "Analyze the following git diff.\n"

    if hint:
        user_context += f"\nUSER INTENT HINT: The user says this change is about: '{hint}'. USE THIS TO GUIDE THE CONTEXT.\n"

    if issue_id:
        user_context += f"Refers to issue ID: #{issue_id}.\n"

    user_context += f"\nDiff Content:\n{diff[:MAX_DIFF_SIZE]}"

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_context}
        ],
        "temperature": 0.1, 
        "response_format": {"type": "json_object"}
    }

    try:
        req = urllib.request.Request(API_URL, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result['choices'][0]['message']['content']
    except urllib.error.URLError as e:
        print(f"Error connecting to LLM API at {API_URL}: {e}")
        sys.exit(1)

def verify_pipeline():
    print("🛡️  Running Pre-Commit Verification Pipeline...")
    if os.path.exists("./scripts/pipeline-check.sh"):
        try:
            subprocess.run(["./scripts/pipeline-check.sh"], check=True)
            print("✅ Pipeline verification passed.")
        except subprocess.CalledProcessError:
            print("❌ Pipeline verification failed. Fix issues before committing.")
            sys.exit(1)
    else:
        print("ℹ️  Skipping pipeline check (script not found).")

def main():
    parser = argparse.ArgumentParser(description='AI Commit Generator')
    parser.add_argument('hint', nargs='?', help='Dica de contexto (ex: "refactor templates")', default=None)
    args = parser.parse_args()

    if not os.path.exists(".git"):
        print("Error: Not a git repository.")
        sys.exit(1)

    # 1. Pipeline Check
    verify_pipeline()

    # 2. Scope Guard (Protection against mixed staging)
    scope_guard()

    print("🔍 Analyzing repository state...")
    diff = get_staged_diff()

    branch = get_branch_name()
    issue_id = extract_issue_id(branch)

    print(f"🤖 Generating intelligent commit message... (Hint: {args.hint if args.hint else 'None'})")
    response_json = generate_commit_message(diff, args.hint, issue_id)

    try:
        data = json.loads(response_json)
        
        # Extract fields safely
        raw_subject = data.get('subject', 'Update code')
        body = data.get('body', '')
        commit_type = data.get('type', 'chore')
        scope = data.get('scope', None) 
        semver = data.get('semver_bump', 'patch')

        # Logic to build the header correctly
        if scope and str(scope).lower() not in ['none', 'null', '']:
            header = f"{commit_type}({scope}): {raw_subject}"
        else:
            header = f"{commit_type}: {raw_subject}"

        full_message = f"{header}\n\n{body}"
        
        if issue_id:
            full_message += f"\n\nRefs: #{issue_id}"

        print("\n" + "="*50)
        print(f"SUGGESTED COMMIT ({commit_type}) [Bump: {semver}]")
        print("="*50)
        print(full_message)
        print("="*50 + "\n")

        confirm = input("Do you want to commit with this message? [Y/n/e(dit)]: ").lower()

        if confirm in ['y', 'yes', '']:
            run_command(f'git commit -m "{full_message}"')
            print("✅ Committed successfully.")
        elif confirm == 'e':
            with open(".git/COMMIT_EDITMSG", "w") as f:
                f.write(full_message)
            editor = os.environ.get('EDITOR', 'vim')
            os.system(f"{editor} .git/COMMIT_EDITMSG")
            os.system("git commit -F .git/COMMIT_EDITMSG")
            print("✅ Committed with edited message.")
        else:
            print("❌ Commit cancelled.")

    except json.JSONDecodeError:
        print("Error parsing LLM response. Raw output:")
        print(response_json)

if __name__ == "__main__":
    main()