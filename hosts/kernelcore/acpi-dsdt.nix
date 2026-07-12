{ pkgs, ... }:

# ============================================================
# ACPI DSDT Override (hardware-específico deste laptop)
# ============================================================
# Injeta uma DSDT corrigida (hosts/kernelcore/acpi-fix/dsdt.aml) no initrd
# para contornar bugs de firmware. Migrado do configuration.nix na Fase 3
# do desmonte (docs/architecture/TOPOLOGY.md §6).
# ============================================================

{
  boot.initrd.prepend = [
    "${
      pkgs.runCommand "acpi-override"
        {
          nativeBuildInputs = [
            pkgs.cpio
            pkgs.findutils
          ];
        }
        ''
          mkdir -p $out/kernel/firmware/acpi
          cp ${./acpi-fix/dsdt.aml} $out/kernel/firmware/acpi/dsdt.aml
          find $out -print0 | cpio -o -H newc --reproducible -0 > $out/acpi_override.cpio
        ''
    }/acpi_override.cpio"
  ];
}
