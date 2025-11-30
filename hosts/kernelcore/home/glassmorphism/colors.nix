# ============================================
# Glassmorphism Design System - Color Palette
# ============================================
# Premium dark glassmorphism theme with electric accents
# For NixOS/Hyprland at 144Hz
# ============================================

{ lib, ... }:

let
  # ============================================
  # BASE COLORS - Dark frosted backgrounds
  # ============================================
  base = {
    # Primary dark surfaces (darkest to lighter)
    bg0 = "#0a0a0f"; # Deepest background
    bg1 = "#12121a"; # Primary surface
    bg2 = "#1a1a24"; # Elevated surface
    bg3 = "#22222e"; # Highest elevation

    # Foreground colors
    fg0 = "#ffffff"; # Primary text
    fg1 = "#e4e4e7"; # Secondary text
    fg2 = "#a1a1aa"; # Muted text
    fg3 = "#71717a"; # Disabled/placeholder

    # Surface variants
    surface = "#16161e"; # Card backgrounds
    overlay = "#1e1e28"; # Modal/popup backgrounds
  };

  # ============================================
  # ACCENT COLORS - Electric neon palette
  # ============================================
  accent = {
    # Primary accents
    cyan = "#00d4ff"; # Electric cyan - primary
    magenta = "#ff00aa"; # Neon magenta - critical/danger
    violet = "#7c3aed"; # Soft violet - secondary

    # Extended palette
    blue = "#3b82f6"; # Info
    green = "#22c55e"; # Success
    yellow = "#eab308"; # Warning
    orange = "#f97316"; # Attention
    red = "#ef4444"; # Error

    # Accent variants (lighter/darker)
    cyanLight = "#67e8f9";
    cyanDark = "#0891b2";
    magentaLight = "#f472b6";
    magentaDark = "#be185d";
    violetLight = "#a78bfa";
    violetDark = "#5b21b6";
  };

  # ============================================
  # TRANSPARENCY VALUES - Glass effects
  # ============================================
  alpha = {
    # Surface transparency (for rgba)
    solid = "ff"; # 100% - fully opaque
    high = "e6"; # 90%
    medium = "cc"; # 80%
    mediumLow = "99"; # 60%
    low = "66"; # 40%
    veryLow = "33"; # 20%
    subtle = "1a"; # 10%
    minimal = "0d"; # 5%

    # Decimal values for CSS rgba()
    dec = {
      solid = "1.0";
      high = "0.9";
      medium = "0.8";
      mediumLow = "0.6";
      low = "0.4";
      veryLow = "0.2";
      subtle = "0.1";
      minimal = "0.05";
    };
  };

  # ============================================
  # BORDER COLORS - Luminescent edges
  # ============================================
  border = {
    # Glass borders (white with transparency)
    light = "rgba(255, 255, 255, 0.1)";
    lighter = "rgba(255, 255, 255, 0.05)";
    accent = "rgba(0, 212, 255, 0.3)"; # Cyan glow
    accentStrong = "rgba(0, 212, 255, 0.5)";

    # Gradient border values
    gradientStart = "rgba(255, 255, 255, 0.1)";
    gradientEnd = "rgba(255, 255, 255, 0.05)";
  };

  # ============================================
  # SHADOW COLORS - Colored glow effects
  # ============================================
  shadow = {
    # Drop shadows
    dark = "rgba(0, 0, 0, 0.4)";
    medium = "rgba(0, 0, 0, 0.25)";
    light = "rgba(0, 0, 0, 0.1)";

    # Colored glow shadows
    cyan = "rgba(0, 212, 255, 0.3)";
    cyanStrong = "rgba(0, 212, 255, 0.5)";
    magenta = "rgba(255, 0, 170, 0.3)";
    magentaStrong = "rgba(255, 0, 170, 0.5)";
    violet = "rgba(124, 58, 237, 0.3)";
    violetStrong = "rgba(124, 58, 237, 0.5)";
  };

  # ============================================
  # BLUR SETTINGS - Frosted glass effect
  # ============================================
  blur = {
    size = 10; # pixels
    passes = 3; # render passes for quality
    xray = true; # see through floating windows
    noise = 0.02; # subtle noise texture
    contrast = 0.9; # slight contrast boost
    brightness = 0.8; # slight dimming for depth
  };

  # ============================================
  # CORNER RADIUS - Consistent rounding
  # ============================================
  radius = {
    small = 8; # buttons, tags
    medium = 12; # cards, inputs
    large = 16; # modals, panels
    pill = 20; # waybar modules
    full = 9999; # circular elements
  };

  # ============================================
  # SPACING - Consistent rhythm
  # ============================================
  spacing = {
    xs = 4;
    sm = 8;
    md = 16;
    lg = 24;
    xl = 32;
    xxl = 48;
  };

  # ============================================
  # ANIMATION - Smooth 144fps curves
  # ============================================
  animation = {
    # Duration in ms
    fast = 150;
    normal = 250;
    slow = 400;

    # Bezier curves for 144fps smoothness
    bezier = {
      smooth = "0.4, 0, 0.2, 1"; # ease-out
      bounce = "0.68, -0.55, 0.265, 1.55"; # overshoot
      snappy = "0.2, 0.8, 0.2, 1"; # quick start
      gentle = "0.4, 0.14, 0.3, 1"; # soft movement
    };
  };

  # ============================================
  # URGENCY COLORS - Notification priorities
  # ============================================
  urgency = {
    low = accent.cyan; # Informational
    normal = accent.violet; # Standard
    critical = accent.magenta; # Important/Alert
  };

  # ============================================
  # SEMANTIC COLORS - UI states
  # ============================================
  semantic = {
    success = accent.green;
    warning = accent.yellow;
    error = accent.red;
    info = accent.blue;
    active = accent.cyan;
    inactive = base.fg3;
    hover = accent.cyanLight;
    focus = accent.cyan;
  };

  # ============================================
  # HYPRLAND-SPECIFIC - Hex with alpha suffix
  # ============================================
  hyprland = {
    # Active border gradient
    activeBorder1 = "${accent.cyan}ff";
    activeBorder2 = "${accent.violet}ff";
    inactiveBorder = "${base.bg3}aa";

    # Shadow color
    shadowColor = "rgba(0, 0, 0, 0.5)";
    shadowColorActive = shadow.cyan;

    # Dim inactive
    dimInactive = 0.85;
  };

  # ============================================
  # WAYBAR-SPECIFIC - CSS-ready values
  # ============================================
  waybar = {
    background = "rgba(10, 10, 15, 0.75)";
    moduleBackground = "rgba(18, 18, 26, 0.8)";
    text = base.fg0;
    textSecondary = base.fg2;
    border = border.light;
    hover = "rgba(0, 212, 255, 0.15)";
    active = accent.cyan;
  };

  # ============================================
  # GTK-SPECIFIC - Theme integration
  # ============================================
  gtk = {
    background = base.bg1;
    foreground = base.fg0;
    accent = accent.cyan;
    selection = "${accent.cyan}33";
    border = base.bg3;
  };

in
{
  options.glassmorphism.colors = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Glassmorphism color palette";
  };

  config.glassmorphism.colors = {
    inherit
      base
      accent
      alpha
      border
      shadow
      blur
      radius
      spacing
      animation
      urgency
      semantic
      hyprland
      waybar
      gtk
      ;

    # Helper functions
    withAlpha = color: alphaHex: "${color}${alphaHex}";
    rgba =
      r: g: b: a:
      "rgba(${toString r}, ${toString g}, ${toString b}, ${a})";

    # Quick access
    primary = accent.cyan;
    secondary = accent.violet;
    danger = accent.magenta;
  };
}
