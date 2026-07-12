{ pkgs, ... }:

# ═══════════════════════════════════════════════════════════
# DESKTOP — Hyprland/Niri, display manager, X, áudio, periféricos
# ═══════════════════════════════════════════════════════════

{
  kernelcore.desktop.hyprland = {
    enable = true;
    nvidia = true;
  };
  #kernelcore.desktop.hyprland.performance = {
  #enable = config.kernelcore.desktop.hyprland.enable;
  #mode = "balanced";
  #};

  programs.hyprland = {
    enable = true;
    withUWSM = true; # <--- Critical: Enables UWSM wrapper and integration
  };
  programs.niri.enable = true;

  # xdg.portal is managed by kernelcore.desktop.hyprland module

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "br";
      variant = "";
    };
    screenSection = ''
      Option "metamodes" "nvidia-auto-select +0+0 (ForceFullCompositionPipeLIne=On)"
    '';
  };

  services.greetd = {
    enable = false;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
        user = "greeter";
      };
    };
  };

  services.displayManager = {
    # gdm = {
    #enable = false;
    # wayland = true;
    #};
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "hyprland-uwsm";
  };

  # ── Áudio ──
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  kernelcore.audio.production.enable = true;
  kernelcore.audio.videoProduction = {
    enable = true;
    enableNVENC = true;
    fixHeadphoneMute = true;
    lowLatency = true;
  };

  # ── Periféricos / desktop services ──
  services.libinput.enable = true;
  services.printing.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}
