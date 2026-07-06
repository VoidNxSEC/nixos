{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.emergency.configuration = {
    system.nixos.tags = [ "Emergency" ];

    # ──────────────────────────────────────────────────────────────
    # Trezor hardware authentication
    # Acesso físico obrigatório para qualquer operação SSH/sudo
    # ──────────────────────────────────────────────────────────────
    hardware.trezor.enable = lib.mkForce true;
    hardware.trezor.enableSSHAgent = lib.mkForce true;

    # ──────────────────────────────────────────────────────────────
    # SSH — apenas autenticação por chave Trezor em modo emergência
    # ──────────────────────────────────────────────────────────────
    services.openssh = {
      enable = lib.mkForce true;
      settings = {
        PasswordAuthentication = lib.mkForce false;
        KbdInteractiveAuthentication = lib.mkForce false;
        PermitRootLogin = lib.mkForce "no";
        # Força uso de chave derivada do Trezor
        AuthenticationMethods = lib.mkForce "publickey";
      };
    };

    # ──────────────────────────────────────────────────────────────
    # Serviços — desabilitar workloads pesados para estabilidade
    # ──────────────────────────────────────────────────────────────
    services.k3s-cluster.enable = lib.mkForce false;
    services.cilium-cni.enable = lib.mkForce false;
    services.longhorn-storage.enable = lib.mkForce false;

    # ──────────────────────────────────────────────────────────────
    # Pacotes de diagnóstico disponíveis no boot de emergência
    # ──────────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      trezor-suite
      python313Packages.trezor
      # Network diagnostics
      nmap
      tcpdump
      netcat-openbsd
      # System diagnostics
      htop
      lsof
      strace
      # Disk tools
      parted
      gptfdisk
      btrfs-progs
      cryptsetup
    ];

    # Mensagem no login indicando modo emergência
    services.getty.helpLine = lib.mkForce ''
      ╔══════════════════════════════════════════════╗
      ║        MODO EMERGÊNCIA — Trezor Auth         ║
      ║  SSH: apenas chave derivada do Trezor        ║
      ║  sudo: requer confirmação física no device   ║
      ╚══════════════════════════════════════════════╝
    '';
  };
}
