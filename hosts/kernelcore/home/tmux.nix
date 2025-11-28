{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = false;
    terminal = "screen-256color";
    keyMode = "vi";
    mouse = true;

    extraConfig = ''
      # Prefix key
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Split panes with intuitive keys
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Easy pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Reload config
      bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

      # Status bar
      set -g status-position bottom
      set -g status-bg black
      set -g status-fg white
      set -g status-left '#[fg=green,bold]#H #[fg=blue]| '
      set -g status-right '#[fg=yellow]#(uptime | cut -d "," -f 1) #[fg=white]| %H:%M'
      set -g status-interval 60

      # Window status
      setw -g window-status-current-style 'fg=black bg=green bold'

      # Start windows at 1, not 0
      set -g base-index 1
      setw -g pane-base-index 1
    '';
  };
}
