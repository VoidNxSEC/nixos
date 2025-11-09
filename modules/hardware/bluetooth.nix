{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.kernelcore.bluetooth;
in
{
  options.kernelcore.bluetooth = {
    enable = mkEnableOption "Bluetooth support with GUI management";
  };

  config = mkIf cfg.enable {
    # Enable Bluetooth hardware
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true; # Power on Bluetooth adapter on boot
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true; # Enable experimental features
        };
      };
    };

    # Enable Blueman for GUI management (works great with Hyprland)
    services.blueman.enable = true;

    # Add Bluetooth packages
    environment.systemPackages = with pkgs; [
      bluez # Bluetooth protocol stack
      bluez-tools # Additional Bluetooth tools
      blueman # GUI Bluetooth manager
    ];

    # Enable PulseAudio/PipeWire Bluetooth support
    # (assuming PipeWire is used, which is common with Hyprland)
    hardware.bluetooth.settings.Policy = {
      AutoEnable = true;
    };
  };
}
