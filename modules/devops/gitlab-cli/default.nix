# /modules/devops/gitlab-cli/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg =
    config.programs.glab-custom or {
      enable = false;
      tokenFile = "/run/keys/gitlab-token"; # ou ~/.local/secrets/gitlab.token
      defaultNamespaceId = 1234; # muda pro teu grupo
    };

  glab-pkgs = with pkgs; [
    glab
    jq
    httpie
  ];

  glab-aliases = ''
    export GITLAB_TOKEN=''$(cat ${cfg.tokenFile} 2>/dev/null || echo "")

    glab-new() {
      local name="''$1"
      local ns="''${2:-${toString cfg.defaultNamespaceId}}"
      [ -z "''$name" ] && echo "❌ Uso: glab-new <nome> [namespace_id]" && return 1
      glab api POST projects \
        --field name="''$name" \
        --field namespace_id="''$ns" \
        --field visibility="internal" \
        --field initialize_with_readme=false \
        --field container_registry_enabled=false \
        --field issues_enabled=false \
        --field merge_requests_enabled=true \
        --field wiki_enabled=false \
        --field packages_enabled=false \
        --field printing_merge_request_link_enabled=false \
      | jq -r '.web_url + " ✅"'
    }

    alias glab-ls='glab api projects --field membership=true --field per_page=50 | jq -r ".[].path_with_namespace"'
    alias glab-vars='glab api projects/''$GITLAB_PROJECT_ID/variables | jq ".[].key"'
    alias glab-pipelines='glab ci list --limit 10'
  '';
in
{
  options.programs.glab-custom = {
    enable = lib.mkEnableOption "Enable custom glab CLI setup with aliases and API helpers";
    tokenFile = lib.mkOption {
      type = lib.types.path;
      default = "/home/kernelcore/.local/secrets/gitlab.token";
      description = "Caminho para o token do GitLab";
    };
    defaultNamespaceId = lib.mkOption {
      type = lib.types.int;
      default = 1234;
      description = "Default namespace/group ID para criação de projetos";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = glab-pkgs;

    programs.zsh.initExtra = glab-aliases;

    # Opcional: copiar scripts úteis para ~/bin
    home.file.".local/bin/glab-new".text = ''
      #!/usr/bin/env bash
      ${builtins.readFile ./lib/glab-new-project.sh}
    '';
    home.file.".local/bin/glab-new".executable = true;
  };
}
