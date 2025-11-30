# ============================================
# Wlogout - Glassmorphism Logout Menu
# ============================================
# Premium frosted glass logout menu with:
# - 2x3 glass button grid
# - Icon animations
# - Glow hover states
# - Keyboard navigation
# ============================================

{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];

    style = ''
      /* ============================================
       * Wlogout - Glassmorphism Theme
       * Premium frosted glass logout menu
       * ============================================ */

      /* Reset */
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        background-image: none;
        transition: all 0.3s ease;
      }

      /* Main window - dark overlay with blur */
      window {
        background-color: rgba(10, 10, 15, 0.85);
      }

      /* Button container */
      button {
        background: rgba(18, 18, 26, 0.7);
        border: 2px solid rgba(255, 255, 255, 0.08);
        border-radius: 16px;
        margin: 12px;
        padding: 0;
        color: #e4e4e7;
        font-size: 16px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
        transition: all 0.3s ease;
      }

      button:hover {
        background: rgba(0, 212, 255, 0.15);
        border-color: rgba(0, 212, 255, 0.5);
        box-shadow: 0 0 30px rgba(0, 212, 255, 0.25),
                    0 4px 20px rgba(0, 0, 0, 0.3);
        color: #00d4ff;
      }

      button:focus {
        background: rgba(0, 212, 255, 0.2);
        border-color: rgba(0, 212, 255, 0.6);
        box-shadow: 0 0 40px rgba(0, 212, 255, 0.3),
                    0 4px 20px rgba(0, 0, 0, 0.3);
        outline: none;
      }

      button:active {
        background: rgba(0, 212, 255, 0.25);
        transform: scale(0.95);
      }

      /* ============================================
       * INDIVIDUAL BUTTON STYLES
       * ============================================ */

      /* Lock - Cyan */
      #lock {
        background: linear-gradient(135deg, rgba(0, 212, 255, 0.1), rgba(18, 18, 26, 0.7));
        border-color: rgba(0, 212, 255, 0.2);
      }

      #lock:hover {
        background: linear-gradient(135deg, rgba(0, 212, 255, 0.25), rgba(18, 18, 26, 0.7));
        border-color: rgba(0, 212, 255, 0.6);
        box-shadow: 0 0 35px rgba(0, 212, 255, 0.3);
      }

      /* Logout - Violet */
      #logout {
        background: linear-gradient(135deg, rgba(124, 58, 237, 0.1), rgba(18, 18, 26, 0.7));
        border-color: rgba(124, 58, 237, 0.2);
      }

      #logout:hover {
        background: linear-gradient(135deg, rgba(124, 58, 237, 0.25), rgba(18, 18, 26, 0.7));
        border-color: rgba(124, 58, 237, 0.6);
        box-shadow: 0 0 35px rgba(124, 58, 237, 0.3);
        color: #a78bfa;
      }

      /* Suspend - Blue */
      #suspend {
        background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(18, 18, 26, 0.7));
        border-color: rgba(59, 130, 246, 0.2);
      }

      #suspend:hover {
        background: linear-gradient(135deg, rgba(59, 130, 246, 0.25), rgba(18, 18, 26, 0.7));
        border-color: rgba(59, 130, 246, 0.6);
        box-shadow: 0 0 35px rgba(59, 130, 246, 0.3);
        color: #60a5fa;
      }

      /* Hibernate - Green */
      #hibernate {
        background: linear-gradient(135deg, rgba(34, 197, 94, 0.1), rgba(18, 18, 26, 0.7));
        border-color: rgba(34, 197, 94, 0.2);
      }

      #hibernate:hover {
        background: linear-gradient(135deg, rgba(34, 197, 94, 0.25), rgba(18, 18, 26, 0.7));
        border-color: rgba(34, 197, 94, 0.6);
        box-shadow: 0 0 35px rgba(34, 197, 94, 0.3);
        color: #4ade80;
      }

      /* Reboot - Yellow/Orange */
      #reboot {
        background: linear-gradient(135deg, rgba(234, 179, 8, 0.1), rgba(18, 18, 26, 0.7));
        border-color: rgba(234, 179, 8, 0.2);
      }

      #reboot:hover {
        background: linear-gradient(135deg, rgba(234, 179, 8, 0.25), rgba(18, 18, 26, 0.7));
        border-color: rgba(234, 179, 8, 0.6);
        box-shadow: 0 0 35px rgba(234, 179, 8, 0.3);
        color: #facc15;
      }

      /* Shutdown - Magenta/Red */
      #shutdown {
        background: linear-gradient(135deg, rgba(255, 0, 170, 0.1), rgba(18, 18, 26, 0.7));
        border-color: rgba(255, 0, 170, 0.2);
      }

      #shutdown:hover {
        background: linear-gradient(135deg, rgba(255, 0, 170, 0.25), rgba(18, 18, 26, 0.7));
        border-color: rgba(255, 0, 170, 0.6);
        box-shadow: 0 0 35px rgba(255, 0, 170, 0.3);
        color: #ff00aa;
      }
    '';
  };

  # ============================================
  # WLOGOUT ICONS
  # ============================================
  # Custom SVG icons with glassmorphism style
  home.file = {
    ".config/wlogout/icons/lock.svg".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
        <path d="m7 11v-4a5 5 0 0 1 10 0v4"></path>
        <circle cx="12" cy="16" r="1"></circle>
      </svg>
    '';

    ".config/wlogout/icons/logout.svg".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
        <polyline points="16 17 21 12 16 7"></polyline>
        <line x1="21" y1="12" x2="9" y2="12"></line>
      </svg>
    '';

    ".config/wlogout/icons/suspend.svg".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
      </svg>
    '';

    ".config/wlogout/icons/hibernate.svg".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="10"></circle>
        <path d="M12 6v6l4 2"></path>
      </svg>
    '';

    ".config/wlogout/icons/reboot.svg".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="23 4 23 10 17 10"></polyline>
        <polyline points="1 20 1 14 7 14"></polyline>
        <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path>
      </svg>
    '';

    ".config/wlogout/icons/shutdown.svg".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M18.36 6.64a9 9 0 1 1-12.73 0"></path>
        <line x1="12" y1="2" x2="12" y2="12"></line>
      </svg>
    '';
  };
}
