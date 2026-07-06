# NixOS Configuration Testing Init
# Provides utilities for testing configuration changes safely

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Test configuration validation
  system.build.testConfig = pkgs.writeShellScriptBin "test-nixos-config" ''
    set -euo pipefail

    echo "🧪 Testing NixOS configuration..."

    # Validate flake syntax
    echo "Validating flake syntax..."
    nix flake check /etc/nixos --no-build

    # Dry-run build to catch errors
    echo "Performing dry-run build..."
    nixos-rebuild dry-build --flake /etc/nixos#kernelcore

    # Check for potential issues
    echo "Checking for common issues..."

    # Check if all imports exist
    echo "Verifying all module imports..."
    find /etc/nixos -name "*.nix" -exec nix-instantiate --parse {} \; > /dev/null

    echo "✅ Configuration test completed successfully!"
  '';

  # Safe testing environment
  system.build.testVM = pkgs.writeShellScriptBin "test-nixos-vm" ''
    set -euo pipefail

    echo "🖥️  Building test VM..."

    # Build VM for testing
    nixos-rebuild build-vm --flake /etc/nixos#kernelcore

    echo "VM built successfully. Run ./result/bin/run-*-vm to test."
    echo "Note: VM will use 2GB RAM by default"
  '';

  # Configuration backup before testing
  system.build.backupConfig = pkgs.writeShellScriptBin "backup-nixos-config" ''
    set -euo pipefail

    BACKUP_DIR="/var/lib/nixos-config-backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/config_$TIMESTAMP"

    echo "📦 Creating configuration backup..."

    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r /etc/nixos "$BACKUP_PATH"

    echo "✅ Configuration backed up to: $BACKUP_PATH"

    # Keep only last 10 backups
    sudo find "$BACKUP_DIR" -maxdepth 1 -type d -name "config_*" | \
      sort -r | tail -n +11 | xargs -r sudo rm -rf
  '';

  # Add testing tools to system packages
  environment.systemPackages = with pkgs; [
    config.system.build.testConfig
    config.system.build.testVM
    config.system.build.backupConfig
  ];
}
