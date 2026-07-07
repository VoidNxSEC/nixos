{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.stable.configuration = {
    system.nixos.tags = [ "Stable" ];

    # ── Modo estável: mínimo de mudanças, máximo de confiabilidade ────────────
    # Desabilita features experimentais e otimizações agressivas

    nix.settings = {
      experimental-features = lib.mkForce [ "nix-command" "flakes" ];
      max-jobs = lib.mkForce 4;
      cores = lib.mkForce 2;
      # Sem sandbox relaxado
      sandbox = lib.mkForce true;
    };

    # ── Auto-upgrade ativo — sempre no último estado estável ──────────────────
    kernelcore.security.auto-upgrade.enable = lib.mkForce true;

    # ── Sem containers (superfície reduzida) ──────────────────────────────────
    virtualisation.docker.enable = lib.mkForce false;
    virtualisation.libvirtd.enable = lib.mkForce false;

    # ── Sem electron apps ─────────────────────────────────────────────────────
    kernelcore.electron.enable = lib.mkForce false;

    # ── Kernel estável (não latest) ───────────────────────────────────────────
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

    # ── Firewall restritivo ───────────────────────────────────────────────────
    networking.firewall = {
      enable = lib.mkForce true;
      allowedTCPPorts = lib.mkForce [ 22 ];
      allowedUDPPorts = lib.mkForce [ 41641 ]; # Tailscale
    };

    # ── Hardening de segurança base ───────────────────────────────────────────
    kernelcore.security.hardening.enable = lib.mkForce true;
    kernelcore.security.kernel.enable = lib.mkForce true;
  };
}
