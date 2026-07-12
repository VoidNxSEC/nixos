{ ... }:

# ═══════════════════════════════════════════════════════════
# SISTEMA BASE — boot loader, memória, Nix
# ═══════════════════════════════════════════════════════════

{
  # Boot loader — controle explícito desta máquina (mercury comentado)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  kernelcore.system = {
    memory.optimizations.enable = true;
    nix.optimizations.enable = true;
    nix.experimental-features.enable = true;

    # Local binary cache - uses offload-server's nix-serve
    binary-cache = {
      enable = false;
      local.enable = false;
      # URL: http://192.168.15.9:5000 (default)
    };
  };

  # ZRAM swap – compressed in-memory swap; important for large ML model loads
  # Uses zstd at 50% of physical RAM; avoids slow disk I/O when VRAM overflows
  kernelcore.system.memory.zram = {
    enable = true;
    memoryPercent = 50;
  };
}
