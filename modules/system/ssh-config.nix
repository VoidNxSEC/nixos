{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# SSH Client Configuration
# ============================================================
# Declarative SSH config management
# Supports multiple identities (personal, org, servers)
# ============================================================

with lib;

{
  options.kernelcore.ssh = {
    enable = mkEnableOption "Enable declarative SSH configuration";

    # User-specific SSH directory
    sshDir = mkOption {
      type = types.str;
      default = "/home/kernelcore/.ssh";
      description = "SSH directory path";
    };

    # Personal identity
    personalKey = mkOption {
      type = types.str;
      default = "id_ed25519_marcos";
      description = "Personal SSH key filename";
    };

    # Organization identity
    orgKey = mkOption {
      type = types.str;
      default = "id_ed25519_voidnxlabs";
      description = "Organization SSH key filename";
    };

    # Server identity
    serverKey = mkOption {
      type = types.str;
      default = "id_ed25519";  # ✅ Usar chave padrão que existe
      description = "Server SSH key filename";
    };

    # GitLab identity
    gitlabKey = mkOption {
      type = types.str;
      default = "id_ed25519_gitlab";
      description = "GitLab SSH key filename";
    };

    # Desktop/builder details
    serverHost = mkOption {
      type = types.str;
      default = "192.168.15.7";  # ✅ Desktop IP correto
      description = "Desktop/builder hostname/IP";
    };

    serverUser = mkOption {
      type = types.str;
      default = "kernelcore";
      description = "Username for internal server";
    };
  };

  config = mkIf config.kernelcore.ssh.enable {

    # ============================================================
    # System-wide SSH Configuration
    # ============================================================

    programs.ssh = {
      # ⚠️ SSH agent disabled here - using GNOME GCR/GPG agent instead
      # GNOME already provides gcr-ssh-agent or gpg-agent for SSH
      startAgent = false;

      # SSH agent configuration (when using standalone agent)
      # agentTimeout = "1h"; # Keys expire after 1 hour

      # Extra configuration (applies to all hosts)
      extraConfig = ''
        # Security defaults
        AddKeysToAgent yes
        ServerAliveInterval 60
        ServerAliveCountMax 120
        ForwardAgent no  # Disabled by default for security

        # Performance
        ControlMaster auto
        ControlPath ~/.ssh/control-%r@%h:%p
        ControlPersist 600

        # Modern crypto only
        HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
        PubkeyAcceptedKeyTypes ssh-ed25519,rsa-sha2-512,rsa-sha2-256

        # ================================================================
        # Host-specific configurations
        # ================================================================

        # Desktop/Builder - General access (VSCode Remote SSH)
        Host desktop
          HostName 192.168.15.7
          User cypher
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes
          Port 22
          ForwardAgent yes
          ForwardX11 yes
          ServerAliveInterval 60
          ServerAliveCountMax 3
          # VSCode Remote SSH optimizations
          ControlMaster auto
          ControlPath ~/.ssh/sockets/%r@%h-%p
          ControlPersist 600
          # Prevent handshake timeout
          ConnectTimeout 30
          # Enable TCP forwarding (required for VSCode)
          # RemoteForward line removed (invalid syntax)
          # Compression for better performance
          Compression yes

        # Desktop/Builder - Nix remote builds
        Host desktop-builder
          HostName 192.168.15.7
          User nix-builder
          IdentityFile ~/.ssh/nix-builder
          IdentitiesOnly yes
          Port 22

        # Alternative alias for nix builds (use accessible key)
        Host nix-desktop
          HostName 192.168.15.7
          User nix-builder
          IdentityFile ~/.ssh/nix-builder
          IdentitiesOnly yes
          StrictHostKeyChecking accept-new

        # GitHub
        Host github.com
          User git
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes

        # GitLab
        Host gitlab.com
          User git
          IdentityFile ~/.ssh/id_ed25519
          IdentitiesOnly yes
      '';

      # ============================================================
      # Host-specific configurations (matchBlocks)
      # ============================================================

      knownHosts = {
        # Define known hosts to prevent MITM
        "github.com" = {
          hostNames = [ "github.com" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
        "gitlab.com" = {
          hostNames = [ "gitlab.com" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
        };
      };
    };

    # ============================================================
    # User-specific SSH configuration (via Home Manager)
    # ============================================================
    # NOTE: Requires home-manager. If not using, configure manually
    # or use extraConfig above

    # Uncomment if using home-manager:
    /*
      home-manager.users.kernelcore = {
        programs.ssh = {
          enable = true;

          matchBlocks = {
            # ────────────────────────────────────────────────────
            # GitHub - Personal Account
            # ────────────────────────────────────────────────────
            "github.com-marcos" = {
              hostname = "github.com";
              user = "git";
              identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.personalKey}";
              identitiesOnly = true;
              extraOptions = {
                PreferredAuthentications = "publickey";
                AddKeysToAgent = "yes";
              };
            };

            # ────────────────────────────────────────────────────
            # GitHub - VoidNxLabs Organization
            # ────────────────────────────────────────────────────
            "github.com-voidnxlabs" = {
              hostname = "github.com";
              user = "git";
              identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.orgKey}";
              identitiesOnly = true;
              extraOptions = {
                PreferredAuthentications = "publickey";
                AddKeysToAgent = "yes";
              };
            };

            # ────────────────────────────────────────────────────
            # GitLab - External Projects
            # ────────────────────────────────────────────────────
            "gitlab.com" = {
              hostname = "gitlab.com";
              user = "git";
              identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.gitlabKey}";
              identitiesOnly = true;
            };

            # ────────────────────────────────────────────────────
            # Internal NixOS Server
            # ────────────────────────────────────────────────────
            "voidnx-server" = {
              hostname = config.kernelcore.ssh.serverHost;
              user = config.kernelcore.ssh.serverUser;
              identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.serverKey}";
              identitiesOnly = true;
              port = 22;
              forwardAgent = true;  # Useful for git operations on server
            };

            # ────────────────────────────────────────────────────
            # Desktop Machine (Builder/Cache)
            # ────────────────────────────────────────────────────
            "desktop" = {
              hostname = "192.168.15.6";
              user = "kernelcore";
              identityFile = "${config.kernelcore.ssh.sshDir}/${config.kernelcore.ssh.serverKey}";
              identitiesOnly = true;
              port = 22;
            };

            # ────────────────────────────────────────────────────
            # CI/CD Automated Host
            # ────────────────────────────────────────────────────
            "ci-runner" = {
              hostname = "ci.example.com";
              user = "runner";
              identityFile = "${config.kernelcore.ssh.sshDir}/id_ed25519_ci";
              identitiesOnly = true;
              extraOptions = {
                StrictHostKeyChecking = "no";  # Only for CI
                UserKnownHostsFile = "/dev/null";
              };
            };
          };
        };
      };
    */

    # ============================================================
    # SSH Key Management
    # ============================================================

    # Ensure SSH directory exists with correct permissions
    system.activationScripts.sshSetup = ''
      mkdir -p ${config.kernelcore.ssh.sshDir}
      chown kernelcore:users ${config.kernelcore.ssh.sshDir}
      chmod 700 ${config.kernelcore.ssh.sshDir}

      # Create config if doesn't exist
      if [ ! -f ${config.kernelcore.ssh.sshDir}/config ]; then
        touch ${config.kernelcore.ssh.sshDir}/config
        chown kernelcore:users ${config.kernelcore.ssh.sshDir}/config
        chmod 600 ${config.kernelcore.ssh.sshDir}/config
      fi
    '';

    # ============================================================
    # Helper Aliases
    # ============================================================

    environment.shellAliases = {
      # SSH shortcuts
      "ssh-desktop" = "ssh desktop";
      "ssh-server" = "ssh voidnx-server";

      # SSH key management
      "ssh-add-all" = "ssh-add ${config.kernelcore.ssh.sshDir}/id_*";
      "ssh-list" = "ssh-add -l";
      "ssh-test-github" = "ssh -T git@github.com-marcos";
      "ssh-test-gitlab" = "ssh -T git@gitlab.com";

      # Generate new key
      "ssh-keygen-ed25519" = "ssh-keygen -t ed25519 -C";
    };

    # ============================================================
    # Documentation
    # ============================================================

    environment.etc."nixos-ssh/README.md" = {
      text = ''
        # SSH Configuration - NixOS

        This system uses declarative SSH configuration managed by NixOS.

        ## Key Files

        - Personal: ~/.ssh/${config.kernelcore.ssh.personalKey}
        - Org: ~/.ssh/${config.kernelcore.ssh.orgKey}
        - Server: ~/.ssh/${config.kernelcore.ssh.serverKey}
        - GitLab: ~/.ssh/${config.kernelcore.ssh.gitlabKey}

        ## Usage Examples

        ### Git with different identities

        ```bash
        # Personal repository
        git clone git@github.com-marcos:username/repo.git

        # Organization repository
        git clone git@github.com-voidnxlabs:voidnxlabs/repo.git

        # GitLab
        git clone git@gitlab.com:user/project.git
        ```

        ### Server connections

        ```bash
        # Desktop/builder
        ssh desktop
        # or
        ssh-desktop

        # Internal server
        ssh voidnx-server
        # or
        ssh-server
        ```

        ### Key Management

        ```bash
        # Add all keys to agent
        ssh-add-all

        # List loaded keys
        ssh-list

        # Test GitHub connection
        ssh-test-github

        # Generate new key
        ssh-keygen-ed25519 "your-email@example.com"
        ```

        ## Configuration

        Edit module options in:
        /etc/nixos/modules/system/ssh-config.nix

        Available options:
        - kernelcore.ssh.enable
        - kernelcore.ssh.sshDir
        - kernelcore.ssh.personalKey
        - kernelcore.ssh.orgKey
        - kernelcore.ssh.serverKey
        - kernelcore.ssh.serverHost
        - kernelcore.ssh.serverUser

        ## Security Notes

        - ForwardAgent is disabled by default
        - Only modern crypto algorithms allowed
        - Keys are added to agent with 1h timeout
        - Connection multiplexing enabled for performance
        - Known hosts verified to prevent MITM

        ## Troubleshooting

        ### Key not being used
        ```bash
        ssh -vvv git@github.com-marcos
        ```

        ### Agent not running
        ```bash
        eval $(ssh-agent)
        ssh-add-all
        ```

        ### Wrong key being used
        ```bash
        # Make sure IdentitiesOnly is set in config
        ssh -o IdentitiesOnly=yes -i ~/.ssh/specific_key git@github.com
        ```
      '';
      mode = "0644";
    };
  };
}
