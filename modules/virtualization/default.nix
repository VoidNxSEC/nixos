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
    ./vmctl-cli.nix # CLI declarativa de VMs QEMU (migrado de modules/programs/)
    ./macos-kvm.nix
  ];
}
