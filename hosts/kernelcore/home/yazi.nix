# ============================================
# Yazi File Manager - Advanced Configuration
# ============================================
# Professional file manager with:
# - Advanced keybindings for workflow
# - Git integration
# - Bulk operations
# - Preview enhancements
# - SSH/remote file operations
# - AI-assisted file organization (via agent-hub)
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Workflow directories
  dirs = {
    docs = "~/Documents/Processed";
    images = "~/Pictures/Processed";
    downloads = "~/Downloads";
    trash = "~/.local/share/Trash/files";
    projects = "~/dev/projects";
    nixos = "/etc/nixos";
  };

  # Remote hosts for quick file transfer
  remotes = {
    laptop = "cypher@192.168.15.9";
    server = "kernelcore@server.local";
  };

  # Helper function for move commands
  mkMoveCmd = dir: "shell 'mkdir -p ${dir} && mv \"$@\" ${dir}/' --confirm";
  mkCopyCmd = dir: "shell 'mkdir -p ${dir} && cp -r \"$@\" ${dir}/' --confirm";
in
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    # ============================================
    # SETTINGS (yazi.toml)
    # ============================================
    settings = {
      manager = {
        show_hidden = false;
        sort_by = "mtime";
        sort_reverse = true;
        sort_sensitive = false;
        sort_dir_first = true;
        linemode = "size"; # Show file sizes inline
        show_symlink = true;
      };

      preview = {
        tab_size = 2;
        max_width = 1200;
        max_height = 1000;
        cache_dir = "${config.home.homeDirectory}/.cache/yazi";
        image_quality = 90;
        sixel_fraction = 15; # For terminal image preview
      };

      opener = {
        edit = [
          {
            run = "nvim \"$@\"";
            block = true;
            desc = "Neovim";
          }
          {
            run = "code \"$@\"";
            desc = "VS Code";
          }
        ];
        open = [
          {
            run = "xdg-open \"$@\"";
            desc = "Open (default)";
          }
        ];
        reveal = [
          {
            run = "nemo --select \"$@\"";
            desc = "Reveal in Nemo";
          }
        ];
        extract = [
          {
            run = "unar \"$@\"";
            desc = "Extract here";
          }
        ];
        play = [
          {
            run = "mpv --force-window \"$@\"";
            orphan = true;
            desc = "Play (mpv)";
          }
        ];
      };

      open = {
        rules = [
          # Text files
          {
            name = "*.md";
            use = [
              "edit"
              "open"
            ];
          }
          {
            name = "*.txt";
            use = [
              "edit"
              "open"
            ];
          }
          {
            name = "*.nix";
            use = [ "edit" ];
          }
          {
            name = "*.py";
            use = [ "edit" ];
          }
          {
            name = "*.rs";
            use = [ "edit" ];
          }
          {
            name = "*.go";
            use = [ "edit" ];
          }
          {
            name = "*.js";
            use = [ "edit" ];
          }
          {
            name = "*.ts";
            use = [ "edit" ];
          }
          {
            name = "*.json";
            use = [ "edit" ];
          }
          {
            name = "*.yaml";
            use = [ "edit" ];
          }
          {
            name = "*.toml";
            use = [ "edit" ];
          }

          # Archives
          {
            name = "*.zip";
            use = [
              "extract"
              "open"
            ];
          }
          {
            name = "*.tar*";
            use = [
              "extract"
              "open"
            ];
          }
          {
            name = "*.gz";
            use = [
              "extract"
              "open"
            ];
          }
          {
            name = "*.rar";
            use = [
              "extract"
              "open"
            ];
          }
          {
            name = "*.7z";
            use = [
              "extract"
              "open"
            ];
          }

          # Media
          {
            name = "*.mp4";
            use = [
              "play"
              "open"
            ];
          }
          {
            name = "*.mkv";
            use = [
              "play"
              "open"
            ];
          }
          {
            name = "*.webm";
            use = [
              "play"
              "open"
            ];
          }
          {
            name = "*.mp3";
            use = [
              "play"
              "open"
            ];
          }
          {
            name = "*.flac";
            use = [
              "play"
              "open"
            ];
          }

          # Default
          {
            name = "*";
            use = [
              "open"
              "edit"
            ];
          }
        ];
      };
    };

    # ============================================
    # KEYMAP (keymap.toml)
    # ============================================
    keymap = {
      manager.prepend_keymap = [
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # QUICK TRIAGE (1-5 keys)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [ "1" ];
          run = mkMoveCmd dirs.docs;
          desc = "Move → Documents";
        }
        {
          on = [ "2" ];
          run = mkMoveCmd dirs.images;
          desc = "Move → Images";
        }
        {
          on = [ "3" ];
          run = mkMoveCmd dirs.projects;
          desc = "Move → Projects";
        }
        {
          on = [ "4" ];
          run = mkMoveCmd dirs.trash;
          desc = "Move → Trash";
        }
        {
          on = [ "5" ];
          run = mkMoveCmd dirs.downloads;
          desc = "Move → Downloads";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # NAVIGATION
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [
            "g"
            "h"
          ];
          run = "cd ~";
          desc = "Go home";
        }
        {
          on = [
            "g"
            "d"
          ];
          run = "cd ~/Downloads";
          desc = "Go downloads";
        }
        {
          on = [
            "g"
            "p"
          ];
          run = "cd ~/dev/projects";
          desc = "Go projects";
        }
        {
          on = [
            "g"
            "n"
          ];
          run = "cd /etc/nixos";
          desc = "Go NixOS config";
        }
        {
          on = [
            "g"
            "c"
          ];
          run = "cd ~/.config";
          desc = "Go config";
        }
        {
          on = [
            "g"
            "t"
          ];
          run = "cd /tmp";
          desc = "Go temp";
        }
        {
          on = [
            "g"
            "m"
          ];
          run = "cd /var/lib/ml-models";
          desc = "Go ML models";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # FILE OPERATIONS
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [ "<Space>" ];
          run = "toggle";
          desc = "Toggle selection";
        }
        {
          on = [ "V" ];
          run = "visual_mode";
          desc = "Visual mode";
        }
        {
          on = [ "a" ];
          run = "select_all --state=true";
          desc = "Select all";
        }
        {
          on = [ "A" ];
          run = "select_all --state=none";
          desc = "Deselect all";
        }

        # Bulk operations
        {
          on = [
            "b"
            "d"
          ];
          run = "remove --permanently";
          desc = "Bulk delete (permanent)";
        }
        {
          on = [
            "b"
            "r"
          ];
          run = "shell 'for f in \"$@\"; do mv \"$f\" \"${dirs.trash}/\"; done' --confirm";
          desc = "Bulk → Trash";
        }
        {
          on = [
            "b"
            "c"
          ];
          run = "shell 'wl-copy < \"$1\"' --confirm";
          desc = "Copy content to clipboard";
        }

        # Rename operations
        {
          on = [ "r" ];
          run = "rename --cursor=before_ext";
          desc = "Rename (before ext)";
        }
        {
          on = [ "R" ];
          run = "rename --cursor=end";
          desc = "Rename (full)";
        }
        {
          on = [
            "c"
            "w"
          ];
          run = "shell 'vidir \"$@\"' --confirm --block";
          desc = "Bulk rename (vidir)";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # PREVIEW & INFO
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [ "i" ];
          run = "shell 'bat --paging=always \"$1\"' --block";
          desc = "View with bat";
        }
        {
          on = [ "I" ];
          run = "shell 'file \"$1\" && stat \"$1\"' --block";
          desc = "File info";
        }
        {
          on = [ "<C-p>" ];
          run = "peek";
          desc = "Toggle preview";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # GIT OPERATIONS
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [
            "g"
            "s"
          ];
          run = "shell 'lazygit' --block";
          desc = "Lazygit";
        }
        {
          on = [
            "g"
            "a"
          ];
          run = "shell 'git add \"$@\"' --confirm";
          desc = "Git add selected";
        }
        {
          on = [
            "g"
            "r"
          ];
          run = "shell 'git restore \"$@\"' --confirm";
          desc = "Git restore";
        }
        {
          on = [
            "g"
            "l"
          ];
          run = "shell 'git log --oneline -20 -- \"$1\"' --block";
          desc = "Git log (file)";
        }
        {
          on = [
            "g"
            "b"
          ];
          run = "shell 'git blame \"$1\" | bat' --block";
          desc = "Git blame";
        }
        {
          on = [
            "g"
            "d"
          ];
          run = "shell 'git diff \"$1\" | bat --language=diff' --block";
          desc = "Git diff";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # REMOTE OPERATIONS (SSH)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [
            "<Leader>"
            "s"
            "l"
          ];
          run = "shell 'scp -rp \"$@\" ${remotes.laptop}:~/' --confirm";
          desc = "Send → Laptop";
        }
        {
          on = [
            "<Leader>"
            "s"
            "s"
          ];
          run = "shell 'scp -rp \"$@\" ${remotes.server}:~/' --confirm";
          desc = "Send → Server";
        }
        {
          on = [
            "<Leader>"
            "r"
            "l"
          ];
          run = "shell 'scp -rp ${remotes.laptop}:\"$(ssh ${remotes.laptop} \"cd ~ && fzf\")\" .' --confirm";
          desc = "Receive ← Laptop";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # ARCHIVE OPERATIONS
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [
            "z"
            "z"
          ];
          run = "shell 'zip -r \"$1.zip\" \"$@\"' --confirm";
          desc = "Create .zip";
        }
        {
          on = [
            "z"
            "t"
          ];
          run = "shell 'tar -czvf \"$1.tar.gz\" \"$@\"' --confirm";
          desc = "Create .tar.gz";
        }
        {
          on = [
            "z"
            "x"
          ];
          run = "shell 'unar \"$1\"' --confirm";
          desc = "Extract archive";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # TERMINAL & EXTERNAL
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [ ":" ];
          run = "shell --interactive";
          desc = "Shell command";
        }
        {
          on = [ "!" ];
          run = "shell '$SHELL' --block";
          desc = "Open shell here";
        }
        {
          on = [ "e" ];
          run = "open";
          desc = "Open with default";
        }
        {
          on = [ "E" ];
          run = "shell 'nvim \"$@\"' --block";
          desc = "Edit in Neovim";
        }
        {
          on = [ "<C-t>" ];
          run = "shell 'alacritty --working-directory=\"$(pwd)\"' --confirm";
          desc = "Terminal here";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # SPECIAL OPERATIONS
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [
            "y"
            "p"
          ];
          run = "shell 'echo \"$PWD/$1\" | wl-copy' --confirm";
          desc = "Copy path";
        }
        {
          on = [
            "y"
            "n"
          ];
          run = "shell 'echo \"$1\" | wl-copy' --confirm";
          desc = "Copy filename";
        }
        {
          on = [
            "y"
            "d"
          ];
          run = "shell 'echo \"$PWD\" | wl-copy' --confirm";
          desc = "Copy directory";
        }

        # Permissions
        {
          on = [
            "c"
            "x"
          ];
          run = "shell 'chmod +x \"$@\"' --confirm";
          desc = "Make executable";
        }
        {
          on = [
            "c"
            "X"
          ];
          run = "shell 'chmod -x \"$@\"' --confirm";
          desc = "Remove executable";
        }

        # Find/Search
        {
          on = [ "/" ];
          run = "find --smart";
          desc = "Find by name";
        }
        {
          on = [ "f" ];
          run = "filter --smart";
          desc = "Filter files";
        }
        {
          on = [ "F" ];
          run = "shell 'rg --files | fzf --preview=\"bat --color=always {}\" | xargs -r nvim' --block";
          desc = "Fuzzy find + edit";
        }

        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        # AI INTEGRATION (via Agent Hub)
        # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        {
          on = [
            "<Leader>"
            "a"
            "i"
          ];
          run = "shell '$HOME/.config/agent-hub/agent-launcher.sh' --confirm";
          desc = "Open Agent Hub";
        }
        {
          on = [
            "<Leader>"
            "a"
            "q"
          ];
          run = "shell '$HOME/.config/agent-hub/quick-prompt.sh' --confirm";
          desc = "AI Quick Prompt";
        }
      ];

      # Tasks view keymaps
      tasks.prepend_keymap = [
        {
          on = [ "k" ];
          run = "arrow -1";
          desc = "Move up";
        }
        {
          on = [ "j" ];
          run = "arrow 1";
          desc = "Move down";
        }
      ];
    };

    # ============================================
    # THEME (theme.toml) - Glassmorphism colors
    # ============================================
    theme = {
      manager = {
        cwd = {
          fg = "#00d4ff";
        };
        hovered = {
          bg = "#2a2a3e";
        };
        preview_hovered = {
          underline = true;
        };
      };

      status = {
        separator_open = "";
        separator_close = "";
      };

      filetype = {
        rules = [
          # Config files
          {
            name = "*.nix";
            fg = "#7c3aed";
          }
          {
            name = "*.toml";
            fg = "#f59e0b";
          }
          {
            name = "*.yaml";
            fg = "#f59e0b";
          }
          {
            name = "*.json";
            fg = "#f59e0b";
          }

          # Programming
          {
            name = "*.py";
            fg = "#3b82f6";
          }
          {
            name = "*.rs";
            fg = "#f97316";
          }
          {
            name = "*.go";
            fg = "#06b6d4";
          }
          {
            name = "*.js";
            fg = "#facc15";
          }
          {
            name = "*.ts";
            fg = "#3b82f6";
          }

          # Documents
          {
            name = "*.md";
            fg = "#10b981";
          }
          {
            name = "*.txt";
            fg = "#a1a1aa";
          }

          # Media
          {
            name = "*.jpg";
            fg = "#ec4899";
          }
          {
            name = "*.png";
            fg = "#ec4899";
          }
          {
            name = "*.mp4";
            fg = "#8b5cf6";
          }
          {
            name = "*.mp3";
            fg = "#14b8a6";
          }

          # Archives
          {
            name = "*.zip";
            fg = "#ef4444";
          }
          {
            name = "*.tar*";
            fg = "#ef4444";
          }
          {
            name = "*.gz";
            fg = "#ef4444";
          }
        ];
      };
    };
  };

  # ============================================
  # ADDITIONAL PACKAGES FOR YAZI
  # ============================================
  home.packages = with pkgs; [
    # Preview tools
    bat # Better cat
    eza # Better ls
    ripgrep # Fast grep
    fd # Fast find
    fzf # Fuzzy finder

    # File operations
    unar # Universal archive extractor
    moreutils # vidir for bulk rename
    file # File type detection

    # Media preview
    ffmpegthumbnailer # Video thumbnails
    imagemagick # Image processing
    poppler-utils # PDF preview (renamed from poppler_utils)

    # Git integration
    lazygit # Terminal git UI
  ];
}
