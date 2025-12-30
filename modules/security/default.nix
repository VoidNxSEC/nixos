{ ... }:

# ============================================================
# Security Module Aggregator
# ============================================================
# Purpose: Import all security hardening configurations
# IMPORTANT: Security modules should be imported LAST in flake.nix
#            to ensure they have highest priority and can override
#            other module configurations.
# Categories: Boot, Kernel, Network, SSH, Audit, ClamAV, etc.
# ============================================================

{
  imports = [
    # Boot and kernel security
    ./boot.nix
    ./kernel.nix

    # Compiler hardening (currently disabled - Nix 2.18+ compatibility)
    ./compiler-hardening.nix

    # Dev directory hardening
    ./dev-directory-hardening.nix

    # System hardening
    ./hardening.nix
    ./network.nix
    ./pam.nix
    ./ssh.nix
    ./nix-daemon.nix
    ./packages.nix
    ./keyring.nix

    # Security monitoring and scanning
    ./aide.nix
    ./clamav.nix
    ./audit.nix

    # Maintenance
    ./auto-upgrade.nix
  ];
}
