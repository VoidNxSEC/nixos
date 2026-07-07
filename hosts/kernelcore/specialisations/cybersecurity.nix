{
  config,
  lib,
  pkgs,
  ...
}:

{
  specialisation.cybersecurity.configuration = {
    system.nixos.tags = [ "CyberSecurity" ];

    # ── Ferramentas de segurança ofensiva e defensiva ────────────────────────
    kernelcore.security.packages.enable = lib.mkForce true;
    kernelcore.security.audit.enable = lib.mkForce true;
    kernelcore.security.kernel.enable = lib.mkForce true;

    environment.systemPackages = with pkgs; [
      # Reconhecimento / OSINT
      nmap
      masscan
      theharvester
      maltego

      # Web / análise de tráfego
      burpsuite
      wireshark
      tcpdump
      mitmproxy
      nikto
      sqlmap

      # Exploração / pentest
      metasploit
      exploitdb

      # Forense
      foremost
      binwalk
      volatility3
      ghidra

      # Senhas / hashes
      hashcat
      john
      hydra

      # Rede / captura
      netcat-openbsd
      socat
      proxychains

      # Criptografia / análise
      openssl
      age
      sops

      # Docker para labs isolados
      docker-compose
    ];

    virtualisation.docker.enable = lib.mkForce true;

    # ── Rede: captura de pacotes sem restrição ────────────────────────────────
    security.wrappers.tcpdump = {
      source = "${pkgs.tcpdump}/bin/tcpdump";
      capabilities = "cap_net_raw,cap_net_admin+eip";
      owner = "root";
      group = "wheel";
      permissions = "u+rx,g+rx";
    };

    # ── Firewall aberto para labs locais ─────────────────────────────────────
    networking.firewall.enable = lib.mkForce false;

    # ── Kernel: carregamento de módulos para análise de rede ─────────────────
    boot.kernelModules = [ "af_packet" ];
  };
}
