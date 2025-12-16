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
    # NOTE: Lynis is now managed via tar-packages module
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/lynis";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    environment.systemPackages = with pkgs; [
      # Security auditing
      # lynis  # MOVED: Now managed via kernelcore.packages.tar.lynis
      vulnix
      aide
      # Lynis wrapper for easier read-only audits
      (pkgs.writeScriptBin "lynis-audit" ''
        #!${pkgs.bash}/bin/bash
        # Run Lynis audit with sudo (read-only system scan)
        # Uses Lynis from tar-packages module
        # Use wrapper sudo which has setuid bit
        exec /run/wrappers/bin/sudo /run/current-system/sw/bin/lynis audit system "$@"
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
