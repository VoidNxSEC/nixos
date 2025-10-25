{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    kernelcore.security.packages.enable = mkEnableOption "Install security and audit tools";
  };

  config = mkIf config.kernelcore.security.packages.enable {
    ##########################################################################
    # 🔧 Security & Audit Tools
    ##########################################################################

    # Allow wheel group users to run Lynis audits without password
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${pkgs.lynis}/bin/lynis";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    environment.systemPackages = with pkgs; [
      # Security auditing
      lynis
      vulnix
      aide
      # Lynis wrapper for easier read-only audits
      (pkgs.writeScriptBin "lynis-audit" ''
        #!${pkgs.bash}/bin/bash
        # Run Lynis audit with sudo (read-only system scan)
        exec ${pkgs.sudo}/bin/sudo ${pkgs.lynis}/bin/lynis audit system "$@"
      '')

      # VPN & Authentication
      wgnord
      google-authenticator

      # Network analysis
      nmap
      tcpdump
      wireshark-cli

      # Secrets management
      vault
      sops
      age

      # Password management
      keepassxc
      pass
      gnupg
      pinentry-curses
      libsecret

      # AI/ML tools (if needed for security analysis)
      ollama
      llama-cpp
      python313Packages.llama-stack-client

      # Uncomment if needed:
      # chkrootkit | >> Deprecated package
      # rkhunter | >> Not exists anymore
      wireshark
      # tripwire | >> Not exists anymore
      htop
      iotop
      nethogs
    ];
  };
}
