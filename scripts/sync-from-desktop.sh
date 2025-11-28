#!/usr/bin/env bash
# ============================================================================
# Sync from Desktop to Laptop
# ============================================================================
# Usage: sync-from-desktop [directory] [options]
# Example: sync-from-desktop projects
#          sync-from-desktop Documents --dry-run

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REMOTE_HOST="desktop"
REMOTE_USER="cypher"
REMOTE_BASE="/home/cypher"
LOCAL_BASE="$HOME"

# Default rsync options
RSYNC_OPTS=(
    -avz
    --progress
    --partial
    --delete
    --exclude='.git/'
    --exclude='node_modules/'
    --exclude='.cache/'
    --exclude='target/'
    --exclude='__pycache__/'
    --exclude='*.pyc'
    --exclude='.venv/'
    --exclude='.env'
)

# Function to display usage
usage() {
    echo -e "${BLUE}Sync from Desktop Script${NC}"
    echo ""
    echo "Usage: $0 [directory] [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run       Show what would be transferred without doing it"
    echo "  --no-delete     Don't delete files on destination"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 projects"
    echo "  $0 Documents --dry-run"
    exit 0
}

# Parse arguments
DRY_RUN=false
DELETE_MODE="--delete"
DIR_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-delete)
            DELETE_MODE=""
            shift
            ;;
        *)
            if [[ -z "$DIR_NAME" ]]; then
                DIR_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Validate directory
if [[ -z "$DIR_NAME" ]]; then
    echo -e "${RED}Error: No directory specified${NC}"
    usage
fi

# Build paths
SOURCE="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BASE}/${DIR_NAME}"
DEST="${LOCAL_BASE}/${DIR_NAME}"

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
echo -e "${GREEN}Syncing from Desktop${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Source:      ${YELLOW}$SOURCE/${NC}"
echo -e "Destination: ${YELLOW}$DEST/${NC}"
echo -e "Options:     ${RSYNC_OPTS[*]}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if remote host is reachable
if ! ssh -o ConnectTimeout=5 "$REMOTE_HOST" "echo 'Connection OK'" &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to $REMOTE_HOST${NC}"
    exit 1
fi

# Check if source exists on desktop
if ! ssh "$REMOTE_HOST" "[ -d $REMOTE_BASE/$DIR_NAME ]"; then
    echo -e "${RED}Error: Directory $DIR_NAME does not exist on desktop${NC}"
    exit 1
fi

# Create local directory if needed
mkdir -p "$DEST"

# Execute rsync
echo -e "${GREEN}Starting sync...${NC}"
rsync "${RSYNC_OPTS[@]}" "$SOURCE/" "$DEST/" || {
    echo -e "${RED}Sync failed!${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}✓ Sync completed successfully!${NC}"

if [[ "$DRY_RUN" = false ]]; then
    echo ""
    echo -e "${BLUE}Local directory size:${NC}"
    du -sh "$DEST"
fi
