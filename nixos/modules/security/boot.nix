{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
    consoleMode = "max";
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.zfs.forceImportRoot = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "acpi_backlight=native"
    "pcie_aspm=force"
  ];

  boot.initrd.luks.devices."luks-49aa90f9-15d5-4622-a2e6-02a989ecc7e3".device =
    "/dev/disk/by-uuid/49aa90f9-15d5-4622-a2e6-02a989ecc7e3";

}
