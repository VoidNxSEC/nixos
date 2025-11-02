# modules/services/laptop-builder-client.nix
# Módulo declarativo para configurar laptop como cliente de build remoto
# Este módulo é uma alternativa ao laptop-offload-client.nix (que fica na raiz)

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    services.laptop-builder-client = {
      enable = mkEnableOption "Enable laptop as remote build client";

      desktopIP = mkOption {
        type = types.str;
        default = "192.168.15.7";
        description = "IP address of the desktop build server";
      };

      builderKeyPath = mkOption {
        type = types.str;
        default = "/etc/nix/builder_key";
        description = "Path to SSH private key for builder authentication";
      };

      maxJobs = mkOption {
        type = types.int;
        default = 0;
        description = "Maximum local build jobs (0 = offload only)";
      };
    };
  };

  config = mkIf config.services.laptop-builder-client.enable {
    # Remote builder configuration
    nix.settings = {
      builders = mkForce [
        "ssh://nix-builder@${config.services.laptop-builder-client.desktopIP} x86_64-linux ${config.services.laptop-builder-client.builderKeyPath} 2 1 nixos-test,benchmark,big-parallel"
      ];

      builders-use-substitutes = true;
      max-jobs = mkForce config.services.laptop-builder-client.maxJobs;
      fallback = true;

      # Desktop cache first, then internet
      substituters = [
        "http://${config.services.laptop-builder-client.desktopIP}:5000"
        "https://cache.nixos.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache-key:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE="
      ];

      connect-timeout = 5;
      stalled-download-timeout = 30;
    };

    # SSH configuration for builder
    programs.ssh.extraConfig = ''
      Host ${config.services.laptop-builder-client.desktopIP}
        HostName ${config.services.laptop-builder-client.desktopIP}
        User nix-builder
        Port 22
        IdentityFile ${config.services.laptop-builder-client.builderKeyPath}
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        LogLevel ERROR
        Compression yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
        ControlMaster auto
        ControlPath ~/.ssh/nix-builder-%h-%p-%r
        ControlPersist 600
    '';

    # Utility scripts
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "offload-status" ''
        echo "🖥️  Laptop Offload Client Status"
        echo "==============================="
        echo

        # Check desktop connectivity
        echo "📡 Desktop Connection:"
        if ping -c 1 -W 2 ${config.services.laptop-builder-client.desktopIP} >/dev/null 2>&1; then
          echo "✅ Desktop reachable"
        else
          echo "❌ Desktop unreachable (ICMP may be blocked)"
        fi

        # Check SSH connectivity
        echo
        echo "🔑 SSH Builder Access:"
        if ssh -o ConnectTimeout=5 -o BatchMode=yes nix-builder@${config.services.laptop-builder-client.desktopIP} 'echo "SSH OK"' 2>/dev/null; then
          echo "✅ SSH builder access working"
        else
          echo "❌ SSH builder access failed"
          echo "   Check: ${config.services.laptop-builder-client.builderKeyPath}"
        fi

        # Check cache access
        echo
        echo "🗄️  Cache Access:"
        if curl -s -f http://${config.services.laptop-builder-client.desktopIP}:5000/nix-cache-info >/dev/null 2>&1; then
          echo "✅ Desktop cache accessible"
        else
          echo "❌ Desktop cache unreachable"
        fi

        # Show configuration
        echo
        echo "⚙️  Configuration:"
        echo "Desktop IP: ${config.services.laptop-builder-client.desktopIP}"
        echo "Builder key: ${config.services.laptop-builder-client.builderKeyPath}"
        echo "Max local jobs: ${toString config.services.laptop-builder-client.maxJobs}"
      '')

      (writeShellScriptBin "offload-test-build" ''
        echo "🧪 Testing Remote Build Capability"
        echo "=================================="
        echo
        echo "Testing remote build with hello package..."
        echo

        if nix-build --builders "ssh://nix-builder@${config.services.laptop-builder-client.desktopIP} x86_64-linux ${config.services.laptop-builder-client.builderKeyPath} 2 1" \
                     --option substitute false \
                     '<nixpkgs>' -A hello --no-out-link; then
          echo
          echo "✅ Remote build test successful!"
        else
          echo
          echo "❌ Remote build test failed!"
          echo "Check SSH connectivity and desktop trusted-users configuration."
        fi
      '')
    ];
  };
}
