#!/usr/bin/env bash
# ============================================
# Container Image Builder Script
# ============================================
# Purpose: Build and load Docker images from Nix
# Usage: ./build-container-images.sh [image-name|all]
# ============================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(dirname "$SCRIPT_DIR")"

# Available images
declare -a IMAGES=(
    "image-app"
    "image-cuda-runtime"
    "image-ollama"
    "image-python-ml"
    "image-nodejs-dev"
    "image-go-dev"
    "image-postgres-dev"
    "image-nginx-proxy"
    "image-redis"
)

# Helper functions
print_header() {
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║          Container Image Builder (Nix)                 ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Build and load image
build_image() {
    local image_name="$1"

    print_info "Building ${BOLD}${image_name}${NC}..."

    # Build the image
    if ! nix build "${FLAKE_DIR}#${image_name}" --no-link; then
        print_error "Failed to build ${image_name}"
        return 1
    fi

    # Get the result path
    local result_path
    result_path=$(nix build "${FLAKE_DIR}#${image_name}" --no-link --print-out-paths)

    print_info "Loading image into Docker..."

    # Load into Docker
    if docker load < "$result_path"; then
        print_success "Successfully built and loaded ${BOLD}${image_name}${NC}"
        return 0
    else
        print_error "Failed to load ${image_name} into Docker"
        return 1
    fi
}

# List available images
list_images() {
    echo -e "${CYAN}Available images:${NC}"
    for image in "${IMAGES[@]}"; do
        echo "  - ${image}"
    done
}

# Build all images
build_all() {
    local failed=0
    local total=${#IMAGES[@]}
    local count=0

    print_info "Building ${total} images..."
    echo ""

    for image in "${IMAGES[@]}"; do
        count=$((count + 1))
        echo -e "${CYAN}[${count}/${total}]${NC} Processing ${BOLD}${image}${NC}"

        if build_image "$image"; then
            echo ""
        else
            failed=$((failed + 1))
            echo ""
        fi
    done

    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}Successful:${NC} $((total - failed))/${total}"

    if [ $failed -gt 0 ]; then
        echo -e "${RED}Failed:${NC} ${failed}/${total}"
        return 1
    fi

    return 0
}

# Show usage
show_help() {
    cat <<EOF
${BOLD}Usage:${NC} $(basename "$0") [OPTIONS] [IMAGE]

${BOLD}Options:${NC}
  -h, --help          Show this help message
  -l, --list          List available images
  -a, --all           Build all images

${BOLD}Arguments:${NC}
  IMAGE               Name of the image to build (e.g., image-ollama)

${BOLD}Examples:${NC}
  $(basename "$0") image-ollama                    # Build Ollama image
  $(basename "$0") --all                           # Build all images
  $(basename "$0") --list                          # List available images

${BOLD}Available images:${NC}
EOF
    for image in "${IMAGES[@]}"; do
        echo "  - ${image}"
    done
}

# Main
main() {
    print_header

    # Parse arguments
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--list)
            list_images
            exit 0
            ;;
        -a|--all)
            build_all
            exit $?
            ;;
        "")
            print_warning "No image specified"
            echo ""
            show_help
            exit 1
            ;;
        *)
            # Check if image exists in array
            if [[ " ${IMAGES[*]} " =~ " ${1} " ]]; then
                build_image "$1"
                exit $?
            else
                print_error "Unknown image: $1"
                echo ""
                list_images
                exit 1
            fi
            ;;
    esac
}

main "$@"
