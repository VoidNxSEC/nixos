{ config, pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# USUÁRIOS — kernelcore (grupos, chaves SSH, pacotes de usuário)
# ═══════════════════════════════════════════════════════════

{
  users.groups.kernelcore = { };
  users.users.kernelcore = {
    isNormalUser = true;
    description = "kernel";
    shell = pkgs.zsh;
    group = "kernelcore";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "nvidia"
      "docker"
      "render"
      "libvirtd"
      "kvm"
      "mcp-shared"
      "input"
      "plugdev"
    ];
    hashedPasswordFile = "/etc/nixos/sec/user-password";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIqr4XMgOMg94E2101vACedmzpGGoDvP7yhaPZ7bBAhQ sec@voidnxlabs.com"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG5StF4nUzkEsUei88BstktP/Q/g8BvlHeWnEDD+ii/jB7Fs4v4imG05tJU/jC8/ax2FFRSwoBRt7tH6RDp4Dys= user@iphone"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBE2jQWzD7N9sMWW+UKBNuxzS5v3Dt5g6UbZ/kd49b7XJugBLma8152DogVrblUxhPqfQfcCVrMHNHFlIkXAB9w= voidnxlabs"
    ];
    packages = with pkgs; [
      obsidian
      sssd
      vscodium
      gphoto2
      libimobiledevice
      devenv
      tailscale
      trezor-suite
      tmux
      starship
      terraform
      nushell
      azure-cli
      ibmcloud-cli
      glab
      mkdocs
      cachix
      python313Packages.mkdocs
      waybackurls
      hakrawler
      python313Packages.pyyaml
      google-chrome
      awscli
      cemu
      onlyoffice-desktopeditors
      google-cloud-sdk
      minikube
      kubernetes
      kubernetes-polaris
      kubernetes-helm
      kind
      git-lfs
      certbot
      flameshot
      # claude-code # FIXME: upstream nixpkgs 2.1.88 tarball unpublished from npm (404)
      codex
      qbittorrent
      # vllm # FIXME: upstream nixpkgs broken patch for llama-cpp-python (406)
      alacritty
      xclip
      glab
      gh
      wrangler
      termius
      codeberg-cli
      zathura
      evince
      sioyek
      kdePackages.okular

      cairo-lang
      metabase

      # Custom wrapper for brev to work with read-only .ssh/config
      (pkgs.writeShellScriptBin "brev" ''
        #!/usr/bin/env bash

        # Original brev binary path
        BREV_BIN="${config.kernelcore.packages."brev-cli".package}/bin/brev"

        # Real paths
        REAL_HOME="$HOME"
        BREV_HOME="$REAL_HOME/.brev"
        NIX_BREV_CONFIG="$REAL_HOME/.ssh/brev_config"
        export BREV_NO_ANALYTICS="''${BREV_NO_ANALYTICS:-1}"

        # Usar um cache persistente para não matar processos em background (ex: Fleet IDE)
        FAKE_HOME="$REAL_HOME/.cache/brev_fake_home"

        # Setup do ambiente Fake
        mkdir -p "$FAKE_HOME/.ssh"
        echo 'Include "/home/kernelcore/.brev/ssh_config"' > "$FAKE_HOME/.ssh/config"
        chmod 600 "$FAKE_HOME/.ssh/config"

        # Symlink do diretório .brev e de chaves conhecidas para não quebrar o handshake
        ln -sfn "$BREV_HOME" "$FAKE_HOME/.brev"

        # Função para extrair o config de forma limpa
        sync_config() {
            echo "[NixOS] Sincronizando o estado declarativo do Brev..." >&2
            # Rodamos um refresh silencioso no Fake Home para forçar a escrita do arquivo
            HOME="$FAKE_HOME" "$BREV_BIN" refresh < /dev/null > /dev/null 2>&1

            if [ -f "$BREV_HOME/ssh_config" ]; then
                # Substitui o caminho do cache persistente pelo real e gera o arquivo final
                sed "s|$FAKE_HOME|$REAL_HOME|g" "$BREV_HOME/ssh_config" > "$NIX_BREV_CONFIG"
                chmod 600 "$NIX_BREV_CONFIG"
            fi
        }

        # Lógica de Roteamento
        case "$1" in
          login|start|create|provision|delete|reset|refresh|register|deregister|enable-ssh|grant-ssh|revoke-ssh|scale)
            # Executa o comando na sandbox, depois sincroniza os configs
            HOME="$FAKE_HOME" "$BREV_BIN" "$@" || EXIT_CODE=$?
            sync_config
            exit ''${EXIT_CODE:-0}
            ;;

          open|shell|ssh|exec|copy|cp|scp|port-forward)
            # Sincroniza o estado antes de comandos que dependem do SSH gerado pelo Brev
            sync_config

            # Executa o acesso remoto passando o FAKE_HOME persistente,
            # garantindo que IDEs não percam o File Descriptor depois.
            exec env HOME="$FAKE_HOME" "$BREV_BIN" "$@"
            ;;

          *)
            # Comandos read-only passam direto
            exec "$BREV_BIN" "$@"
            ;;
        esac
      '')
      slack
      gnome-console
      zed-editor
      cinnamon
      gnome-disk-utility
      rust-analyzer
      rustup
      terraform-providers.carlpett_sops
      terraform-providers.hashicorp_vault
      #anytype
      antigravity
      evince
      sillytavern
      koboldcpp
      lmstudio
    ];
  };

  users.extraGroups.docker.members = [
    "kernelcore"
    "nvidia"
  ];
}
