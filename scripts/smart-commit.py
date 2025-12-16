#!/usr/bin/env python3
import subprocess
import json
import urllib.request
import urllib.error
import sys
import os
import re

# Configuration - llama.cpp TURBO
API_URL = os.environ.get("LLAMACPP_URL", "http://127.0.0.1:8080") + "/v1/chat/completions"
MODEL_NAME = "default"
MAX_DIFF_SIZE = 12000  # Characters

def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}\n{e.stderr}")
        sys.exit(1)

def get_staged_diff():
    # Check for staged changes
    if run_command("git diff --cached --quiet; echo $?") == "0":
        print("No staged changes found. Staging all changes...")
        run_command("git add -A")
    
    return run_command("git diff --cached")

def get_branch_name():
    return run_command("git rev-parse --abbrev-ref HEAD")

def extract_issue_id(branch_name):
    # Matches feature/123-desc, fix/PROJ-456-desc, etc.
    match = re.search(r'([a-zA-Z]+-\d+|\d+)', branch_name)
    if match:
        return match.group(1)
    return None

def generate_commit_message(diff, issue_id=None):
    system_prompt = """You are an expert DevOps engineer and code reviewer. 
    Your task is to generate a semantic git commit message based on the provided diff. 
    
    Rules:
    1. Format: <type>(<scope>): <subject>
    2. Body: clearly explain WHY the changes were made, not just WHAT.
    3. Footer: specific issue references or breaking changes.
    4. Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
    5. Suggest a Semantic Versioning bump (Major, Minor, Patch) based on the changes.
    6. Output strictly JSON format: {\"subject\": \"...\", \"body\": \"...\", \"type\": \"...\", \"semver_bump\": \"...\"}
    """
    
    user_context = f"Analyze the following git diff."
    if issue_id:
        user_context += f" The changes are related to issue ID: #{issue_id}."
    
    user_context += f"\n\nDiff Content (truncated if too large):\n{diff[:MAX_DIFF_SIZE]}"

    payload = {
        "model": MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_context}
        ],
        "temperature": 0.2,
        "response_format": {"type": "json_object"} 
    }

    try:
        req = urllib.request.Request(API_URL, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result['choices'][0]['message']['content']
    except urllib.error.URLError as e:
        print(f"Error connecting to LLM API at {API_URL}: {e}")
        print("Ensure llama.cpp TURBO is running (llama-start).")
        sys.exit(1)

def verify_pipeline():
    print("🛡️  Running Pre-Commit Verification Pipeline...")
    try:
        # Run the pipeline check script
        subprocess.run(["./scripts/pipeline-check.sh"], check=True)
        print("✅ Pipeline verification passed.")
    except subprocess.CalledProcessError:
        print("❌ Pipeline verification failed. Fix issues before committing.")
        sys.exit(1)
    except FileNotFoundError:
         print("⚠️  Warning: scripts/pipeline-check.sh not found. Skipping validation.")

def main():
    if not os.path.exists(".git"):
        print("Error: Not a git repository.")
        sys.exit(1)
        
    # Run Verification
    verify_pipeline()

    print("🔍 Analyzing repository state...")
    diff = get_staged_diff()
    if not diff:
        print("No changes to commit even after staging.")
        sys.exit(0)

    branch = get_branch_name()
    issue_id = extract_issue_id(branch)
    if issue_id:
        print(f"🎫 Detected Issue ID from branch: {issue_id}")

    print("🤖 Generating intelligent commit message...")
    response_json = generate_commit_message(diff, issue_id)
    
    try:
        data = json.loads(response_json)
        subject = data.get('subject', 'Update code')
        body = data.get('body', '')
        commit_type = data.get('type', 'chore')
        semver = data.get('semver_bump', 'patch')
        
        # Construct final message
        full_message = f"{subject}\n\n{body}"
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
            # Create a temp file for editing
            with open(".git/COMMIT_EDITMSG", "w") as f:
                f.write(full_message)
            os.system(f"vim .git/COMMIT_EDITMSG") # Assume vim or use $EDITOR
            # Commit using the file
            os.system("git commit -F .git/COMMIT_EDITMSG")
            print("✅ Committed with edited message.")
        else:
            print("❌ Commit cancelled.")

    except json.JSONDecodeError:
        print("Error parsing LLM response. Raw output:")
        print(response_json)

if __name__ == "__main__":
    main()
