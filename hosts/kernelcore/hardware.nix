{ ... }:

# ═══════════════════════════════════════════════════════════
# HARDWARE — GPU NVIDIA (prime offload), Intel, Bluetooth, WiFi
# ═══════════════════════════════════════════════════════════

{
  kernelcore.nvidia = {
    enable = true;
    cudaSupport = true;
    prime = {
      enable = true;
      offload = true;
      sync = false;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # GPU power limit - raised from 50W to the 65W hardware max for llamacpp-turbo
  # inference performance. Trades battery/thermal headroom for sustained clocks.
  kernelcore.nvidia.powerLimit = 65;

  kernelcore.hardware.intel.enable = true;
  kernelcore.hardware.bluetooth.enable = true;
  kernelcore.hardware.wifi-optimization.enable = true;
  kernelcore.hardware.i915-governor.enable = false;

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
