# ============================================
# Hyprland Modular - Keybinding System
# ============================================
# Modular keybindings organized by category:
# - core: Essential window/app management
# - window: Window manipulation
# - workspace: Workspace navigation
# - media: Media keys and volume
# - screenshot: Screenshot utilities
# - power: Lock/suspend/shutdown
# - custom: User-defined bindings
# ============================================
{
  lib,
  pkgs,
  hyprLib,
  cfg,
}:

let
  inherit (hyprLib) mkWorkspaceBinds mkDirectionalBinds screenshotCommands;

  mainMod = cfg.mainMod;
  terminal = cfg.terminal.primary;
  terminal2 = cfg.terminal.secondary;
  launcher = cfg.launcher;
  fileManager = cfg.fileManager;

  # Build terminal command with multiplexer
  terminalCmd =
    session:
    if cfg.terminal.multiplexer == "zellij" then
      "${terminal} -e zellij attach --create ${session}"
    else if cfg.terminal.multiplexer == "tmux" then
      "${terminal} -e tmux new-session -A -s ${session}"
    else
      terminal;

  terminalCmd2 =
    session:
    if cfg.terminal.multiplexer == "zellij" then
      "${terminal2} -e zellij attach --create ${session}"
    else if cfg.terminal.multiplexer == "tmux" then
      "${terminal2} -e tmux new-session -A -s ${session}"
    else
      terminal2;

in
rec {
  # ==========================================
  # BINDING MODULES
  # ==========================================

  modules = {
    # ----------------------------------------
    # CORE - Essential bindings
    # ----------------------------------------
    core = [
      # Terminal launchers
      "${mainMod}, Return, exec, ${terminalCmd "main"}"
      "${mainMod} SHIFT, Return, exec, ${terminalCmd2 "alt"}"
      "${mainMod} CTRL, Return, exec, ${terminal}"
      "${mainMod} CTRL SHIFT, Return, exec, ${terminal2}"
      "${mainMod} ALT, Return, exec, foot" # Emergency fallback

      # Application launcher
      "${mainMod}, D, exec, ${launcher} --show drun"
      "${mainMod} SHIFT, D, exec, ${launcher} --show run"

      # File manager
      "${mainMod}, E, exec, ${fileManager}"

      # Kill window
      "${mainMod}, Q, killactive"

      # Exit Hyprland
      "${mainMod} SHIFT, M, exit"

      # Reload waybar
      "${mainMod} SHIFT, W, exec, killall waybar; waybar &"

      # Clipboard history
      "${mainMod}, C, exec, cliphist list | ${launcher} --dmenu | cliphist decode | wl-copy"

      # Color picker
      "${mainMod} SHIFT, C, exec, hyprpicker -a"

      # Notification management
      "${mainMod}, N, exec, makoctl dismiss"
      "${mainMod} SHIFT, N, exec, makoctl dismiss --all"
    ];

    # ----------------------------------------
    # WINDOW - Window manipulation
    # ----------------------------------------
    window = lib.flatten [
      # Fullscreen modes
      [
        "${mainMod}, F, fullscreen, 0"
        "${mainMod} SHIFT, F, fullscreen, 1"
      ]

      # Floating & layout
      [
        "${mainMod}, V, togglefloating"
        "${mainMod}, P, pseudo"
        "${mainMod}, J, togglesplit"
        "${mainMod}, Z, togglesplit"
      ]

      # Window groups
      [
        "${mainMod}, G, togglegroup"
        "${mainMod}, Tab, changegroupactive, f"
        "${mainMod} SHIFT, Tab, changegroupactive, b"
      ]

      # Pin & center
      [
        "${mainMod}, X, pin"
        "${mainMod} ALT, C, centerwindow"
      ]

      # Focus navigation (arrows)
      (mkDirectionalBinds mainMod "movefocus")

      # Move windows (arrows)
      (mkDirectionalBinds "${mainMod} SHIFT" "movewindow")

      # Focus urgent
      [
        "${mainMod}, U, focusurgentorlast"
      ]

      # Force kill
      [
        "${mainMod} SHIFT CTRL, Q, exec, hyprctl kill"
      ]
    ];

    # ----------------------------------------
    # WORKSPACE - Workspace navigation
    # ----------------------------------------
    workspace = lib.flatten [
      # Switch to workspace (1-10)
      (mkWorkspaceBinds mainMod cfg.workspaces.count)

      # Quick workspace switching
      [
        "${mainMod} ALT, left, workspace, e-1"
        "${mainMod} ALT, right, workspace, e+1"
      ]

      # Mouse scroll workspaces
      [
        "${mainMod}, mouse_down, workspace, e+1"
        "${mainMod}, mouse_up, workspace, e-1"
      ]

      # Special workspaces
      (lib.flatten (
        map (sw: [
          "${sw.modifiers}, ${sw.key}, togglespecialworkspace, ${sw.name}"
          "${sw.modifiers} SHIFT, ${sw.key}, movetoworkspace, special:${sw.name}"
        ]) cfg.workspaces.specialWorkspaces
      ))
    ];

    # ----------------------------------------
    # MEDIA - Media keys and volume
    # ----------------------------------------
    media = [
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
      ", XF86AudioStop, exec, playerctl stop"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    ];

    # ----------------------------------------
    # SCREENSHOT - Screenshot utilities
    # ----------------------------------------
    screenshot = [
      # Region to swappy (annotation)
      ", Print, exec, ${screenshotCommands.regionToSwappy}"

      # Fullscreen to swappy
      "SHIFT, Print, exec, ${screenshotCommands.fullToSwappy}"

      # Region to file
      "CTRL, Print, exec, ${screenshotCommands.regionToFile "~/Pictures"}"

      # Fullscreen to file
      "CTRL SHIFT, Print, exec, ${screenshotCommands.fullToFile "~/Pictures"}"

      # Region to clipboard
      "${mainMod}, Print, exec, ${screenshotCommands.regionToClipboard}"
    ];

    # ----------------------------------------
    # POWER - Lock/suspend/shutdown
    # ----------------------------------------
    power = [
      # Lock screen
      "${mainMod} CTRL, L, exec, hyprlock"

      # Force idle
      "${mainMod} CTRL ALT, L, exec, hyprctl dispatch forceidle"

      # Logout menu
      "${mainMod}, Escape, exec, wlogout -p layer-shell"

      # Quick power actions
      "${mainMod} SHIFT, Escape, exec, systemctl suspend"
      "${mainMod} CTRL SHIFT, Escape, exec, systemctl reboot"
      "${mainMod} ALT SHIFT, Escape, exec, systemctl poweroff"
    ];

    # ----------------------------------------
    # CUSTOM - Placeholder for user bindings
    # ----------------------------------------
    custom = [ ];
  };

  # ==========================================
  # REPEAT BINDINGS (binde)
  # ==========================================
  repeatBinds = [
    # Resize with arrows
    "${mainMod} CTRL, left, resizeactive, -50 0"
    "${mainMod} CTRL, right, resizeactive, 50 0"
    "${mainMod} CTRL, up, resizeactive, 0 -50"
    "${mainMod} CTRL, down, resizeactive, 0 50"

    # Resize with vim keys
    "${mainMod} CTRL, h, resizeactive, -50 0"
    "${mainMod} CTRL, l, resizeactive, 50 0"
    "${mainMod} CTRL, k, resizeactive, 0 -50"
    "${mainMod} CTRL, j, resizeactive, 0 50"

    # Volume
    ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
    ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

    # Brightness
    ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
    ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
  ];

  # ==========================================
  # MOUSE BINDINGS (bindm)
  # ==========================================
  mouseBinds = [
    "${mainMod}, mouse:272, movewindow"
    "${mainMod}, mouse:273, resizewindow"
  ];

  # ==========================================
  # RESOLVER - Combine selected modules
  # ==========================================
  resolveModules = moduleList: lib.flatten (map (m: modules.${m} or [ ]) moduleList);
}
