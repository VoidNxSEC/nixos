# Glassmorphism Design System
## Premium Dark Theme for Hyprland/NixOS

> **Version**: 2.0.0
> **Status**: Production
> **Target**: 144Hz displays with GPU acceleration
> **Philosophy**: Function meets form - every design decision serves a purpose

---

## Table of Contents

1. [Overview](#overview)
2. [Color System](#color-system)
3. [Typography](#typography)
4. [Spacing & Layout](#spacing--layout)
5. [Effects & Animations](#effects--animations)
6. [Component Patterns](#component-patterns)
7. [Usage Guidelines](#usage-guidelines)
8. [Implementation](#implementation)

---

## Overview

The Glassmorphism Design System is a comprehensive design language for modern Linux desktops. It combines **frosted glass aesthetics** with **electric neon accents** to create a visually striking yet highly functional interface optimized for 144Hz displays.

### Core Principles

1. **Clarity over Decoration**: Every visual element must enhance usability
2. **Performance First**: All effects optimized for 144fps @ 1920x1080
3. **Consistency**: Predictable patterns across all components
4. **Accessibility**: Maintained contrast ratios (WCAG AA minimum)
5. **Purposeful Motion**: Animations guide attention, don't distract

### Design Philosophy

**Glassmorphism** = Frosted glass surfaces + Electric accents + Deep backgrounds

- **Depth through transparency**: Layered surfaces with controlled blur
- **Visual hierarchy**: 4 elevation levels (bg0-bg3) for clear information architecture
- **Electric energy**: Cyan/Magenta/Violet accents for high-tech aesthetic
- **Smooth motion**: Bezier curves optimized for 144fps displays

---

## Color System

### Base Colors (Dark Frosted Backgrounds)

Our foundation is a **4-level background hierarchy** providing visual depth:

| Level | Hex | Purpose | Examples |
|-------|-----|---------|----------|
| **bg0** | `#0a0a0f` | Deepest background | Desktop wallpaper base, fullscreen app backgrounds |
| **bg1** | `#12121a` | Primary surface | Window backgrounds, main content areas |
| **bg2** | `#1a1a24` | Elevated surface | Sidebars, cards, elevated panels |
| **bg3** | `#22222e` | Highest elevation | Floating panels, dropdowns, tooltips |

**Additional Surfaces:**
- **surface** (`#16161e`): Card backgrounds
- **overlay** (`#1e1e28`): Modal/popup backgrounds

### Foreground Colors (Text Hierarchy)

4 foreground levels for **typographic hierarchy**:

| Level | Hex | Opacity | Purpose |
|-------|-----|---------|---------|
| **fg0** | `#ffffff` | 100% | Primary text, headlines, critical info |
| **fg1** | `#e4e4e7` | 90% | Body text, secondary headlines |
| **fg2** | `#a1a1aa` | 65% | Muted text, labels, metadata |
| **fg3** | `#71717a` | 45% | Disabled text, placeholders |

**Contrast Ratios** (against bg1):
- fg0: 19.2:1 (AAA Large)
- fg1: 16.8:1 (AAA)
- fg2: 9.2:1 (AA)
- fg3: 5.1:1 (AA Large)

### Accent Colors (Electric Neon Palette)

Our **primary identity colors**:

| Color | Hex | Purpose | Usage |
|-------|-----|---------|-------|
| **Cyan** | `#00d4ff` | Primary accent | Active states, primary actions, focus indicators |
| **Violet** | `#7c3aed` | Secondary accent | Hover states, secondary actions, normal priority |
| **Magenta** | `#ff00aa` | Critical/Danger | Errors, critical alerts, destructive actions |

**Extended Palette:**
- **Blue** (`#3b82f6`): Informational messages
- **Green** (`#22c55e`): Success states, positive feedback
- **Yellow** (`#eab308`): Warnings, attention needed
- **Orange** (`#f97316`): Attention, moderate priority
- **Red** (`#ef4444`): Errors, failed states

**Accent Variants:**
- **Light**: Hover states, highlights (+40% lightness)
- **Dark**: Pressed states, shadows (-40% lightness)

### Semantic Color Mapping

**State-based colors** for immediate recognition:

```nix
semantic = {
  success = green;    # #22c55e - Actions completed successfully
  warning = yellow;   # #eab308 - Caution required
  error = red;        # #ef4444 - Failed operations
  info = blue;        # #3b82f6 - Informational
  active = cyan;      # #00d4ff - Currently active/selected
  inactive = fg3;     # #71717a - Inactive/disabled
  hover = cyanLight;  # #67e8f9 - Hover states
  focus = cyan;       # #00d4ff - Keyboard focus
};
```

### Urgency Levels (Notifications)

3-tier notification priority system:

| Urgency | Color | Border | Timeout | Use Case |
|---------|-------|--------|---------|----------|
| **Low** | Cyan | 2px | 3s | Background info, non-critical updates |
| **Normal** | Violet | 2px | 5s | Standard notifications, user actions |
| **Critical** | Magenta | 3px | ∞ (persistent) | Errors, system alerts, requires action |

### Transparency System

**Alpha values** for layering:

| Level | Hex | Decimal | CSS | Purpose |
|-------|-----|---------|-----|---------|
| **solid** | `ff` | 1.0 | 100% | Opaque elements |
| **high** | `e6` | 0.9 | 90% | Primary surfaces |
| **medium** | `cc` | 0.8 | 80% | Secondary surfaces |
| **mediumLow** | `99` | 0.6 | 60% | Tertiary surfaces |
| **low** | `66` | 0.4 | 40% | Overlays |
| **veryLow** | `33` | 0.2 | 20% | Hover states |
| **subtle** | `1a` | 0.1 | 10% | Borders |
| **minimal** | `0d` | 0.05 | 5% | Shadows |

### Border Colors

**Luminescent glass edges**:

```css
border-light: rgba(255, 255, 255, 0.1);      /* Standard glass border */
border-lighter: rgba(255, 255, 255, 0.05);   /* Subtle separation */
border-accent: rgba(0, 212, 255, 0.3);       /* Cyan glow */
border-accent-strong: rgba(0, 212, 255, 0.5); /* Active glow */
```

**Gradient borders** for depth:
```css
border-image: linear-gradient(
  135deg,
  rgba(255, 255, 255, 0.1) 0%,
  rgba(255, 255, 255, 0.05) 100%
);
```

### Shadow System

**3 elevation levels** + **colored glows**:

#### Drop Shadows
| Level | Value | Use Case |
|-------|-------|----------|
| **Dark** | `rgba(0, 0, 0, 0.4)` | Floating windows, modals |
| **Medium** | `rgba(0, 0, 0, 0.25)` | Cards, elevated panels |
| **Light** | `rgba(0, 0, 0, 0.1)` | Subtle depth, buttons |

#### Colored Glows
| Color | Normal | Strong | Use Case |
|-------|--------|--------|----------|
| **Cyan** | `0.3` | `0.5` | Active elements, focus indicators |
| **Magenta** | `0.3` | `0.5` | Critical alerts, errors |
| **Violet** | `0.3` | `0.5` | Hover states, secondary actions |

**Example Shadow Stack:**
```css
box-shadow:
  0 4px 6px rgba(0, 0, 0, 0.1),           /* Base depth */
  0 0 20px rgba(0, 212, 255, 0.3),        /* Cyan glow */
  inset 0 1px 0 rgba(255, 255, 255, 0.1); /* Top highlight */
```

---

## Typography

### Font Stack

**System fonts** for performance and consistency:

```nix
fonts = {
  # Monospace (terminals, code)
  mono = "JetBrainsMono Nerd Font";
  monoFallback = "Fira Code Nerd Font";

  # Sans-serif (UI, body text)
  sans = "Inter";
  sansFallback = "Liberation Sans";

  # Emoji/symbols
  emoji = "Noto Color Emoji";
  symbols = "Symbols Nerd Font";
};
```

### Font Sizes

**Modular scale** (1.250 ratio):

| Level | Size | Line Height | Weight | Use Case |
|-------|------|-------------|--------|----------|
| **h1** | 32px | 40px | 700 | Page titles, major headings |
| **h2** | 24px | 32px | 600 | Section headings |
| **h3** | 20px | 28px | 600 | Subsection headings |
| **h4** | 16px | 24px | 500 | Card titles, labels |
| **body** | 13px | 20px | 400 | Body text, descriptions |
| **small** | 11px | 16px | 400 | Metadata, captions |
| **tiny** | 9px | 12px | 400 | Timestamps, fine print |

### Font Weights

- **300**: Light (decorative only)
- **400**: Regular (body text)
- **500**: Medium (emphasis, labels)
- **600**: Semibold (headings, titles)
- **700**: Bold (critical info, CTAs)

### Component-Specific Typography

#### Waybar
```
Font: JetBrainsMono Nerd Font 11
Weight: 500
Spacing: 0.5px letter-spacing
```

#### Mako Notifications
```
Title: JetBrainsMono 12 (weight 600)
Body: JetBrainsMono 11 (weight 400)
```

#### Wofi Launcher
```
Input: Inter 14 (weight 500)
Results: Inter 12 (weight 400)
```

#### Hyprlock
```
Time: JetBrainsMono 95px (weight 700)
Date: JetBrainsMono 24px (weight 500)
Input: JetBrainsMono 16px (weight 400)
```

---

## Spacing & Layout

### Spacing Scale

**8px base unit** for consistent rhythm:

| Token | Value | CSS Var | Use Case |
|-------|-------|---------|----------|
| **xs** | 4px | `--space-xs` | Tight spacing, icon padding |
| **sm** | 8px | `--space-sm` | Standard padding, small gaps |
| **md** | 16px | `--space-md` | Content padding, section spacing |
| **lg** | 24px | `--space-lg` | Large sections, page margins |
| **xl** | 32px | `--space-xl` | Major sections, hero spacing |
| **xxl** | 48px | `--space-xxl` | Page-level separation |

### Border Radius

**Consistent rounding** for visual harmony:

| Token | Value | Use Case |
|-------|-------|----------|
| **small** | 8px | Buttons, tags, small elements |
| **medium** | 12px | Cards, inputs, standard components |
| **large** | 16px | Modals, panels, large surfaces |
| **pill** | 20px | Waybar modules, pills |
| **full** | 9999px | Circular elements, avatars |

**Visual Examples:**
```
small (8px):   [Button]
medium (12px): [Input Field____________]
large (16px):  [Modal Dialog             ]
pill (20px):   (Waybar Module)
full:          (●) Avatar
```

### Layout Grid

**8px base grid** system:

- **Gutters**: 16px (2 units)
- **Margins**: 24px (3 units)
- **Column gap**: 16px
- **Row gap**: 16px

### Window Rules

**Opacity hierarchy** by application type:

| Type | Active | Inactive | Purpose |
|------|--------|----------|---------|
| **Terminal** | 0.92 | 0.88 | Kitty, Alacritty |
| **Editor** | 0.95 | 0.90 | VSCode, VSCodium |
| **Browser** | 0.98 | 0.95 | Firefox, Brave (readability) |
| **Utility** | 0.92 | 0.88 | File managers, settings |

---

## Effects & Animations

### Blur Settings

**Frosted glass effect**:

```nix
blur = {
  size = 10;           # Blur radius (pixels)
  passes = 3;          # Render passes (quality)
  xray = true;         # See through floating windows
  noise = 0.02;        # Subtle texture (2%)
  contrast = 0.9;      # Slight contrast boost
  brightness = 0.8;    # Dimming for depth
};
```

**Performance**: Optimized for NVIDIA GPUs at 144fps

### Animation Curves

**4 bezier curves** for different motion types:

| Curve | Values | Purpose | Use Case |
|-------|--------|---------|----------|
| **smooth** | `0.4, 0, 0.2, 1` | Ease-out | Menus, panels, general UI |
| **bounce** | `0.68, -0.55, 0.265, 1.55` | Overshoot | Playful interactions, notifications |
| **snappy** | `0.2, 0.8, 0.2, 1` | Quick start | Fast actions, dismissals |
| **gentle** | `0.4, 0.14, 0.3, 1` | Soft movement | Background transitions, ambient |

**Visual representation:**
```
smooth:  ___/‾‾
bounce:  ___/‾\_/‾
snappy:  __/‾‾‾
gentle:  ___/‾‾‾
```

### Duration Scale

**3-tier timing** for 144fps:

| Speed | Duration | Frames @ 144fps | Use Case |
|-------|----------|-----------------|----------|
| **fast** | 150ms | ~22 frames | Hover, focus, instant feedback |
| **normal** | 250ms | ~36 frames | Standard transitions, menus |
| **slow** | 400ms | ~58 frames | Page transitions, complex animations |

### Interaction States

**5-state model** for all interactive elements:

```css
/* 1. Default */
element {
  opacity: 0.9;
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 250ms cubic-bezier(0.4, 0, 0.2, 1);
}

/* 2. Hover */
element:hover {
  opacity: 1.0;
  border-color: rgba(0, 212, 255, 0.3);
  box-shadow: 0 0 20px rgba(0, 212, 255, 0.2);
}

/* 3. Active/Pressed */
element:active {
  transform: scale(0.98);
  box-shadow: 0 0 10px rgba(0, 212, 255, 0.4);
}

/* 4. Focus (keyboard) */
element:focus-visible {
  outline: 2px solid #00d4ff;
  outline-offset: 2px;
}

/* 5. Disabled */
element:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  filter: grayscale(0.5);
}
```

---

## Component Patterns

### Buttons

**3 button types**:

#### Primary Button
```css
background: linear-gradient(135deg, #00d4ff, #7c3aed);
color: #0a0a0f;
padding: 8px 16px;
border-radius: 8px;
font-weight: 600;
box-shadow: 0 4px 12px rgba(0, 212, 255, 0.3);
```

#### Secondary Button
```css
background: rgba(18, 18, 26, 0.8);
color: #e4e4e7;
border: 1px solid rgba(0, 212, 255, 0.3);
padding: 8px 16px;
border-radius: 8px;
```

#### Ghost Button
```css
background: transparent;
color: #00d4ff;
padding: 8px 16px;
border-radius: 8px;
```

### Cards

**Elevated glass surface**:

```css
.card {
  background: rgba(18, 18, 26, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 16px;
  box-shadow:
    0 4px 6px rgba(0, 0, 0, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.05);
}
```

### Inputs

**Frosted glass input fields**:

```css
.input {
  background: rgba(10, 10, 15, 0.6);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 8px 12px;
  color: #e4e4e7;
  font-family: "JetBrainsMono Nerd Font";
  font-size: 13px;
  transition: all 250ms ease;
}

.input:focus {
  outline: none;
  border-color: #00d4ff;
  box-shadow: 0 0 0 2px rgba(0, 212, 255, 0.2);
}
```

### Notifications (Mako)

**3 urgency levels** with distinct styling:

```css
/* Low urgency (Cyan) */
.notification.low {
  border-left: 3px solid #00d4ff;
  background: rgba(18, 18, 26, 0.95);
}

/* Normal urgency (Violet) */
.notification.normal {
  border-left: 3px solid #7c3aed;
  background: rgba(18, 18, 26, 0.95);
}

/* Critical urgency (Magenta) */
.notification.critical {
  border-left: 4px solid #ff00aa;
  background: rgba(26, 10, 20, 0.95);
  box-shadow: 0 0 20px rgba(255, 0, 170, 0.4);
}
```

### Tooltips

**Minimal floating info**:

```css
.tooltip {
  background: rgba(34, 34, 46, 0.95);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 6px;
  padding: 4px 8px;
  font-size: 11px;
  color: #e4e4e7;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}
```

---

## Usage Guidelines

### When to Use Each Color

#### Primary Accent (Cyan)
✅ **Use for:**
- Primary actions (submit, save, confirm)
- Active/selected states
- Focus indicators
- Links and interactive elements
- Progress indicators

❌ **Don't use for:**
- Destructive actions
- Warnings or errors
- Disabled states

#### Secondary Accent (Violet)
✅ **Use for:**
- Secondary actions
- Hover states
- Normal priority notifications
- Supporting UI elements

#### Danger (Magenta)
✅ **Use for:**
- Destructive actions (delete, remove)
- Critical errors
- Urgent notifications
- Warning states requiring immediate action

❌ **Don't use for:**
- Success messages
- Informational content

### Accessibility

**Minimum contrast ratios** (WCAG 2.1):

- **Normal text**: 4.5:1 (Level AA)
- **Large text** (18px+): 3:1 (Level AA)
- **UI components**: 3:1 (borders, icons)

**Keyboard navigation**:
- All interactive elements must have visible focus states
- Focus indicator: 2px solid cyan with 2px offset
- Tab order should follow visual hierarchy

**Screen reader support**:
- Use semantic HTML/GTK widgets
- Provide aria-labels for icon-only buttons
- Announce state changes (loading, errors)

### Performance Guidelines

**144fps optimization**:

1. **Limit blur layers**: Max 3 stacked blurred surfaces
2. **Optimize animations**: Use GPU-accelerated properties (transform, opacity)
3. **Avoid layout thrashing**: Batch DOM/GTK updates
4. **Lazy load**: Defer non-visible component rendering
5. **Monitor performance**: Keep frame time < 6.9ms

**Resource usage targets**:
- Idle RAM: < 200MB for all desktop components
- Active RAM: < 400MB
- GPU usage: < 15% idle, < 40% active

---

## Implementation

### NixOS Module Structure

```
glassmorphism/
├── colors.nix          # Design tokens (this system)
├── waybar.nix          # Status bar styling
├── mako.nix            # Notifications
├── wofi.nix            # Application launcher
├── hyprlock.nix        # Lock screen
├── wlogout.nix         # Logout menu
├── kitty.nix           # Terminal styling
├── zellij.nix          # Terminal multiplexer
└── default.nix         # Main module
```

### Accessing Design Tokens

**In Nix configs**:

```nix
{ config, ... }:
let
  colors = config.glassmorphism.colors;
in {
  # Use design tokens
  background = colors.base.bg1;
  foreground = colors.base.fg0;
  accent = colors.accent.cyan;
  borderRadius = colors.radius.medium;
  spacing = colors.spacing.md;
}
```

### CSS Integration

**Generate CSS variables**:

```css
:root {
  /* Base colors */
  --bg-0: #0a0a0f;
  --bg-1: #12121a;
  --fg-0: #ffffff;
  --fg-1: #e4e4e7;

  /* Accents */
  --cyan: #00d4ff;
  --violet: #7c3aed;
  --magenta: #ff00aa;

  /* Spacing */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;

  /* Radius */
  --radius-sm: 8px;
  --radius-md: 12px;

  /* Animation */
  --duration-fast: 150ms;
  --ease-smooth: cubic-bezier(0.4, 0, 0.2, 1);
}
```

### Hyprland Integration

**Apply to window manager**:

```nix
wayland.windowManager.hyprland.settings = {
  general = {
    # Use design tokens
    border_size = 2;
    gaps_in = colors.spacing.sm;
    gaps_out = colors.spacing.md;
    "col.active_border" = "${colors.accent.cyan} ${colors.accent.violet} 45deg";
    "col.inactive_border" = colors.hyprland.inactiveBorder;
  };

  decoration = {
    rounding = colors.radius.medium;
    blur = {
      enabled = true;
      size = colors.blur.size;
      passes = colors.blur.passes;
      xray = colors.blur.xray;
      noise = colors.blur.noise;
    };
  };
};
```

---

## Version History

### 2.0.0 (2025-12-16)
- Initial formal design system documentation
- Consolidated design tokens from colors.nix
- Added typography scale and font stack
- Documented animation curves and timing
- Created component pattern library
- Added accessibility guidelines

### 1.x (Pre-documentation)
- Organic development of glassmorphism theme
- colors.nix token system created
- Component styling in individual modules

---

## Credits

**Design System**: kernelcore
**Implementation**: NixOS + Hyprland + Home Manager
**Font**: JetBrains Mono Nerd Font, Inter
**Inspiration**: Modern UI design, cyberpunk aesthetics, material design principles

---

**Last Updated**: 2025-12-16
**Maintained By**: @VoidNxSEC
**License**: MIT (for design system), individual component licenses apply
