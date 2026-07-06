{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# VSCode Remote SSH Extension Configuration
# ============================================================
# Adds Remote SSH extension to all VSCode-like editors:
# - VSCode
# - VSCodium
# - Cursor
# - Windsurf
# ============================================================

with lib;

let
  cfg = config.programs.vscode-remote-ssh;
in
{
  options.programs.vscode-remote-ssh = {
    enable = mkEnableOption "Enable Remote SSH extension for VSCode-like editors";

    installFor = mkOption {
      type = types.listOf (
        types.enum [
          "vscode"
          "vscodium"
          "cursor"
          "windsurf"
        ]
      );
      default = [
        "vscode"
        "cursor"
        "windsurf"
      ];
      description = "List of editors to install Remote SSH extension for";
    };
  };

  config = mkIf cfg.enable {
    # Install VSCode with Remote SSH extension via home-manager
    home-manager.users.kernelcore = mkIf (builtins.elem "vscode" cfg.installFor) {
      programs.vscode = {
        enable = true;
        profiles.default.extensions = with pkgs.vscode-extensions; [
          ms-vscode-remote.remote-ssh
        ];
      };
    };

    # For Cursor and Windsurf, we need to install the extension manually
    # via activation script since they're not managed by home-manager
    system.activationScripts.install-remote-ssh-extensions =
      mkIf
        (builtins.any (editor: builtins.elem editor cfg.installFor) [
          "cursor"
          "windsurf"
        ])
        ''
          # Install Remote SSH extension for Cursor
          ${optionalString (builtins.elem "cursor" cfg.installFor) ''
            if [ -d "${config.system.user.homeDir}/.cursor" ] && command -v cursor >/dev/null 2>&1; then
              echo "Installing Remote SSH extension for Cursor..."
              su - ${config.system.user.username} -c "cursor --install-extension ms-vscode-remote.remote-ssh --force" || true
            fi
          ''}

          # Install Remote SSH extension for Windsurf
          ${optionalString (builtins.elem "windsurf" cfg.installFor) ''
            if [ -d "${config.system.user.homeDir}/.windsurf" ] && command -v windsurf >/dev/null 2>&1; then
              echo "Installing Remote SSH extension for Windsurf..."
              su - ${config.system.user.username} -c "windsurf --install-extension ms-vscode-remote.remote-ssh --force" || true
            fi
          ''}
        '';

    # Add helpful aliases
    environment.shellAliases = {
      "vscode-ssh" = "code --remote ssh-remote+";
      "cursor-ssh" = "cursor --remote ssh-remote+";
      "windsurf-ssh" = "windsurf --remote ssh-remote+";
    };

    # Documentation
    environment.etc."nixos-vscode-remote/README.md" = {
      text = ''
        # Remote SSH Extension Configuration

        The Remote SSH extension has been installed for: ${concatStringsSep ", " cfg.installFor}

        ## Usage

        ### Connect to remote host

        ```bash
        # Using VSCode
        code --remote ssh-remote+voidnx /workspace

        # Using Cursor
        cursor --remote ssh-remote+voidnx /workspace

        # Using Windsurf
        windsurf --remote ssh-remote+voidnx /workspace
        ```

        ### Or use GUI:
        1. Open Command Palette (Ctrl+Shift+P)
        2. Type "Remote-SSH: Connect to Host"
        3. Select your configured host from ~/.ssh/config

        ## Available SSH Hosts

        Based on your ~/.ssh/config:
        - voidnx (Brev Kubernetes environment)
        - github.com (GitHub)
        - gitlab.com (GitLab)
        - desktop (Local desktop builder)
        - laptop (Local laptop)

        ## Troubleshooting

        ### Extension not showing up?
        ```bash
        # List installed extensions
        code --list-extensions | grep remote-ssh
        cursor --list-extensions | grep remote-ssh
        windsurf --list-extensions | grep remote-ssh
        ```

        ### Manual installation
        ```bash
        # Install for VSCode
        code --install-extension ms-vscode-remote.remote-ssh

        # Install for Cursor
        cursor --install-extension ms-vscode-remote.remote-ssh

        # Install for Windsurf
        windsurf --install-extension ms-vscode-remote.remote-ssh
        ```

        ## Configuration

        Edit module options in:
        /etc/nixos/modules/applications/vscode-remote-ssh.nix

        Available options:
        - programs.vscode-remote-ssh.enable
        - programs.vscode-remote-ssh.installFor

        ## Brev Integration

        To connect to your Brev environment (voidnx):
        1. Make sure you've run `brev shell voidnx` at least once
        2. Open VSCode/Cursor/Windsurf
        3. Press Ctrl+Shift+P
        4. Type "Remote-SSH: Connect to Host"
        5. Select "voidnx"
        6. The editor will connect to your Kubernetes pod with GPU access!

        ## Security Notes

        - Remote SSH uses your ~/.ssh/config for authentication
        - Uses the same SSH keys configured in your system
        - All connections are encrypted via SSH
        - No additional credentials needed (uses your SSH keys)
      '';
      mode = "0644";
    };
  };
}
