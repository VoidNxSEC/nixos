#!/usr/bin/env bash
set -u # Removed -e to continue on errors
set -o pipefail

# Configuration
BACKUP_DIR="/etc/nixos/backups/ollama_cleanup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

# Check arguments
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE ACTIVE: No files will be modified."
else
    echo "⚠️  LIVE MODE: Files will be modified."
    mkdir -p "$BACKUP_DIR"
    echo "📁 Backups will be saved to: $BACKUP_DIR"
fi

# List of files to process
FILES=(
    "/etc/nixos/hosts/kernelcore/configuration.nix"
    "/etc/nixos/modules/security/packages.nix"
    "/etc/nixos/hosts/kernelcore/home/home.nix"
    "/etc/nixos/modules/shell/aliases/ai/default.nix"
    "/etc/nixos/hosts/kernelcore/configurations-template.nix"
    "/etc/nixos/hosts/kernelcore/home/glassmorphism/agent-hub.nix"
    "/etc/nixos/modules/programs/phantom.nix"
    "/etc/nixos/modules/ml/infrastructure/storage.nix"
    "/etc/nixos/modules/network/proxy/tailscale-services.nix"
    "/etc/nixos/modules/network/security/firewall-zones.nix"
    "/etc/nixos/modules/ml/orchestration/registry/database.nix"
    "/etc/nixos/hosts/kernelcore/home/aliases/nixos-aliases.nix"
    "/etc/nixos/modules/system/ml-gpu-users.nix"
    "/etc/nixos/modules/services/gpu-orchestration.nix"
    "/etc/nixos/modules/shell/aliases/ai/ollama.nix"
    "/etc/nixos/hosts/kernelcore/home/aliases/aliases.sh"
    "/etc/nixos/hosts/kernelcore/home/aliases/nx.sh"
    "/etc/nixos/hosts/kernelcore/home/aliases/ai-compose-stack.sh"
    "/etc/nixos/hosts/kernelcore/home/aliases/ai-ml-stack.sh"
    "/etc/nixos/hosts/kernelcore/home/aliases/litellm_runtime_manager.sh"
    "/etc/nixos/hosts/kernelcore/home/aliases/gpu-management.sh"
    "/etc/nixos/hosts/kernelcore/home/aliases/multimodal.sh"
    "/etc/nixos/modules/ml/services/default.nix"
    "/etc/nixos/modules/network/proxy/nginx-tailscale.nix"
    "/etc/nixos/hosts/workstation/configuration.nix"
    "/etc/nixos/scripts/fix-sudo.nix"
    "/etc/nixos/scripts/desktop-cfg2.nix"
    "/etc/nixos/scripts/desktop-config-clean.nix"
    "/etc/nixos/scripts/desktop-config-backup.nix"
    "/etc/nixos/scripts/fix-sudo3.nix"
    "/etc/nixos/scripts/fix-sudo2.nix"
    "/etc/nixos/scripts/desktop-cfg.nix"
    "/etc/nixos/scripts/clean-sudo.nix"
)

echo "Starting analysis..."
echo "----------------------------------------------------------------"

TOTAL_REMOVED_LINES=0
MODIFIED_FILES_COUNT=0

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        # Count lines that match "ollama" (case insensitive)
        MATCH_COUNT=$(grep -c -i "ollama" "$file" || true)

        if [ "$MATCH_COUNT" -gt 0 ]; then
            echo "📄 File: $file"
            echo "   Found $MATCH_COUNT lines containing 'ollama'."

            if [ "$DRY_RUN" = true ]; then
                echo "   [DRY RUN] Would backup to $BACKUP_DIR/$(basename "$file")"
                echo "   [DRY RUN] Would remove $MATCH_COUNT lines."
                # Preview matching lines (first 3)
                echo "   [PREVIEW] First 3 matches:"
                grep -i "ollama" "$file" | head -n 3 | sed 's/^/     > /'
            else
                # Create backup
                cp "$file" "$BACKUP_DIR/$(basename "$file")"
                
                # Perform removal using grep -v
                # We use a temporary file to ensure atomic operation
                grep -v -i "ollama" "$file" > "${file}.tmp"
                
                # Verify the operation (basic check)
                ORIG_LINES=$(wc -l < "$file")
                NEW_LINES=$(wc -l < "${file}.tmp")
                ACTUAL_REMOVED=$((ORIG_LINES - NEW_LINES))
                
                if [ "$ACTUAL_REMOVED" -eq "$MATCH_COUNT" ]; then
                    mv "${file}.tmp" "$file"
                    echo "   ✅ Successfully removed $ACTUAL_REMOVED lines."
                    ((TOTAL_REMOVED_LINES+=ACTUAL_REMOVED))
                    ((MODIFIED_FILES_COUNT++))
                else
                    echo "   ❌ ERROR: Line count mismatch. Expected removal: $MATCH_COUNT, Actual: $ACTUAL_REMOVED. Aborting change for this file."
                    rm "${file}.tmp"
                fi
            fi
            echo "----------------------------------------------------------------"
        else
            # Only verbose if requested, keeping it quiet for clean files
            :
        fi
    else
        echo "⚠️  Warning: File not found: $file"
    fi
done

if [ "$DRY_RUN" = true ]; then
    echo "🔍 Dry run complete."
else
    echo "🎉 Cleanup complete."
    echo "   Files modified: $MODIFIED_FILES_COUNT"
    echo "   Total lines removed: $TOTAL_REMOVED_LINES"
    echo "   Backups stored in: $BACKUP_DIR"
fi
