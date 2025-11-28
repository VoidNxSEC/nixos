#!/usr/bin/env bash
# ============================================================================
# Sync from Laptop to Desktop
# ============================================================================
# Usage: sync-to-desktop [directory] [options]
# Example: sync-to-desktop ~/projects
#          sync-to-desktop ~/Documents --dry-run

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REMOTE_HOST="desktop"
REMOTE_USER="cypher"
REMOTE_BASE="/home/cypher"

# Default rsync options
RSYNC_OPTS=(
    -avz                    # Archive, verbose, compress
    --progress              # Show progress
    --partial               # Keep partial transfers
    --delete                # Delete files on destination that don't exist on source
    --exclude='.git/'       # Exclude git repos
    --exclude='node_modules/' # Exclude node modules
    --exclude='.cache/'     # Exclude cache
    --exclude='target/'     # Exclude Rust target
    --exclude='__pycache__/' # Exclude Python cache
    --exclude='*.pyc'       # Exclude compiled Python
    --exclude='.venv/'      # Exclude Python venv
    --exclude='.env'        # Exclude env files
)

# Function to display usage
usage() {
    echo -e "${BLUE}Sync to Desktop Script${NC}"
    echo ""
    echo "Usage: $0 [directory] [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run       Show what would be transferred without doing it"
    echo "  --delete-after  Delete files after transfer (safer)"
    echo "  --no-delete     Don't delete files on destination"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ~/projects"
    echo "  $0 ~/Documents --dry-run"
    echo "  $0 /etc/nixos --no-delete"
    exit 0
}

# Parse arguments
DRY_RUN=false
DELETE_MODE="--delete"
SOURCE_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --delete-after)
            DELETE_MODE="--delete-after"
            shift
            ;;
        --no-delete)
            DELETE_MODE=""
            shift
            ;;
        *)
            if [[ -z "$SOURCE_DIR" ]]; then
                SOURCE_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Validate source directory
if [[ -z "$SOURCE_DIR" ]]; then
    echo -e "${RED}Error: No source directory specified${NC}"
    usage
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo -e "${RED}Error: Directory $SOURCE_DIR does not exist${NC}"
    exit 1
fi

# Resolve to absolute path
SOURCE_DIR=$(readlink -f "$SOURCE_DIR")
DIR_NAME=$(basename "$SOURCE_DIR")
PARENT_DIR=$(dirname "$SOURCE_DIR")

# Build destination path
DEST="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BASE}/${DIR_NAME}"

# Add delete mode if set
if [[ -n "$DELETE_MODE" ]]; then
    RSYNC_OPTS+=("$DELETE_MODE")
fi

# Add dry-run if requested
if [[ "$DRY_RUN" = true ]]; then
    RSYNC_OPTS+=(--dry-run)
    echo -e "${YELLOW}DRY RUN MODE - No files will be transferred${NC}"
fi

# Display sync info
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Syncing to Desktop${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Source:      ${YELLOW}$SOURCE_DIR/${NC}"
echo -e "Destination: ${YELLOW}$DEST${NC}"
echo -e "Options:     ${RSYNC_OPTS[*]}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if remote host is reachable
if ! ssh -o ConnectTimeout=5 "$REMOTE_HOST" "echo 'Connection OK'" &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to $REMOTE_HOST${NC}"
    echo "Make sure SSH is configured and the host is reachable"
    exit 1
fi

# Create destination directory if it doesn't exist
ssh "$REMOTE_HOST" "mkdir -p $REMOTE_BASE/$DIR_NAME"

# Execute rsync
echo -e "${GREEN}Starting sync...${NC}"
rsync "${RSYNC_OPTS[@]}" "$SOURCE_DIR/" "$DEST/" || {
    echo -e "${RED}Sync failed!${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}✓ Sync completed successfully!${NC}"

# Show summary if not dry-run
if [[ "$DRY_RUN" = false ]]; then
    echo ""
    echo -e "${BLUE}Remote directory size:${NC}"
    ssh "$REMOTE_HOST" "du -sh $REMOTE_BASE/$DIR_NAME"
fi
