{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.services.offload-server = {
    enable = mkEnableOption "Enable NixOS offload build server";

    cachePort = mkOption {
      type = types.int;
      default = 5000;
      description = "Port for nix-serve binary cache";
    };

    builderUser = mkOption {
      type = types.str;
      default = "nix-builder";
      description = "Username for remote build SSH access";
    };

    cacheKeyPath = mkOption {
      type = types.str;
      default = "/var/cache-priv-key.pem";
      description = "Path to cache signing private key";
    };

    enableNFS = mkOption {
      type = types.bool;
      default = false;
      description = "Enable NFS exports for /nix/store sharing";
    };
  };

  config = mkIf config.services.offload-server.enable {

    # ===== NIX-SERVE BINARY CACHE =====
    services.nix-serve = {
      enable = true;
      port = config.services.offload-server.cachePort;
      bindAddress = "0.0.0.0"; # Listen on all interfaces
      secretKeyFile = config.services.offload-server.cacheKeyPath;
    };

    # ===== CREATE BUILDER USER =====
    users.users.${config.services.offload-server.builderUser} = {
      isSystemUser = true;
      group = config.services.offload-server.builderUser;
      home = "/var/lib/${config.services.offload-server.builderUser}";
      createHome = true;
      shell = pkgs.bash;
      description = "Nix remote build user";

      # SSH keys will be added here
      openssh.authorizedKeys.keys = [
        # Add laptop keys manually via:
        # ssh-copy-id -i laptop-key.pub nix-builder@192.168.15.7
        # Or add them declaratively here as strings
      ];
    };

    users.groups.${config.services.offload-server.builderUser} = {};

    # ===== SSH SERVER CONFIGURATION =====
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = mkDefault "no";
        PasswordAuthentication = mkDefault false;
        PubkeyAuthentication = true;
      };

      extraConfig = ''
        # Optimize for build transfers
        Compression yes
        TCPKeepAlive yes
        ClientAliveInterval 60
        ClientAliveCountMax 3
      '';
    };

    # ===== NIX CONFIGURATION =====
    nix.settings = {
      # Trust the builder user
      trusted-users = [ config.services.offload-server.builderUser ];

      # Optimize for serving builds
      keep-outputs = true;
      keep-derivations = true;

      # Network optimization
      connect-timeout = 5;
      stalled-download-timeout = 30;
    };

    # ===== NFS EXPORTS (OPTIONAL) =====
    services.nfs.server = mkIf config.services.offload-server.enableNFS {
      enable = true;
      exports = ''
        # Export /nix/store read-only to LAN
        /nix/store 192.168.15.0/24(ro,sync,no_subtree_check,no_root_squash)

        # Export build workspace read-write
        /var/lib/nix-offload 192.168.15.0/24(rw,sync,no_subtree_check,no_root_squash)
      '';
    };

    # Create NFS directories if enabled
    systemd.tmpfiles.rules = mkIf config.services.offload-server.enableNFS [
      "d /var/lib/nix-offload 0755 root root -"
      "d /var/lib/nix-offload/builds 0755 root root -"
      "d /var/lib/nix-offload/cache 0755 root root -"
    ];

    services.rpcbind.enable = mkIf config.services.offload-server.enableNFS true;

    # ===== FIREWALL CONFIGURATION =====
    networking.firewall = {
      allowedTCPPorts = [
        22 # SSH
        config.services.offload-server.cachePort # nix-serve
      ] ++ (optionals config.services.offload-server.enableNFS [
        2049 # NFS
        111 # RPC portmapper
      ]);

      allowedUDPPorts = optionals config.services.offload-server.enableNFS [
        2049 # NFS
        111 # RPC portmapper
      ];
    };

    # ===== MANAGEMENT SCRIPTS =====
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "offload-server-status" ''
        echo "🖥️  NixOS Offload Server Status"
        echo "================================"
        echo

        # Check services
        echo "📊 Services:"
        systemctl is-active --quiet nix-serve && \
          echo "✅ nix-serve: Running (port ${toString config.services.offload-server.cachePort})" || \
          echo "❌ nix-serve: Inactive"

        systemctl is-active --quiet sshd && \
          echo "✅ sshd: Running" || \
          echo "❌ sshd: Inactive"

        ${optionalString config.services.offload-server.enableNFS ''
        systemctl is-active --quiet nfs-server && \
          echo "✅ NFS: Running" || \
          echo "❌ NFS: Inactive"
        ''}

        # Check cache key
        echo
        echo "🔑 Cache Configuration:"
        if [ -f "${config.services.offload-server.cacheKeyPath}" ]; then
          echo "✅ Cache signing key: Present"
          PUB_KEY_PATH="${builtins.replaceStrings ["-priv-"] ["-pub-"] config.services.offload-server.cacheKeyPath}"
          if [ -f "$PUB_KEY_PATH" ]; then
            echo "   Public key: $PUB_KEY_PATH"
            echo "   Key content: $(cat $PUB_KEY_PATH)"
          fi
        else
          echo "❌ Cache signing key: Missing"
          echo "   Run: sudo nix-store --generate-binary-cache-key cache.local \\"
          echo "        ${config.services.offload-server.cacheKeyPath} \\"
          echo "        ${builtins.replaceStrings ["-priv-"] ["-pub-"] config.services.offload-server.cacheKeyPath}"
        fi

        # Network info
        echo
        echo "🌐 Network:"
        IP=$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)
        echo "Server IP: $IP"
        echo "Cache URL: http://$IP:${toString config.services.offload-server.cachePort}"

        # Test cache
        echo
        echo "🧪 Cache Test:"
        if curl -s -f http://localhost:${toString config.services.offload-server.cachePort}/nix-cache-info >/dev/null; then
          echo "✅ Cache accessible"
          curl -s http://localhost:${toString config.services.offload-server.cachePort}/nix-cache-info
        else
          echo "❌ Cache not accessible"
        fi

        # Builder user info
        echo
        echo "👤 Builder User (${config.services.offload-server.builderUser}):"
        if id ${config.services.offload-server.builderUser} >/dev/null 2>&1; then
          echo "✅ User exists"
          echo "   Home: $(eval echo ~${config.services.offload-server.builderUser})"

          AUTH_KEYS="$(eval echo ~${config.services.offload-server.builderUser})/.ssh/authorized_keys"
          if [ -f "$AUTH_KEYS" ]; then
            KEY_COUNT=$(wc -l < "$AUTH_KEYS")
            echo "   Authorized keys: $KEY_COUNT"
          else
            echo "   Authorized keys: None"
          fi
        else
          echo "❌ User does not exist"
        fi

        # Storage info
        echo
        echo "💾 Storage:"
        echo "Nix store: $(du -sh /nix/store 2>/dev/null | cut -f1)"
        echo "Available: $(df -h /nix/store | tail -1 | awk '{print $4}')"
      '')

      (writeShellScriptBin "offload-server-test" ''
        echo "🧪 Testing Offload Server Components"
        echo "===================================="
        echo

        # Test SSH
        echo "1. Testing SSH access for ${config.services.offload-server.builderUser}..."
        if sudo -u ${config.services.offload-server.builderUser} ssh -o ConnectTimeout=5 -o BatchMode=yes localhost 'echo "SSH OK"' 2>/dev/null; then
          echo "   ✅ SSH test passed"
        else
          echo "   ⚠️  SSH test failed (may need SSH key setup)"
        fi
        echo

        # Test cache
        echo "2. Testing cache server..."
        if curl -s -f http://localhost:${toString config.services.offload-server.cachePort}/nix-cache-info >/dev/null; then
          echo "   ✅ Cache server responding"
        else
          echo "   ❌ Cache server not responding"
        fi
        echo

        # Test build capability
        echo "3. Testing build capability..."
        if nix-build '<nixpkgs>' -A hello --no-out-link >/dev/null 2>&1; then
          echo "   ✅ Local builds working"
        else
          echo "   ❌ Local builds failed"
        fi
        echo

        ${optionalString config.services.offload-server.enableNFS ''
        # Test NFS
        echo "4. Testing NFS exports..."
        if showmount -e localhost >/dev/null 2>&1; then
          echo "   ✅ NFS exports available:"
          showmount -e localhost | tail -n +2 | sed 's/^/      /'
        else
          echo "   ❌ NFS exports failed"
        fi
        echo
        ''}

        echo "✅ Server tests complete!"
        echo
        echo "📋 Next Steps:"
        echo "1. On laptop, copy builder key:"
        echo "   scp $(whoami)@$(ip route get 1.1.1.1 | awk '{print $7}' | head -1):/etc/nix/builder_key /etc/nix/"
        echo
        echo "2. Add to laptop's configuration.nix:"
        echo "   services.laptop-builder-client.enable = true;"
        echo
        echo "3. Rebuild laptop:"
        echo "   sudo nixos-rebuild switch"
      '')

      (writeShellScriptBin "offload-generate-cache-keys" ''
        PRIV_KEY="${config.services.offload-server.cacheKeyPath}"
        PUB_KEY="${builtins.replaceStrings ["-priv-"] ["-pub-"] config.services.offload-server.cacheKeyPath}"

        if [ -f "$PRIV_KEY" ] && [ -f "$PUB_KEY" ]; then
          echo "⚠️  Cache keys already exist!"
          echo "Private: $PRIV_KEY"
          echo "Public:  $PUB_KEY"
          echo
          read -p "Regenerate keys? This will invalidate existing cache! (y/N) " -n 1 -r
          echo
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 0
          fi
        fi

        echo "🔑 Generating cache signing keys..."
        sudo nix-store --generate-binary-cache-key cache.local "$PRIV_KEY" "$PUB_KEY"

        if [ $? -eq 0 ]; then
          echo "✅ Keys generated successfully!"
          echo
          echo "📋 Public key (add to laptop's trusted-public-keys):"
          echo "   cache.local:$(cat $PUB_KEY)"
          echo
          echo "🔒 Private key location: $PRIV_KEY"
          echo "   Keep this secure! Do not share!"
        else
          echo "❌ Key generation failed!"
          exit 1
        fi
      '')
    ];

    # ===== ACTIVATION SCRIPT =====
    system.activationScripts.offload-server-setup = ''
      # Ensure builder SSH directory exists
      BUILDER_HOME="/var/lib/${config.services.offload-server.builderUser}"
      if [ -d "$BUILDER_HOME" ]; then
        mkdir -p "$BUILDER_HOME/.ssh"
        chown ${config.services.offload-server.builderUser}:${config.services.offload-server.builderUser} "$BUILDER_HOME/.ssh"
        chmod 700 "$BUILDER_HOME/.ssh"
      fi

      # Warn if cache keys don't exist
      if [ ! -f "${config.services.offload-server.cacheKeyPath}" ]; then
        echo "⚠️  WARNING: Cache signing keys not found!"
        echo "   Run: offload-generate-cache-keys"
      fi
    '';
  };
}
