# ============================================
# Hyprland Modular - Library Functions
# ============================================
# Composable helpers for:
# - Color manipulation (hex, rgba, gradients)
# - Rule builders (declarative window rules)
# - Animation generators
# - Binding factories
# ============================================
{ lib, pkgs }:

rec {
  # ==========================================
  # COLOR UTILITIES
  # ==========================================

  # Convert hex color to rgba format for Hyprland
  # hexToRgba "#00d4ff" 1.0 => "rgba(00d4ffff)"
  # hexToRgba "#00d4ff" 0.5 => "rgba(00d4ff80)"
  hexToRgba =
    hex: alpha:
    let
      cleanHex = lib.removePrefix "#" hex;
      alphaHex = toHexByte (builtins.floor (alpha * 255));
    in
    "rgba(${cleanHex}${alphaHex})";

  # Convert 0-255 to hex byte string
  toHexByte =
    n:
    let
      hexChars = [
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
      ];
      high = builtins.elemAt hexChars (n / 16);
      low = builtins.elemAt hexChars (lib.mod n 16);
    in
    "${high}${low}";

  # Create gradient border string
  # gradient [ "#00d4ff" "#7c3aed" ] 45 => "rgba(00d4ffff) rgba(7c3aedff) 45deg"
  gradient =
    colors: angle:
    let
      rgbaColors = map (c: hexToRgba c 1.0) colors;
    in
    "${lib.concatStringsSep " " rgbaColors} ${toString angle}deg";

  # Predefined color palettes
  palettes = {
    glassmorphism = {
      primary = "#00d4ff"; # Electric cyan
      secondary = "#7c3aed"; # Violet
      accent = "#ff006e"; # Magenta
      background = "#0d0d0f";
      surface = "#22222e";
      text = "#ffffff";
      textMuted = "#a0a0a0";
    };
    nord = {
      primary = "#88c0d0";
      secondary = "#81a1c1";
      accent = "#b48ead";
      background = "#2e3440";
      surface = "#3b4252";
      text = "#eceff4";
      textMuted = "#d8dee9";
    };
    dracula = {
      primary = "#bd93f9";
      secondary = "#ff79c6";
      accent = "#50fa7b";
      background = "#282a36";
      surface = "#44475a";
      text = "#f8f8f2";
      textMuted = "#6272a4";
    };
    catppuccin = {
      primary = "#cba6f7"; # Mauve
      secondary = "#f5c2e7"; # Pink
      accent = "#a6e3a1"; # Green
      background = "#1e1e2e"; # Base
      surface = "#313244"; # Surface0
      text = "#cdd6f4"; # Text
      textMuted = "#a6adc8"; # Subtext0
    };
    gruvbox = {
      primary = "#fe8019";
      secondary = "#fabd2f";
      accent = "#b8bb26";
      background = "#282828";
      surface = "#3c3836";
      text = "#ebdbb2";
      textMuted = "#a89984";
    };
    tokyonight = {
      primary = "#7aa2f7";
      secondary = "#bb9af7";
      accent = "#9ece6a";
      background = "#1a1b26";
      surface = "#24283b";
      text = "#c0caf5";
      textMuted = "#565f89";
    };
  };

  # ==========================================
  # WINDOW RULE BUILDERS
  # ==========================================

  # Build a complete window rule set for an application

  # New syntax: "rule value, match:selector regex"

  appRule =

    {

      class ? null,

      title ? null,

      opacity ? null,

      float ? false,

      size ? null,

      center ? false,

      pin ? false,

      workspace ? null,

      animation ? null,

      immediate ? false,

      noanim ? false,

      stayfocused ? false,

      dimaround ? false,

      extra ? [ ],

    }:

    let

      # Selectors now use match: prefix

      selectors =

        if class != null then

          "match:class ^(${class})$"

        else if title != null then

          "match:title ^(${title})$"

        else

          throw "appRule requires either class or title";

      rules = lib.flatten [

        (lib.optional (

          opacity != null

        ) "opacity ${toString opacity} ${toString (opacity - 0.03)}, ${selectors}")

        (lib.optional float "float 1, ${selectors}")

        (lib.optional (size != null) "size ${size}, ${selectors}")

        (lib.optional center "center 1, ${selectors}")

        (lib.optional pin "pin 1, ${selectors}")

        (lib.optional (workspace != null) "workspace ${toString workspace} silent, ${selectors}")

        (lib.optional (animation != null) "animation ${animation}, ${selectors}")

        (lib.optional immediate "immediate 1, ${selectors}")

        (lib.optional noanim "noanim 1, ${selectors}")

        (lib.optional stayfocused "stayfocused 1, ${selectors}")

        (lib.optional dimaround "dimaround 1, ${selectors}")

        (map (e: "${e}, ${selectors}") extra)

      ];

    in

    rules;

  # Quick rule for floating windows with standard setup
  floatingApp =
    class: width: height:
    appRule {
      inherit class;
      float = true;
      size = "${toString width} ${toString height}";
      center = true;
    };

  # Dialog rule (floating, pinned, focused, dimmed background)
  dialogRule =
    selector:
    appRule {
      title = selector;
      float = true;
      pin = true;
      stayfocused = true;
      center = true;
      dimaround = true;
    };

  # ==========================================
  # KEYBINDING FACTORIES
  # ==========================================

  # Create a bind with common prefix
  # mkBind "SUPER" "Return" "exec" "kitty" => "$mainMod, Return, exec, kitty"
  mkBind =
    mod: key: dispatcher: args:
    "${mod}, ${key}, ${dispatcher}, ${args}";

  # Create a set of workspace bindings (switch + move)
  mkWorkspaceBinds =
    mainMod: count:
    lib.flatten (
      map (n: [
        "${mainMod}, ${toString n}, workspace, ${toString n}"
        "${mainMod} SHIFT, ${toString n}, movetoworkspace, ${toString n}"
      ]) (lib.range 1 count)
    );

  # Create directional bindings for a dispatcher
  # mkDirectionalBinds "$mainMod" "movefocus" => arrow + hjkl bindings
  mkDirectionalBinds = mod: dispatcher: [
    "${mod}, left, ${dispatcher}, l"
    "${mod}, right, ${dispatcher}, r"
    "${mod}, up, ${dispatcher}, u"
    "${mod}, down, ${dispatcher}, d"
    "${mod}, h, ${dispatcher}, l"
    "${mod}, l, ${dispatcher}, r"
    "${mod}, k, ${dispatcher}, u"
    "${mod}, j, ${dispatcher}, d"
  ];

  # ==========================================
  # ANIMATION BUILDERS
  # ==========================================

  # Predefined bezier curves
  beziers = {
    smoothOut = "smoothOut, 0.4, 0, 0.2, 1";
    snappy = "snappy, 0.2, 0.8, 0.2, 1";
    bounce = "bounce, 0.68, -0.55, 0.265, 1.55";
    gentle = "gentle, 0.4, 0.14, 0.3, 1";
    linear = "linear, 0, 0, 1, 1";
    fast = "fast, 0.2, 1, 0.3, 1";
    slide = "slide, 0.3, 0, 0.2, 1";
    # Gaming-optimized (minimal motion)
    instant = "instant, 0, 0, 0, 1";
    # Presentation (smooth, slow)
    elegant = "elegant, 0.25, 0.1, 0.25, 1";
  };

  # Build animation config
  mkAnimation =
    name: enabled: speed: curve: style:
    "${name}, ${if enabled then "1" else "0"}, ${toString speed}, ${curve}${
      lib.optionalString (style != null) ", ${style}"
    }";

  # Animation presets
  animationPresets = {
    # Default smooth animations for 144Hz
    smooth = {
      bezier = with beziers; [
        smoothOut
        snappy
        bounce
        gentle
        linear
        fast
        slide
      ];
      animation = [
        "windowsIn, 1, 4, snappy, slide"
        "windowsOut, 1, 3, smoothOut, slide"
        "windowsMove, 1, 4, snappy"
        "fadeIn, 1, 3, gentle"
        "fadeOut, 1, 3, gentle"
        "fadeSwitch, 1, 4, smoothOut"
        "fadeShadow, 1, 4, smoothOut"
        "fadeDim, 1, 4, smoothOut"
        "border, 1, 8, gentle"
        "borderangle, 1, 50, linear, loop"
        "workspaces, 1, 5, slide, slide"
        "workspacesIn, 1, 4, snappy, slide"
        "workspacesOut, 1, 3, smoothOut, slide"
        "specialWorkspace, 1, 4, snappy, slidevert"
        "layers, 1, 3, snappy, fade"
        "layersIn, 1, 3, snappy, fade"
        "layersOut, 1, 3, gentle, fade"
      ];
    };
    # Minimal animations for gaming
    minimal = {
      bezier = [
        beziers.instant
        beziers.fast
      ];
      animation = [
        "windowsIn, 1, 1, instant, slide"
        "windowsOut, 1, 1, instant, slide"
        "windowsMove, 1, 1, instant"
        "fadeIn, 1, 1, instant"
        "fadeOut, 1, 1, instant"
        "workspaces, 1, 1, instant, slide"
        "layers, 0"
      ];
    };
    # No animations
    none = {
      bezier = [ ];
      animation = [ ];
    };
    # Elegant for presentations
    elegant = {
      bezier = [
        beziers.elegant
        beziers.gentle
      ];
      animation = [
        "windowsIn, 1, 6, elegant, slide"
        "windowsOut, 1, 5, elegant, slide"
        "windowsMove, 1, 5, elegant"
        "fadeIn, 1, 5, gentle"
        "fadeOut, 1, 5, gentle"
        "workspaces, 1, 6, elegant, slide"
        "layers, 1, 5, elegant, fade"
      ];
    };
  };

  # ==========================================
  # DECORATION BUILDERS
  # ==========================================

  # Build blur configuration (modern Hyprland 0.40+)
  # Removed deprecated fields: noise, contrast, brightness, vibrancy, vibrancy_darkness
  # Modern blur only uses: enabled, size, passes, new_optimizations, ignore_opacity
  # All values use mkDefault so profiles can override them
  mkBlur =
    {
      enabled ? true,
      size ? 10,
      passes ? 3,
      new_optimizations ? true,
      ignore_opacity ? false,
    }:
    {
      enabled = lib.mkDefault enabled;
      size = lib.mkDefault size;
      passes = lib.mkDefault passes;
      new_optimizations = lib.mkDefault new_optimizations;
      ignore_opacity = lib.mkDefault ignore_opacity;
    };

  # Build shadow configuration
  # All values use mkDefault so profiles can override them
  mkShadow =
    {
      enabled ? true,
      range ? 20,
      renderPower ? 3,
      offset ? "0 4",
      color ? "rgba(00000066)",
      colorInactive ? "rgba(00000044)",
    }:
    {
      enabled = lib.mkDefault enabled;
      range = lib.mkDefault range;
      offset = lib.mkDefault offset;
      color = lib.mkDefault color;
      render_power = lib.mkDefault renderPower;
      color_inactive = lib.mkDefault colorInactive;
    };

  # ==========================================
  # LAYER RULE HELPERS
  # ==========================================

  # Common layer blur targets
  blurLayers = layers: map (l: "blur, ${l}") layers;

  defaultBlurLayers = blurLayers [
    "waybar"
    "notifications"
    "wofi"
    "rofi"
    "swappy"
    "logout_dialog"
    "hyprlock"
    "gtk-layer-shell"
  ];

  # ==========================================
  # MONITOR CONFIGURATION HELPERS
  # ==========================================

  # Build monitor string
  mkMonitor =
    {
      name ? "",
      resolution ? "preferred",
      position ? "auto",
      scale ? 1.0,
      transform ? 0,
      vrr ? null,
    }:
    "${name},${resolution},${position},${toString scale}"
    + lib.optionalString (transform != 0) ",transform,${toString transform}";

  # ==========================================
  # GENERAL UTILITIES
  # ==========================================

  # Merge multiple attribute sets recursively
  deepMerge = lib.foldl lib.recursiveUpdate { };

  # Conditional attribute
  optionalAttr = cond: attr: if cond then attr else { };

  # Build exec-once list
  mkAutostart = entries: lib.flatten entries;

  # ==========================================
  # TERMINAL COMMAND BUILDERS
  # ==========================================

  # Build terminal command with optional multiplexer
  mkTerminalCmd =
    {
      terminal,
      multiplexer ? null,
      session ? "main",
    }:
    if multiplexer == "zellij" then
      "${terminal} -e zellij attach --create ${session}"
    else if multiplexer == "tmux" then
      "${terminal} -e tmux new-session -A -s ${session}"
    else
      terminal;

  # ==========================================
  # SCREENSHOT COMMAND BUILDERS
  # ==========================================

  screenshotCommands = {
    regionToSwappy = ''grim -g "$(slurp)" - | swappy -f -'';
    fullToSwappy = ''grim - | swappy -f -'';
    regionToFile = dir: ''grim -g "$(slurp)" ${dir}/screenshot-$(date +%Y%m%d-%H%M%S).png'';
    fullToFile = dir: ''grim ${dir}/screenshot-$(date +%Y%m%d-%H%M%S).png'';
    regionToClipboard = ''grim -g "$(slurp)" - | wl-copy'';
    fullToClipboard = ''grim - | wl-copy'';
  };
}
