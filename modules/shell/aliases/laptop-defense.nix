{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# LAPTOP DEFENSE ALIASES
# ============================================================
# Aliases para thermal forensics e proteção de hardware

{
  environment.shellAliases = {
    # ========================================
    # THERMAL FORENSICS
    # ========================================

    # Full forensic analysis
    "thermal-forensics" = "nix run /etc/nixos/modules/hardware/laptop-defense#thermal-forensics";
    "tf" = "nix run /etc/nixos/modules/hardware/laptop-defense#thermal-forensics";

    # War room monitor
    "thermal-warroom" = "nix run /etc/nixos/modules/hardware/laptop-defense#thermal-warroom";
    "tw" = "nix run /etc/nixos/modules/hardware/laptop-defense#thermal-warroom";

    # Quick verdict
    "laptop-verdict" = "nix run /etc/nixos/modules/hardware/laptop-defense#verdict";
    "lv" = "nix run /etc/nixos/modules/hardware/laptop-defense#verdict";

    # Full investigation
    "laptop-investigation" = "nix run /etc/nixos/modules/hardware/laptop-defense#full-investigation";
    "li" = "nix run /etc/nixos/modules/hardware/laptop-defense#full-investigation";

    # MCP knowledge extract
    "mcp-extract" = "nix run /etc/nixos/modules/hardware/laptop-defense#mcp-extract";

    # ========================================
    # SAFE REBUILD
    # ========================================

    # Safe rebuild with thermal monitoring
    "safe-rebuild" = "safe-nixos-rebuild switch";
    "sr" = "safe-nixos-rebuild switch";

    # Safe rebuild with fast mode
    "safe-rebuild-fast" = "safe-nixos-rebuild switch --fast";
    "srf" = "safe-nixos-rebuild switch --fast";

    # Pre-rebuild check
    "rebuild-check" = "mcp-rebuild-check";
    "rc" = "mcp-rebuild-check";

    # ========================================
    # THERMAL MONITORING
    # ========================================

    # Quick temperature check
    "temp-check" = "sensors | grep -E 'Core|Package|temp' | head -10";
    "tc" = "sensors | grep -E 'Core|Package|temp' | head -10";

    # Continuous temperature monitoring
    "temp-watch" = "watch -n 2 'sensors | grep -E \"Core|Package|temp\"'";

    # Temperature with threshold alert
    "temp-alert" = "mcp-thermal-check 75";

    # ========================================
    # EVIDENCE MANAGEMENT
    # ========================================

    # List thermal evidence
    "thermal-evidence-list" = "ls -lht /var/log/rebuild-evidence/ 2>/dev/null | head -20";
    "tel" = "ls -lht /var/log/rebuild-evidence/ 2>/dev/null | head -20";

    # View latest thermal log
    "thermal-log" = "tail -50 /var/log/rebuild-thermal.log";
    "tl" = "tail -50 /var/log/rebuild-thermal.log";

    # View rebuild evidence
    "rebuild-evidence" = "ls -lht /tmp/thermal-evidence-* 2>/dev/null | head -10";
    "re" = "ls -lht /tmp/thermal-evidence-* 2>/dev/null | head -10";

    # ========================================
    # SYSTEM HEALTH
    # ========================================

    # Full system health check
    "system-health" = ''
      echo "=== THERMAL ===" && \
      sensors | grep -E "Core|Package" | head -5 && \
      echo "" && \
      echo "=== CPU ===" && \
      uptime && \
      echo "" && \
      echo "=== MEMORY ===" && \
      free -h && \
      echo "" && \
      echo "=== DISK ===" && \
      df -h / /nix
    '';
    "sh" = "system-health"; # Note: conflicts with shell, use full name

    # Check if safe to rebuild
    "can-rebuild" = ''
      TEMP=$(sensors 2>/dev/null | grep -oP '+\K[0-9]+' | sort -rn | head -1 || echo "0") && \
      if [ "$TEMP" -le 75 ]; then \
        echo "✅ SAFE: Temperature $TEMP°C"; \
      else \
        echo "❌ UNSAFE: Temperature $TEMP°C (wait for <75°C)"; \
      fi
    '';
    "cr" = "can-rebuild";

    # ========================================
    # THERMAL PROFILES (i5-13420H + RTX 3050)
    # ========================================

    # Profile management
    "profile-status" = "thermal-profile status";
    "ps" = "thermal-profile status";

    "profile-silent" = "thermal-profile silent && sudo systemctl restart thermal-profile-manager";
    "psi" = "thermal-profile silent && sudo systemctl restart thermal-profile-manager";

    "profile-balanced" = "thermal-profile balanced && sudo systemctl restart thermal-profile-manager";
    "pb" = "thermal-profile balanced && sudo systemctl restart thermal-profile-manager";

    "profile-performance" =
      "thermal-profile performance && sudo systemctl restart thermal-profile-manager";
    "pp" = "thermal-profile performance && sudo systemctl restart thermal-profile-manager";

    "profile-stats" = "thermal-profile stats";
    "pst" = "thermal-profile stats";

    "profile-watch" = "thermal-profile watch";
    "pw" = "thermal-profile watch";

    # ========================================
    # EMERGENCY
    # ========================================

    # Force cooldown (now uses thermal profile)
    "force-cooldown" =
      "thermal-profile silent && sudo systemctl restart thermal-profile-manager && echo '✅ Emergency cooldown activated (Silent profile)'";
    "fc" = "force-cooldown";

    # Reset to performance (now uses thermal profile)
    "reset-performance" =
      "thermal-profile performance && sudo systemctl restart thermal-profile-manager && echo '✅ Performance restored (Performance profile)'";
    "rp" = "reset-performance";

    # Legacy manual controls (kept for compatibility)
    "force-cooldown-manual" = ''
      echo "Forcing CPU to powersave..." && \
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do \
        echo powersave | sudo tee $cpu > /dev/null 2>&1; \
      done && \
      echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 && \
      echo "✅ Manual cooldown activated"
    '';

    "reset-performance-manual" = ''
      echo "Resetting to performance..." && \
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do \
        echo performance | sudo tee $cpu > /dev/null 2>&1; \
      done && \
      echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 && \
      echo "✅ Manual performance restored"
    '';

    # ========================================
    # GPU MONITORING (RTX 3050)
    # ========================================

    # NVIDIA GPU status
    "gpu-status" =
      "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw,clocks.gr,clocks.mem --format=csv,noheader";
    # Note: "gs" removed - conflicts with "git status" in utils.nix
    # Use "gpu-status" instead

    # GPU watch
    "gpu-watch" = "watch -n 2 nvidia-smi";
    "gw" = "watch -n 2 nvidia-smi";

    # GPU power limit info
    "gpu-power" = "nvidia-smi -q -d POWER | grep -E 'Power Limit|Power Draw'";
    # Note: "gp" removed - conflicts with "git push" in utils.nix
    # Use "gpu-power" instead

    # ========================================
    # DOCUMENTATION
    # ========================================

    # Show laptop defense guide
    "laptop-defense-guide" = "cat /etc/nixos/docs/LAPTOP-DEFENSE-FRAMEWORK.md";
    "ldg" = "cat /etc/nixos/docs/LAPTOP-DEFENSE-FRAMEWORK.md";

    # Show thermal hooks documentation
    "rebuild-hooks-doc" = "cat /etc/nixos/docs/REBUILD-HOOKS.md";
    "rhd" = "cat /etc/nixos/docs/REBUILD-HOOKS.md";
  };

  # ========================================
  # SHELL INIT
  # ========================================

  environment.interactiveShellInit = ''
    # Laptop Defense Framework disponível
    # safe-rebuild, thermal-forensics, laptop-investigation
    # Digite: ldg (laptop-defense-guide)
  '';
}
