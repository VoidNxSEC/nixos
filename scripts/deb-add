#!/usr/bin/env bash

# deb-add: Automated script to add .deb packages to NixOS configuration
# Usage: deb-add --name PACKAGE_NAME [OPTIONS]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIXOS_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_DIR="$NIXOS_DIR/modules/packages/deb-packages/packages"
STORAGE_DIR="$NIXOS_DIR/modules/packages/deb-packages/storage"

# Default values
NAME=""
DEB_FILE=""
URL=""
METHOD="auto"
STORAGE_TYPE="url"
SANDBOX="true"
AUDIT="true"
BLOCK_HARDWARE=()
MEMORY=""
CPU=""
TASKS=""
DESCRIPTION=""
HOMEPAGE=""
LICENSE=""
VERBOSE="false"

# Print colored message
print_msg() {
    local color=$1
    local msg=$2
    echo -e "${color}${msg}${NC}"
}

# Print usage
usage() {
    cat <<EOF
Usage: deb-add --name PACKAGE_NAME [OPTIONS]

Add a .deb package to your NixOS configuration declaratively.

Required:
  --name NAME               Package name (will be used as executable name)

Source (one required):
  --deb FILE                Path to local .deb file
  --url URL                 URL to download .deb file

Integration:
  --method METHOD           Integration method: auto, fhs, or native (default: auto)
  --storage TYPE            Storage type: url or git-lfs (default: url)

Sandbox:
  --no-sandbox              Disable sandboxing (not recommended)
  --block-gpu               Block GPU access
  --block-audio             Block audio access
  --block-usb               Block USB access
  --block-camera            Block camera access
  --block-bluetooth         Block bluetooth access
  --memory LIMIT            Memory limit (e.g., 2G, 512M)
  --cpu PERCENT             CPU quota percentage (0-100)
  --tasks NUMBER            Maximum number of tasks/threads

Audit:
  --no-audit                Disable audit logging
  --audit-level LEVEL       Audit level: minimal, standard, verbose (default: standard)

Metadata:
  --description TEXT        Package description
  --homepage URL            Package homepage
  --license LICENSE         Package license

Other:
  --verbose                 Verbose output
  --help                    Show this help message

Examples:
  # Add package from URL
  deb-add --name my-tool --url https://example.com/my-tool.deb

  # Add package from local file with Git LFS
  deb-add --name my-tool --deb ./my-tool.deb --storage git-lfs

  # Add with security restrictions
  deb-add --name untrusted-app \\
          --url https://example.com/app.deb \\
          --block-gpu --block-audio \\
          --memory 1G --cpu 25

  # Add development tool with relaxed restrictions
  deb-add --name dev-tool \\
          --deb ./dev-tool.deb \\
          --no-sandbox \\
          --description "Development tool"
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            NAME="$2"
            shift 2
            ;;
        --deb)
            DEB_FILE="$2"
            shift 2
            ;;
        --url)
            URL="$2"
            STORAGE_TYPE="url"
            shift 2
            ;;
        --method)
            METHOD="$2"
            shift 2
            ;;
        --storage)
            STORAGE_TYPE="$2"
            shift 2
            ;;
        --no-sandbox)
            SANDBOX="false"
            shift
            ;;
        --block-gpu)
            BLOCK_HARDWARE+=("\"gpu\"")
            shift
            ;;
        --block-audio)
            BLOCK_HARDWARE+=("\"audio\"")
            shift
            ;;
        --block-usb)
            BLOCK_HARDWARE+=("\"usb\"")
            shift
            ;;
        --block-camera)
            BLOCK_HARDWARE+=("\"camera\"")
            shift
            ;;
        --block-bluetooth)
            BLOCK_HARDWARE+=("\"bluetooth\"")
            shift
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cpu)
            CPU="$2"
            shift 2
            ;;
        --tasks)
            TASKS="$2"
            shift 2
            ;;
        --no-audit)
            AUDIT="false"
            shift
            ;;
        --audit-level)
            AUDIT_LEVEL="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --homepage)
            HOMEPAGE="$2"
            shift 2
            ;;
        --license)
            LICENSE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        --help)
            usage
            ;;
        *)
            print_msg "$RED" "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$NAME" ]]; then
    print_msg "$RED" "Error: --name is required"
    exit 1
fi

if [[ -z "$DEB_FILE" ]] && [[ -z "$URL" ]]; then
    print_msg "$RED" "Error: Either --deb or --url is required"
    exit 1
fi

if [[ -n "$DEB_FILE" ]] && [[ -n "$URL" ]]; then
    print_msg "$RED" "Error: Cannot specify both --deb and --url"
    exit 1
fi

# Validate method
if [[ ! "$METHOD" =~ ^(auto|fhs|native)$ ]]; then
    print_msg "$RED" "Error: Invalid method '$METHOD'. Must be: auto, fhs, or native"
    exit 1
fi

# Validate storage type
if [[ ! "$STORAGE_TYPE" =~ ^(url|git-lfs)$ ]]; then
    print_msg "$RED" "Error: Invalid storage type '$STORAGE_TYPE'. Must be: url or git-lfs"
    exit 1
fi

print_msg "$BLUE" "==================================="
print_msg "$BLUE" "  .deb Package Installer for NixOS"
print_msg "$BLUE" "==================================="
echo ""

# Handle local file
if [[ -n "$DEB_FILE" ]]; then
    if [[ ! -f "$DEB_FILE" ]]; then
        print_msg "$RED" "Error: File not found: $DEB_FILE"
        exit 1
    fi

    DEB_FILE="$(realpath "$DEB_FILE")"
    print_msg "$GREEN" "✓ Found .deb file: $DEB_FILE"

    if [[ "$STORAGE_TYPE" == "git-lfs" ]]; then
        print_msg "$YELLOW" "→ Copying to storage directory..."
        mkdir -p "$STORAGE_DIR"
        cp "$DEB_FILE" "$STORAGE_DIR/$NAME.deb"
        DEB_FILE="$STORAGE_DIR/$NAME.deb"
        print_msg "$GREEN" "✓ Copied to: $DEB_FILE"
    fi
fi

# Calculate SHA256
print_msg "$YELLOW" "→ Calculating SHA256 hash..."
if [[ -n "$DEB_FILE" ]]; then
    SHA256=$(nix-prefetch-url "file://$DEB_FILE" 2>/dev/null)
elif [[ -n "$URL" ]]; then
    SHA256=$(nix-prefetch-url "$URL" 2>/dev/null)
fi
print_msg "$GREEN" "✓ SHA256: $SHA256"

# Build hardware block array
HARDWARE_ARRAY=""
if [[ ${#BLOCK_HARDWARE[@]} -gt 0 ]]; then
    HARDWARE_ARRAY="[ $(IFS=' '; echo "${BLOCK_HARDWARE[*]}") ]"
else
    HARDWARE_ARRAY="[ ]"
fi

# Build resource limits
RESOURCE_LIMITS=""
if [[ -n "$MEMORY" ]] || [[ -n "$CPU" ]] || [[ -n "$TASKS" ]]; then
    RESOURCE_LIMITS="resourceLimits = {"
    [[ -n "$MEMORY" ]] && RESOURCE_LIMITS="$RESOURCE_LIMITS\n        memory = \"$MEMORY\";"
    [[ -n "$CPU" ]] && RESOURCE_LIMITS="$RESOURCE_LIMITS\n        cpu = $CPU;"
    [[ -n "$TASKS" ]] && RESOURCE_LIMITS="$RESOURCE_LIMITS\n        tasks = $TASKS;"
    RESOURCE_LIMITS="$RESOURCE_LIMITS\n      };"
else
    RESOURCE_LIMITS="resourceLimits = {};"
fi

# Build source configuration
if [[ "$STORAGE_TYPE" == "git-lfs" ]]; then
    SOURCE_CONFIG="path = ../storage/$NAME.deb;"
else
    SOURCE_CONFIG="url = \"$URL\";"
fi

# Generate configuration file
print_msg "$YELLOW" "→ Generating configuration..."

CONFIG_FILE="$PACKAGES_DIR/$NAME.nix"

cat > "$CONFIG_FILE" <<EOF
# Generated by deb-add on $(date -Iseconds)
# Package: $NAME
${DESCRIPTION:+# Description: $DESCRIPTION}
${HOMEPAGE:+# Homepage: $HOMEPAGE}
${LICENSE:+# License: $LICENSE}

{
  $NAME = {
    enable = true;
    method = "$METHOD";

    source = {
      $SOURCE_CONFIG
      sha256 = "$SHA256";
    };

    sandbox = {
      enable = $SANDBOX;
      allowedPaths = [ ];
      blockHardware = $HARDWARE_ARRAY;
      $RESOURCE_LIMITS
    };

    audit = {
      enable = $AUDIT;
      logLevel = "${AUDIT_LEVEL:-standard}";
    };

    wrapper = {
      name = "$NAME";
      extraArgs = [ ];
      environmentVariables = {};
    };

    meta = {
      description = "${DESCRIPTION:-$NAME}";
      ${HOMEPAGE:+homepage = \"$HOMEPAGE\";}
      ${LICENSE:+license = \"$LICENSE\";}
    };
  };
}
EOF

print_msg "$GREEN" "✓ Configuration saved to: $CONFIG_FILE"

# Summary
echo ""
print_msg "$BLUE" "==================================="
print_msg "$BLUE" "  Configuration Summary"
print_msg "$BLUE" "==================================="
echo "Package name:     $NAME"
echo "Method:           $METHOD"
echo "Storage:          $STORAGE_TYPE"
echo "Sandbox:          $SANDBOX"
echo "Audit:            $AUDIT"
[[ ${#BLOCK_HARDWARE[@]} -gt 0 ]] && echo "Blocked hardware: ${BLOCK_HARDWARE[*]}"
[[ -n "$MEMORY" ]] && echo "Memory limit:     $MEMORY"
[[ -n "$CPU" ]] && echo "CPU limit:        $CPU%"
echo ""

# Next steps
print_msg "$YELLOW" "Next steps:"
echo "1. Review configuration: $CONFIG_FILE"
echo "2. Import in your NixOS configuration"
echo "3. Run: nix flake check"
echo "4. Run: sudo nixos-rebuild switch"
echo ""

# Git LFS reminder
if [[ "$STORAGE_TYPE" == "git-lfs" ]]; then
    print_msg "$YELLOW" "Git LFS reminder:"
    echo "  git lfs track '*.deb'"
    echo "  git add $CONFIG_FILE"
    echo "  git add $DEB_FILE"
    echo "  git commit -m 'Add $NAME package'"
    echo ""
fi

print_msg "$GREEN" "✓ Package configuration created successfully!"
