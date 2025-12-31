# Niri Migration Strategy & Hyprland Isolation

## Objective
Migrate the daily driver environment to **Niri** (Glassmorphism Edition) while preserving **Hyprland** as a fallback option accessible via the boot menu (NixOS Specialisation).

## Strategy: NixOS Specialisation
We will use `specialisation` to create a discrete boot entry for Hyprland. The "default" boot entry will load Niri.

### 1. Structure Changes
We need to separate the Window Manager configurations so they don't conflict.

**Current State (Assumed):**
- `hosts/kernelcore/default.nix` imports `hyprland.nix` (system)
- `hosts/kernelcore/home/default.nix` imports `hyprland.nix` (home)

**Target State:**
- `hosts/kernelcore/default.nix`:
    - Enables Niri system-wide.
    - Defines `specialisation.hyprland` which enables Hyprland and disables Niri.
- `hosts/kernelcore/home/niri.nix`: (Already exists) Niri Home Manager config.
- `hosts/kernelcore/home/hyprland.nix`: (Existing) Hyprland Home Manager config.

### 2. Implementation Plan

#### Step A: System Level Configuration (`hosts/kernelcore/default.nix`)

We will modify the main system configuration to default to Niri and use a specialisation for Hyprland.

```nix
{ config, pkgs, lib, inputs, ... }: {
  
  # ... other imports ...

  # ==========================================
  # 1. DEFAULT SESSION (NIRI)
  # ==========================================
  programs.niri.enable = true;
  programs.niri.package = inputs.niri.packages.${pkgs.system}.niri-unstable;
  
  # Disable Hyprland by default
  programs.hyprland.enable = false;

  # Pass a flag to Home Manager to know which WM is active
  # (Requires creating a simple option or using an environment variable)
  environment.sessionVariables.CURRENT_WM = "niri";

  # ==========================================
  # 2. HYPRLAND SPECIALISATION
  # ==========================================
  specialisation = {
    hyprland.configuration = {
      system.nixos.tags = [ "Hyprland" ];
      
      # Enable Hyprland
      programs.hyprland.enable = true;
      
      # Disable Niri
      programs.niri.enable = lib.mkForce false;
      
      environment.sessionVariables.CURRENT_WM = "hyprland";
    };
  };
}
```

#### Step B: Home Manager Conditional Logic (`hosts/kernelcore/home/default.nix`)

Home Manager needs to know which config to load. Since Home Manager is typically imported once, we need to conditionally import the WM config based on the specialisation or system state.

A robust way to do this within NixOS integrated Home Manager:

```nix
{ config, osConfig, lib, ... }: {
  
  imports = [
    # Shared configs (Theme, Apps, Git, etc.)
    ./glassmorphism
    ./alacritty.nix
    # ...
  ] 
  ++ lib.optional (osConfig.programs.niri.enable) ./niri.nix
  ++ lib.optional (osConfig.programs.niri.enable) ./waybar-niri.nix
  ++ lib.optional (osConfig.programs.hyprland.enable) ./hyprland.nix;

  # Optional: Conflict resolution if both try to set same files
  # (e.g. both wanting to write to ~/.config/waybar/config)
  # waybar-niri.nix already uses different script paths, but ensure
  # main config doesn't collide.
}
```

*Note: `osConfig` allows Home Manager to see the system configuration.*

### 3. Execution Steps

1.  **Backup**: Ensure current `flake.nix` and configs are committed.
2.  **Edit `flake.nix`**: Add `niri` input if not present.
3.  **Edit `hosts/kernelcore/default.nix`**: Apply the Specialisation block.
4.  **Edit `hosts/kernelcore/home/default.nix`**: Apply the conditional imports using `osConfig`.
5.  **Rebuild**: `nixos-rebuild switch --flake .#kernelcore`
6.  **Reboot**: You will see "NixOS" (Niri) and "NixOS - Hyprland" in the bootloader.

### 4. Verification
- **Boot Default**: Should launch Niri. `waybar` should look different (Niri modules).
- **Boot Hyprland**: Select "Hyprland" in GRUB/systemd-boot. Should load familiar Hyprland session.

## Notes
- **Waybar**: `waybar-niri.nix` is already designed to be standalone. Ensure `hyprland.nix` imports the standard `waybar.nix` and `niri.nix` imports `waybar-niri.nix`.
- **Conflicts**: If `glassmorphism/default.nix` imports `waybar.nix` unconditionally, remove that import and let the WM-specific files handle the bar.
