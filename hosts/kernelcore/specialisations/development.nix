{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.development.configuration = {
    system.nixos.tags = [ "Development" ];

    # ── Ambientes de linguagem ────────────────────────────────────────────────
    kernelcore.development = {
      rust.enable = lib.mkForce true;
      go.enable = lib.mkForce true;
      python.enable = lib.mkForce true;
      nodejs.enable = lib.mkForce true;
      nix.enable = lib.mkForce true;
    };

    # ── Nix: builds agressivos com recursos máximos ───────────────────────────
    nix.settings = {
      max-jobs = lib.mkForce 2;
      cores = lib.mkForce 2;
      keep-outputs = lib.mkForce true;
      keep-derivations = lib.mkForce true;
    };

    # ── Containers ────────────────────────────────────────────────────────────
    virtualisation.docker = {
      enable = lib.mkForce true;
      enableOnBoot = true;
    };

    # ── Ferramentas de dev ────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      # Debug
      gdb valgrind strace ltrace

      # Performance
      hyperfine flamegraph perf-tools

      # Rede / API
      httpie insomnia

      # Git avançado
      git-lfs gh lazygit

      # Análise de código
      tokei cloc

      # Containers / infra
      kubectl helm k9s docker-compose
    ];

    # ── Firewall: portas de dev local abertas ─────────────────────────────────
    networking.firewall.allowedTCPPortRanges = lib.mkForce [
      { from = 3000; to = 9999; }
    ];

    # ── Electron apps para IDEs ───────────────────────────────────────────────
    kernelcore.electron.enable = lib.mkForce true;
  };
}
