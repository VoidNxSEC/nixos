{
  config,
  pkgs,
  lib,
  ...
}:

let
  # =========================================================================
  # Git Deployment Scripts (Multi-Remote & Security Posture)
  # =========================================================================

  gp-deploy = pkgs.writeShellScriptBin "gp-deploy" ''
    if [ -z "$1" ]; then
      echo "Usage: gp-deploy <remote> [args...]"
      echo "Example: gp-deploy github --all"
      exit 1
    fi
    REMOTE=$1
    shift
    echo "[DEPLOY] Pushing to $REMOTE..."
    git push "$REMOTE" "$@"
  '';

  gp-all = pkgs.writeShellScriptBin "gp-all" ''
    echo "Deploying to all configured remotes for redundancy..."
    for remote in github gitlab codeberg selfhosted; do
      if git remote | grep -q "^$remote$"; then
        echo "========================================"
        echo "Pushing to $remote..."
        echo "========================================"
        git push "$remote" --all
        git push "$remote" --tags
      else
        echo "[SKIP] Remote '$remote' not configured."
      fi
    done
    echo "Multi-remote deployment completed."
  '';

  # =========================================================================
  # Disaster Recovery & Backup Scripts
  # =========================================================================

  git-backup = pkgs.writeShellScriptBin "git-backup" ''
    REPO_NAME=$(basename "$PWD")
    TIMESTAMP=$(date +%Y%m%d-%H%M)
    BUNDLE_NAME="''${REPO_NAME}-backup-''${TIMESTAMP}.bundle"

    echo "[BACKUP] Creating git bundle (offline full backup)..."
    git bundle create "$BUNDLE_NAME" --all

    if [ $? -eq 0 ]; then
      echo "========================================"
      echo "Backup successfully created: $PWD/$BUNDLE_NAME"
      echo "Store this safely or upload to your cloud storage."
      echo "========================================"
    else
      echo "[ERROR] Failed to create git bundle."
      exit 1
    fi
  '';

  nix-cache-push = pkgs.writeShellScriptBin "nix-cache-push" ''
    CACHE_NAME="''${1:-system-cache}"
    echo "[CACHE] Pushing build closures to binary cache ($CACHE_NAME)..."
    if [ -L result ]; then
      nix-store -qR result | cachix push "$CACHE_NAME"
    else
      echo "[ERROR] No 'result' symlink found in the current directory. Did you build?"
      exit 1
    fi
  '';

  # =========================================================================
  # Configuration Helper
  # =========================================================================

  git-setup-remotes = pkgs.writeShellScriptBin "git-setup-remotes" ''
    echo "Multi-Remote Setup Utility"
    echo "Note: Leave blank to skip a remote. You can re-run this anytime."

    setup_remote() {
      local name=$1
      local url=$2
      if [ -n "$url" ]; then
        if git remote | grep -q "^$name$"; then
          git remote set-url "$name" "$url"
          echo "  -> Updated remote '$name' with URL: $url"
        else
          git remote add "$name" "$url"
          echo "  -> Added remote '$name' with URL: $url"
        fi
      fi
    }

    read -p "GitHub URL (blank to skip): " GITHUB_URL
    read -p "GitLab URL (blank to skip): " GITLAB_URL
    read -p "Codeberg URL (blank to skip): " CODEBERG_URL
    read -p "Self-hosted URL (blank to skip): " SELFHOSTED_URL

    echo ""
    echo "Configuring remotes..."
    setup_remote "github" "$GITHUB_URL"
    setup_remote "gitlab" "$GITLAB_URL"
    setup_remote "codeberg" "$CODEBERG_URL"
    setup_remote "selfhosted" "$SELFHOSTED_URL"

    echo ""
    echo "Current git remotes:"
    git remote -v
  '';

in
{
  home.packages = [
    gp-deploy
    gp-all
    git-backup
    nix-cache-push
    git-setup-remotes
  ];
}
