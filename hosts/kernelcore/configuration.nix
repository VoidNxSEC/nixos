{ ... }:

# ═══════════════════════════════════════════════════════════
# HOST kernelcore — agregador
#
# Este arquivo só reúne identidade da máquina e os imports
# temáticos. Toda ativação/valores vive nos arquivos ao lado;
# implementação vive em modules/ (namespace kernelcore.*).
# ═══════════════════════════════════════════════════════════

{
  imports = [
    ./system.nix # boot loader, memória/zram, Nix
    ./hardware.nix # NVIDIA prime, Intel, bluetooth, wifi
    ./acpi-dsdt.nix # DSDT override específico deste laptop
    ./networking.nix # DNS, bridge, VPNs, proxies, Tailscale
    ./security.nix # hardening, TLS, keyring, SOC, secrets
    ./desktop.nix # Hyprland/Niri, SDDM, áudio, periféricos
    ./applications.nix # browsers, editores, Electron/Chromium
    ./development.nix # toolchains, CI/CD, tools, shell helpers
    ./services.nix # SSH, PostgreSQL, forges, runners, mosh
    ./ml.nix # inferência llama.cpp, MCP, agent hub
    ./kubernetes.nix # k3s/cilium/longhorn/kind (gated)
    ./virtualization.nix # libvirt/KVM, VMs, containers
    ./users.nix # usuário kernelcore + pacotes de usuário
    ./packages.nix # systemPackages + nixpkgs config
    ./specialisations # ambientes alternativos de boot
  ];

  # ── Identidade da máquina ──
  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "br-abnt2";

  system.stateVersion = "26.05";
}
