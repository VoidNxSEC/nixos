#!/usr/bin/env bash
# ps-advanced.sh - Listagem avançada de processos com foco em recursos

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${CYAN}${BOLD}Usage:${NC} $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -c, --cpu       Sort by CPU usage (default)"
    echo "  -m, --mem       Sort by Memory usage"
    echo "  -i, --io        Sort by IO usage (requires iotop or pidstat)"
    echo "  -w, --wait      Sort by wait channel (shows blocking processes)"
    echo "  -n <num>        Show top N processes (default: 15)"
    echo "  -f, --full      Show full command line"
    echo "  -t, --tree      Show process tree (requires pstree)"
    echo "  -s <service>    Filter processes by service name"
    echo "  -u <user>       Filter processes by user"
    echo "  -h, --help      Show this help message"
}

SORT_BY="cpu"
NUM_TOP=15
FULL_CMD=false
SHOW_TREE=false
FILTER_SERVICE=""
FILTER_USER=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -c|--cpu) SORT_BY="cpu";;
        -m|--mem) SORT_BY="mem";;
        -i|--io) SORT_BY="io";;
        -w|--wait) SORT_BY="wait";;
        -n) NUM_TOP="$2"; shift;; 
        -f|--full) FULL_CMD=true;; 
        -t|--tree) SHOW_TREE=true;; 
        -s) FILTER_SERVICE="$2"; shift;; 
        -u) FILTER_USER="$2"; shift;; 
        -h|--help) show_help; exit 0;; 
        *) echo -e "${RED}Unknown option: $1${NC}"; show_help; exit 1;; 
    esac
    shift
fi

echo -e "${GREEN}=== ADVANCED PROCESS LISTING ===${NC}"

# Process tree
if $SHOW_TREE; then
    echo -e "\n${YELLOW}Process Tree:${NC}"
    if command -v pstree &> /dev/null; then
        pstree -Apl
    else
        echo -e "${RED}pstree not found. Please install it.${NC}"
    fi
fi

# Top processes
echo -e "\n${YELLOW}Top $NUM_TOP Processes (Sorted by $SORT_BY):${NC}"

PS_CMD="ps -eo pid,user,%cpu,%mem,vsz,rss,stat,start_time,wchan:20,comm,args"
SORT_OPT=""
FILTER_OPT=""

case "$SORT_BY" in
    cpu) SORT_OPT="-pcpu";;
    mem) SORT_OPT="-pmem";;
    wait) SORT_OPT="-wchan";;
    io)
        if command -v pidstat &> /dev/null; then
            echo -e "${BLUE}Note: IO sorting uses pidstat (snapshot).${NC}"
            pidstat -d 1 1 | head -n $((NUM_TOP + 4)) 
            exit 0
        else
            echo -e "${RED}pidstat not found. Falling back to CPU/Mem sort.${NC}"
            SORT_OPT="-pcpu"
        fi
        ;; 
esac

if [ ! -z "$FILTER_SERVICE" ]; then
    FILTER_OPT="-s $FILTER_SERVICE" # This is a conceptual filter, ps doesn't filter by service name directly
    echo -e "${YELLOW}Note: Service filtering is conceptual. Use 'grep' on the output.${NC}"
fi
if [ ! -z "$FILTER_USER" ]; then
    FILTER_OPT+=" -u $FILTER_USER"
fi

# Need a robust ps for sorting
if ! ps --sort=-%cpu > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: 'ps --sort' not supported. Falling back to basic ps.${NC}"
    ps -aux | head -n $((NUM_TOP + 1)) | awk '{print $1,$2,$3,$4,$11}' | column -t
else
    # Busybox ps doesn't have --sort, but basic ps works
    if $FULL_CMD; then
        ps -eo pid,user,%cpu,%mem,vsz,rss,stat,start_time,wchan:20,cmd --sort="$SORT_OPT" | head -n $((NUM_TOP + 1))
    else
        ps -eo pid,user,%cpu,%mem,vsz,rss,stat,start_time,wchan:20,comm --sort="$SORT_OPT" | head -n $((NUM_TOP + 1))
    fi
fi

# Highlight potential issues (high CPU/Mem/Wait)
echo -e "\n${YELLOW}Potential Issues (High CPU/Mem):${NC}"
if ! ps --sort=-%cpu > /dev/null 2>&1; then
    # Fallback for busybox
    ps -aux | awk '$3 > 20 || $4 > 10 {print "'$RED' "$0" '$NC'"}' | head -n 5
else
    ps -eo pid,user,%cpu,%mem,comm,args --sort=-%cpu | awk 'NR>1 && $3 > 20 {print "'$RED' "$0" '$NC'"}' | head -n 3
    ps -eo pid,user,%cpu,%mem,comm,args --sort=-%mem | awk 'NR>1 && $4 > 10 {print "'$MAGENTA' "$0" '$NC'"}' | head -n 3
fi
