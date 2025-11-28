{ lib, pkgs, ... }:

{
  # Hyprland configuration managed via Home Manager to keep keybinds in sync with Nix.
  home.file.".config/hypr/hyprland.conf".text = lib.mkDefault ''
    # ============================================
    # Hyprland Configuration
    # Optimized for NVIDIA + Alacritty + Zellij
    # ============================================

    # Monitor configuration
    monitor=,preferred,auto,1

    # ============================================
    # AUTOSTART
    # ============================================
    exec-once = waybar
    exec-once = dunst
    exec-once = /nix/store/$(ls /nix/store | grep polkit-gnome | head -1)/libexec/polkit-gnome-authentication-agent-1
    exec-once = nm-applet --indicator
    exec-once = swayidle -w timeout 300 'swaylock -f' timeout 600 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on'

    # ============================================
    # ENVIRONMENT VARIABLES (NVIDIA)
    # ============================================
    env = LIBVA_DRIVER_NAME,nvidia
    env = XDG_SESSION_TYPE,wayland
    env = GBM_BACKEND,nvidia-drm
    env = __GLX_VENDOR_LIBRARY_NAME,nvidia
    env = WLR_NO_HARDWARE_CURSORS,1
    env = NIXOS_OZONE_WL,1
    env = QT_QPA_PLATFORM,wayland
    env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
    env = GDK_BACKEND,wayland,x11

    # ============================================
    # INPUT CONFIGURATION
    # ============================================
    input {
        kb_layout = br
        kb_variant =
        kb_model =
        kb_options =
        kb_rules =

        follow_mouse = 1
        sensitivity = 1.0
        accel_profile = flat

        touchpad {
            natural_scroll = false
        }
    }

    # ============================================
    # GENERAL SETTINGS
    # ============================================
    general {
        gaps_in = 5
        gaps_out = 10
        border_size = 2
        col.active_border = rgba(7aa2f7ee) rgba(7fdbcaee) 45deg
        col.inactive_border = rgba(29323aaa)

        layout = dwindle

        allow_tearing = false
    }

    # ============================================
    # DECORATIONS
    # ============================================
    decoration {
        rounding = 8

        blur {
            enabled = true
            size = 5
            passes = 2
            new_optimizations = true
            xray = false
            ignore_opacity = true
        }

        active_opacity = 0.96
        inactive_opacity = 0.88
        fullscreen_opacity = 1.0
    }

    # ============================================
    # ANIMATIONS
    # ============================================
    animations {
        enabled = true

        bezier = myBezier, 0.05, 0.9, 0.1, 1.05
        bezier = smoothOut, 0.36, 0, 0.66, -0.56
        bezier = smoothIn, 0.25, 1, 0.5, 1

        animation = windows, 1, 5, myBezier, slide
        animation = windowsOut, 1, 4, smoothOut, slide
        animation = windowsMove, 1, 4, default
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, smoothIn
        animation = workspaces, 1, 6, default, slide
    }

    # ============================================
    # LAYOUTS
    # ============================================

    # Dwindle layout (similar to bspwm)
    dwindle {
        pseudotile = true
        preserve_split = true
        force_split = 2
    }

    # Master layout
    master {
        new_status = master
    }

    # ============================================
    # WINDOW RULES
    # ============================================
    windowrulev2 = float, class:^(pavucontrol)$
    windowrulev2 = float, class:^(nm-connection-editor)$
    windowrulev2 = float, class:^(thunar)$
    windowrulev2 = opacity 0.94 0.94, class:^(Alacritty)$
    windowrulev2 = opacity 0.94 0.94, class:^(kitty)$

    # ============================================
    # MISC SETTINGS
    # ============================================
    misc {
        force_default_wallpaper = 0
        disable_hyprland_logo = true
        disable_splash_rendering = true
        mouse_move_enables_dpms = true
        key_press_enables_dpms = true
        vrr = 1
    }

    # ============================================
    # KEYBINDINGS
    # ============================================

    # Main modifier
    $mainMod = SUPER

    # Applications
    bind = $mainMod, Return, exec, ${pkgs.alacritty}/bin/alacritty -e ${pkgs.zellij}/bin/zellij attach --create main
    bind = $mainMod, E, exec, nemo
    bind = $mainMod, D, exec, wofi --show drun
    bind = $mainMod SHIFT, D, exec, wofi --show run

    # Window management
    bind = $mainMod, Q, killactive
    bind = $mainMod, M, exit
    bind = $mainMod, F, fullscreen, 0
    bind = $mainMod, V, togglefloating
    bind = $mainMod, P, pseudo
    bind = $mainMod, J, togglesplit

    # Move focus with mainMod + arrow keys
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d

    # Move focus with mainMod + hjkl (vim-style)
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, l, movefocus, r
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, j, movefocus, d

    # Move windows with mainMod + SHIFT + arrow keys
    bind = $mainMod SHIFT, left, movewindow, l
    bind = $mainMod SHIFT, right, movewindow, r
    bind = $mainMod SHIFT, up, movewindow, u
    bind = $mainMod SHIFT, down, movewindow, d

    # Move windows with mainMod + SHIFT + hjkl
    bind = $mainMod SHIFT, h, movewindow, l
    bind = $mainMod SHIFT, l, movewindow, r
    bind = $mainMod SHIFT, k, movewindow, u
    bind = $mainMod SHIFT, j, movewindow, d

    # Resize windows with mainMod + CTRL + arrow keys
    binde = $mainMod CTRL, left, resizeactive, -50 0
    binde = $mainMod CTRL, right, resizeactive, 50 0
    binde = $mainMod CTRL, up, resizeactive, 0 -50
    binde = $mainMod CTRL, down, resizeactive, 0 50

    # Resize windows with mainMod + CTRL + hjkl
    binde = $mainMod CTRL, h, resizeactive, -50 0
    binde = $mainMod CTRL, l, resizeactive, 50 0
    binde = $mainMod CTRL, k, resizeactive, 0 -50
    binde = $mainMod CTRL, j, resizeactive, 0 50

    # Switch workspaces with mainMod + [0-9]
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10

    # Move active window to workspace with mainMod + SHIFT + [0-9]
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10

    # Scroll through workspaces with mainMod + scroll
    bind = $mainMod, mouse_down, workspace, e+1
    bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    # Screenshot utilities
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = SHIFT, Print, exec, grim - | wl-copy
    bind = CTRL, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

    # Media controls
    bind = , XF86AudioPlay, exec, playerctl play-pause
    bind = , XF86AudioNext, exec, playerctl next
    bind = , XF86AudioPrev, exec, playerctl previous
    bind = , XF86AudioStop, exec, playerctl stop

    # Volume controls
    binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

    # Lock screen
    bind = $mainMod, L, exec, swaylock -f
  '';
}
