# NixOS Configuration Debug Init
# Provides utilities for debugging configuration issues

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Debug configuration issues
  system.build.debugConfig = pkgs.writeShellScriptBin "debug-nixos-config" ''
    set -euo pipefail

    echo "🔍 Debugging NixOS configuration..."

    # Check system journal for errors
    echo "=== Recent systemd failures ==="
    journalctl --failed --since="24 hours ago" --no-pager || true

    # Check for configuration warnings
    echo -e "\n=== Configuration warnings ==="
    nixos-rebuild dry-build --flake /etc/nixos#kernelcore 2>&1 | grep -i "warning" || echo "No warnings found"

    # Check disk space
    echo -e "\n=== Disk usage ==="
    df -h / /boot /nix 2>/dev/null || true

    # Check Nix store issues
    echo -e "\n=== Nix store verification ==="
    nix store verify --check-contents --repair 2>&1 | head -20 || echo "Store verification failed"

    # Show recent generations
    echo -e "\n=== Recent system generations ==="
    nixos-rebuild list-generations | tail -5

    # Check for broken symlinks
    echo -e "\n=== Checking for broken symlinks ==="
    find /etc/nixos -type l -exec test ! -e {} \; -print 2>/dev/null || echo "No broken symlinks found"

    echo -e "\n✅ Debug information collected"
  '';

  # Detailed system analysis
  system.build.analyzeSystem = pkgs.writeShellScriptBin "analyze-nixos-system" ''
    set -euo pipefail

    echo "📊 Analyzing NixOS system..."

    # Memory usage
    echo "=== Memory usage ==="
    free -h

    # Service status
    echo -e "\n=== Failed services ==="
    systemctl list-units --failed --no-pager || true

    # Boot time analysis
    echo -e "\n=== Boot time analysis ==="
    systemd-analyze blame | head -10 || true

    # Network configuration
    echo -e "\n=== Network status ==="
    ip route show || true
    systemctl is-active NetworkManager systemd-networkd || true

    # Check for common issues
    echo -e "\n=== Common issue checks ==="

    # Check if /tmp is full
    TMPFULL=$(df /tmp | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$TMPFULL" -gt 90 ]; then
      echo "⚠️  /tmp is ''${TMPFULL}% full"
    fi

    # Check if /boot is full
    BOOTFULL=$(df /boot | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$BOOTFULL" -gt 80 ]; then
      echo "⚠️  /boot is ''${BOOTFULL}% full"
    fi

    echo -e "\n✅ System analysis complete"
  '';

  # Recovery tools
  system.build.recoveryTools = pkgs.writeShellScriptBin "nixos-recovery-tools" ''
    set -euo pipefail

    case "''${1:-help}" in
      rollback)
        echo "🔄 Rolling back to previous generation..."
        nixos-rebuild switch --rollback --flake /etc/nixos#kernelcore
        ;;
      bootloader)
        echo "🔧 Rebuilding bootloader..."
        nixos-rebuild switch --install-bootloader --flake /etc/nixos#kernelcore
        ;;
      gc)
        echo "🗑️  Running garbage collection..."
        nix-collect-garbage -d
        echo "Cleaning up boot entries..."
        /run/current-system/bin/switch-to-configuration boot
        ;;
      repair)
        echo "🔨 Repairing Nix store..."
        nix store repair --all || true
        ;;
      reset-generation)
        echo "⚠️  This will delete ALL system generations except current!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
          nix-env --delete-generations old --profile /nix/var/nix/profiles/system
          echo "✅ Old generations deleted"
        else
          echo "❌ Operation cancelled"
        fi
        ;;
      help|*)
        echo "NixOS Recovery Tools"
        echo "Usage: nixos-recovery-tools <command>"
        echo ""
        echo "Commands:"
        echo "  rollback        - Roll back to previous generation"
        echo "  bootloader      - Rebuild bootloader configuration"
        echo "  gc              - Run garbage collection"
        echo "  repair          - Repair Nix store"
        echo "  reset-generation - Delete old generations (DANGEROUS)"
        echo "  help            - Show this help"
        ;;
    esac
  '';

  # Debug log collection
  system.build.collectLogs = pkgs.writeShellScriptBin "collect-debug-logs" ''
    set -euo pipefail

    DEBUG_DIR="/tmp/nixos-debug-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$DEBUG_DIR"

    echo "📋 Collecting debug logs to $DEBUG_DIR..."

    # System info
    nixos-version > "$DEBUG_DIR/nixos-version.txt"
    uname -a > "$DEBUG_DIR/kernel-info.txt"

    # Hardware info
    lscpu > "$DEBUG_DIR/cpu-info.txt" 2>/dev/null || true
    lsblk > "$DEBUG_DIR/disk-info.txt" 2>/dev/null || true
    free -h > "$DEBUG_DIR/memory-info.txt"

    # System logs
    journalctl --since="24 hours ago" --no-pager > "$DEBUG_DIR/journalctl.log" 2>/dev/null || true
    dmesg > "$DEBUG_DIR/dmesg.log" 2>/dev/null || true

    # Configuration info
    nix flake show /etc/nixos > "$DEBUG_DIR/flake-outputs.txt" 2>/dev/null || true
    nixos-rebuild list-generations > "$DEBUG_DIR/generations.txt" 2>/dev/null || true

    # Service status
    systemctl list-units --failed > "$DEBUG_DIR/failed-services.txt" 2>/dev/null || true
    systemctl list-units --type=service > "$DEBUG_DIR/all-services.txt" 2>/dev/null || true

    echo "✅ Debug logs collected in: $DEBUG_DIR"
    echo "You can share this directory for troubleshooting"
  '';

  # Add debug tools to system packages
  environment.systemPackages = with pkgs; [
    config.system.build.debugConfig
    config.system.build.analyzeSystem
    config.system.build.recoveryTools
    config.system.build.collectLogs
  ];
}
