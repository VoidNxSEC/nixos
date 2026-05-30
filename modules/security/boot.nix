{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "quiet"
    "splash"
    "acpi_backlight=native"
    "pcie_aspm=force"
  ];

  boot.initrd.luks.devices."luks-fc184620-7703-4f89-9177-54e39e24a918".device =
    "/dev/disk/by-uuid/fc184620-7703-4f89-9177-54e39e24a918";

}
