#!/usr/bin/env bash
# ============================================
# Docker Inspect to Nix Converter
# ============================================
# Purpose: Inspect a running Docker container and generate Nix expression
# Usage: ./docker-inspect-to-nix.sh <container-name>
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

# Check if container name provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error:${NC} No container name provided"
    echo "Usage: $0 <container-name>"
    exit 1
fi

CONTAINER="$1"
OUTPUT_FILE="${2:-${CONTAINER}.nix}"

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error:${NC} Docker not found"
    exit 1
fi

# Check if container exists
if ! docker inspect "$CONTAINER" &> /dev/null; then
    echo -e "${RED}Error:${NC} Container '$CONTAINER' not found"
    echo ""
    echo "Available containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    exit 1
fi

print_header() {
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║          Docker to Nix Converter                        ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Extract container info
print_header
print_info "Inspecting container: ${BOLD}${CONTAINER}${NC}"

# Get container details
IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER")
PORTS=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}' "$CONTAINER")
VOLUMES=$(docker inspect --format='{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' "$CONTAINER")
ENV_VARS=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER")
WORKDIR=$(docker inspect --format='{{.Config.WorkingDir}}' "$CONTAINER")
CMD=$(docker inspect --format='{{range .Config.Cmd}}{{.}} {{end}}' "$CONTAINER")
ENTRYPOINT=$(docker inspect --format='{{range .Config.Entrypoint}}{{.}} {{end}}' "$CONTAINER")
USER=$(docker inspect --format='{{.Config.User}}' "$CONTAINER")

print_success "Container info extracted"
echo ""

# Generate Nix expression
print_info "Generating Nix expression..."

cat > "$OUTPUT_FILE" <<EOF
# Auto-generated from Docker container: $CONTAINER
# Generated: $(date)
# Original image: $IMAGE
#
# This is a template - you'll need to adjust package names and paths

{ config, lib, pkgs, ... }:

with lib;

{
  # ═══════════════════════════════════════════════════════════
  # OPTION 1: NixOS Container (Recommended)
  # ═══════════════════════════════════════════════════════════

  containers.$CONTAINER = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.230.10";
    localAddress = "192.168.230.11";

    # Bind mounts (volumes)
    bindMounts = {
EOF

# Add bind mounts
if [ -n "$VOLUMES" ]; then
    for vol in $VOLUMES; do
        IFS=':' read -r source dest <<< "$vol"
        cat >> "$OUTPUT_FILE" <<EOF
      "$dest" = {
        hostPath = "$source";
        isReadOnly = false;
      };
EOF
    done
fi

cat >> "$OUTPUT_FILE" <<EOF
    };

    config = { config, pkgs, ... }: {
      nix.nixPath = [ "nixpkgs=\${pkgs.path}" ];

      networking = {
        defaultGateway = {
          address = "192.168.230.10";
          interface = "eth0";
        };
        nameservers = [ "1.1.1.1" "8.8.8.8" ];
        firewall = {
          enable = true;
          allowedTCPPorts = [
EOF

# Add ports
if [ -n "$PORTS" ]; then
    for port in $PORTS; do
        # Extract port number (remove /tcp or /udp)
        port_num=$(echo "$port" | sed 's|/tcp||;s|/udp||')
        echo "            $port_num" >> "$OUTPUT_FILE"
    done
fi

cat >> "$OUTPUT_FILE" <<EOF
          ];
        };
      };

      # Environment variables
      environment.variables = {
EOF

# Add environment variables
if [ -n "$ENV_VARS" ]; then
    while IFS= read -r line; do
        if [[ "$line" == *"="* ]]; then
            key=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2-)
            # Skip PATH and common system vars
            if [[ "$key" != "PATH" && "$key" != "HOME" && "$key" != "HOSTNAME" ]]; then
                echo "        $key = \"$value\";" >> "$OUTPUT_FILE"
            fi
        fi
    done <<< "$ENV_VARS"
fi

cat >> "$OUTPUT_FILE" <<EOF
      };

      # TODO: Add appropriate packages
      environment.systemPackages = with pkgs; [
        # Example: if image was node:22, add nodejs_22
        # nodejs_22
        # If postgres:16, use services.postgresql instead
        bash
        coreutils
      ];

      # TODO: Enable appropriate services
      # services.postgresql.enable = true;
      # services.nginx.enable = true;
      # services.redis.servers."".enable = true;

      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "25.05";
    };
  };

  # ═══════════════════════════════════════════════════════════
  # OPTION 2: Docker Image (Alternative)
  # ═══════════════════════════════════════════════════════════
  #
  # If you prefer to build a Docker image with Nix:
  #
  # Add to lib/packages.nix:
  #
  # image-$CONTAINER = pkgs.dockerTools.buildImage {
  #   name = "ghcr.io/voidnxlabs/$CONTAINER";
  #   tag = "latest";
  #
  #   copyToRoot = pkgs.buildEnv {
  #     name = "$CONTAINER-root";
  #     paths = with pkgs; [
  #       bash
  #       coreutils
  #       # Add your packages here
  #     ];
  #     pathsToLink = [ "/bin" ];
  #   };
  #
  #   config = {
EOF

if [ -n "$WORKDIR" ]; then
    echo "  #     WorkingDir = \"$WORKDIR\";" >> "$OUTPUT_FILE"
fi

if [ -n "$USER" ]; then
    echo "  #     User = \"$USER\";" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" <<EOF
  #     Env = [
  #       "PATH=/bin"
EOF

# Add environment to Docker image config
if [ -n "$ENV_VARS" ]; then
    while IFS= read -r line; do
        if [[ "$line" == *"="* ]] && [[ "$line" != PATH=* ]]; then
            echo "  #       \"$line\"" >> "$OUTPUT_FILE"
        fi
    done <<< "$ENV_VARS"
fi

cat >> "$OUTPUT_FILE" <<EOF
  #     ];
  #     ExposedPorts = {
EOF

# Add exposed ports to Docker image config
if [ -n "$PORTS" ]; then
    for port in $PORTS; do
        echo "  #       \"$port\" = {};" >> "$OUTPUT_FILE"
    done
fi

cat >> "$OUTPUT_FILE" <<EOF
  #     };
EOF

if [ -n "$ENTRYPOINT" ]; then
    echo "  #     Entrypoint = [ $ENTRYPOINT ];" >> "$OUTPUT_FILE"
fi

if [ -n "$CMD" ]; then
    echo "  #     Cmd = [ $CMD ];" >> "$OUTPUT_FILE"
fi

cat >> "$OUTPUT_FILE" <<EOF
  #   };
  # };
}
EOF

print_success "Nix expression generated: ${BOLD}${OUTPUT_FILE}${NC}"
echo ""

# Print summary
echo -e "${CYAN}${BOLD}Container Summary:${NC}"
echo -e "${BLUE}Image:${NC}       $IMAGE"
echo -e "${BLUE}Ports:${NC}       $PORTS"
if [ -n "$WORKDIR" ]; then
    echo -e "${BLUE}WorkDir:${NC}     $WORKDIR"
fi
if [ -n "$USER" ]; then
    echo -e "${BLUE}User:${NC}        $USER"
fi
echo ""

# Print next steps
echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
echo "1. Review and edit ${BOLD}${OUTPUT_FILE}${NC}"
echo "2. Replace TODOs with actual package names"
echo "3. Add to your configuration:"
echo "   ${CYAN}imports = [ ./${OUTPUT_FILE} ];${NC}"
echo "4. Rebuild:"
echo "   ${CYAN}sudo nixos-rebuild switch${NC}"
echo ""

print_info "Additional information:"
echo ""
echo "To see full container config:"
echo "  ${CYAN}docker inspect $CONTAINER | jq${NC}"
echo ""
echo "To export filesystem:"
echo "  ${CYAN}docker export $CONTAINER > ${CONTAINER}.tar${NC}"
echo ""
echo "To see running processes:"
echo "  ${CYAN}docker top $CONTAINER${NC}"
echo ""
