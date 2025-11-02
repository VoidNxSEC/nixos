{ ... }:

# ============================================================
# Virtualization Module Aggregator
# ============================================================
# Purpose: Import all virtualization configurations
# Categories: VM management (vmctl), VM definitions
# ============================================================

{
  imports = [
    ./vms.nix
    ./vmctl.nix
  ];
}
