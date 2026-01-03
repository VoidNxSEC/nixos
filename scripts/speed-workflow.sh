#!/usr/bin/env bash

# ==============================================================================
# SPEED WORKFLOW CONTROLLER
# Modular script for path verification, flake updates, and AI-assisted commits.
# ==============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FLAKE_FILE="/etc/nixos/flake.nix"
LOG_FILE="/tmp/speed_workflow.log"

# ==============================================================================
# MODULE 1: PATH VERIFICATION
# ==============================================================================
check_local_inputs() {
    echo -e "${BLUE}[1/3] Verifying local flake inputs...${NC}"

    # Extract paths starting with git+file:// from flake.nix
    # We look for lines like: url = "git+file:///home/kernelcore/dev/low-level/..."
    local_paths=$(grep -o 'git+file://[^"]*' "$FLAKE_FILE" | sed 's/git+file:\/\///')

    if [ -z "$local_paths" ]; then
        echo -e "${YELLOW}No local git+file inputs found in flake.nix. Skipping check.${NC}"
        return 0
    fi

    local error_count=0

    for path in $local_paths; do
        if [ -d "$path" ]; then
            echo -e "  ${GREEN}✓ Found:${NC} $path"
        else
            echo -e "  ${RED}✗ MISSING:${NC} $path"
            ((error_count++))
        fi
    done

    if [ "$error_count" -gt 0 ]; then
        echo -e "${RED}Critical: $error_count local project path(s) are missing.${NC}"
        echo -e "${YELLOW}Please verify you have moved your projects to ~/dev/low-level/${NC}"
        exit 1
    fi
    echo -e "${GREEN}All local inputs verified.${NC}\n"
}

# ==============================================================================
# MODULE 2: FLAKE OPERATIONS
# ==============================================================================
update_flake() {
    echo -e "${BLUE}[2/3] Updating Flake Lockfile...${NC}"

    # We use 'nix flake update' to update all inputs (including local ones)
    # This ensures the lockfile points to the latest commit hashes of your local repos
    if nix flake update --commit-lock-file >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓ Flake updated successfully.${NC}"
    else
        echo -e "${RED}✗ Flake update failed.${NC}"
        echo -e "${YELLOW}Check log: $LOG_FILE${NC}"
        tail -n 10 "$LOG_FILE"
        exit 1
    fi
    echo ""
}

# ==============================================================================
# MODULE 3: AI GIT COMMIT
# ==============================================================================
ai_smart_commit() {
    echo -e "${BLUE}[3/3] Processing Git Commit...${NC}"

    # Check if there are changes to commit
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}No changes to commit.${NC}"
        exit 0
    fi

    git add .

    # Check for Gemini CLI or similar AI tool
    local commit_msg=""

    if command -v gemini &> /dev/null; then
        echo -e "  ${YELLOW}🤖 Generating AI commit message...${NC}"
        # Capture diff (limit size to avoid token limits)
        diff_context=$(git diff --cached | head -n 300)

        # Simple prompt for the AI
        prompt="Write a concise, conventional commit message (type: subject) for these changes. Do not use markdown blocks. Changes: $diff_context"

        # Try to get message from Gemini
        commit_msg=$(gemini "$prompt" 2>/dev/null)
    fi

    # Fallback if AI failed or returned empty string
    if [ -z "$commit_msg" ] || [[ "$commit_msg" == *"Error"* ]]; then
        echo -e "  ${YELLOW}⚠ AI unavailable or failed. Using standard timestamp.${NC}"
        commit_msg="chore(system): bulk update workflow $(date +'%Y-%m-%d %H:%M')"
    else
         echo -e "  ${GREEN}🤖 AI Suggestion:${NC} $commit_msg"
    fi

    # Commit
    if git commit -m "$commit_msg"; then
        echo -e "${GREEN}✓ Changes committed.${NC}"

        # Optional: Print status
        echo -e "\n${BLUE}Current Status:${NC}"
        git log -1 --oneline
    else
        echo -e "${RED}✗ Git commit failed.${NC}"
        exit 1
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================
echo -e "${BLUE}=== Speed Workflow Initiated ===${NC}"
echo -e "Log file: $LOG_FILE\n"

check_local_inputs
update_flake
ai_smart_commit

echo -e "\n${GREEN}=== Workflow Complete ===${NC}"
