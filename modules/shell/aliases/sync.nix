{ config, pkgs, ... }:

{
  # Rsync aliases for laptop-desktop synchronization
  environment.shellAliases = {
    # ════════════════════════════════════════════════════════════════
    # RSYNC - Laptop ↔ Desktop Sync
    # ════════════════════════════════════════════════════════════════

    # Sync TO desktop
    "sync-to" = "/etc/nixos/scripts/sync-to-desktop.sh";
    "sync-push" = "/etc/nixos/scripts/sync-to-desktop.sh";
    "push-desktop" = "/etc/nixos/scripts/sync-to-desktop.sh";

    # Sync FROM desktop
    "sync-from" = "/etc/nixos/scripts/sync-from-desktop.sh";
    "sync-pull" = "/etc/nixos/scripts/sync-from-desktop.sh";
    "pull-desktop" = "/etc/nixos/scripts/sync-from-desktop.sh";

    # Common sync shortcuts
    "sync-nixos" = "sync-to /etc/nixos --no-delete";
    "sync-projects" = "sync-to ~/projects";
    "sync-docs" = "sync-to ~/Documents";
    "sync-home" =
      "sync-to ~ --exclude='*' --include='.*' --include='.config/' --include='.bashrc' --include='.zshrc'";

    # Bidirectional sync (careful!)
    "sync-both-nixos" = "sync-to /etc/nixos --no-delete && sync-from nixos --no-delete";

    # Dry-run helpers
    "sync-test" = "sync-to"; # Add --dry-run manually
    "sync-check" = "rsync -avzn"; # Manual dry-run

    # Direct rsync commands for advanced usage
    "rsync-desktop" = "rsync -avz --progress";
    "rsync-safe" = "rsync -avzn --progress"; # Always dry-run
  };
}
