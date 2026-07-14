# Laptop Defense — thermal-warroom: real-time thermal monitor display.
# Part of the flake.nix split; see ../flake.nix.
{ pkgs }:

pkgs.writeShellApplication {
  name = "thermal-warroom";
  runtimeInputs = with pkgs; [
    lm_sensors
    watch
    ncurses
  ];

  text = ''
    # Colors
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'

    while true; do
      clear
      echo "╔════════════════════════════════════════════════════════════╗"
      echo "║           THERMAL WAR ROOM - LIVE MONITORING              ║"
      echo "╚════════════════════════════════════════════════════════════╝"
      echo ""

      # Get temps
      TEMPS=$(sensors 2>/dev/null | grep -E "Core|Package|temp" | head -10 || echo "No sensors found")

      # Parse and colorize
      echo "$TEMPS" | while IFS= read -r line; do
        TEMP=$(echo "$line" | grep -oP '\+\K[0-9]+' | head -1 || echo "0")

        if [ -n "$TEMP" ] && [ "$TEMP" != "0" ]; then
          if [ "$TEMP" -gt 85 ]; then
            echo -e "''${RED}🔥 $line''${NC}"
          elif [ "$TEMP" -gt 70 ]; then
            echo -e "''${YELLOW}⚠️  $line''${NC}"
          else
            echo -e "''${GREEN}✅ $line''${NC}"
          fi
        else
          echo "$line"
        fi
      done

      echo ""
      echo "CPU Frequency:"
      cat /proc/cpuinfo | grep "cpu MHz" | head -4 || echo "Not available"

      echo ""
      echo "Load Average:"
      uptime

      echo ""
      echo "Governor:"
      cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Not available"

      echo ""
      echo "Throttle Status:"
      if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
        if [ "$TURBO" = "1" ]; then
          echo -e "''${RED}Turbo DISABLED''${NC}"
        else
          echo -e "''${GREEN}Turbo ENABLED''${NC}"
        fi
      else
        echo "Not available (AMD or not supported)"
      fi

      echo ""
      echo "Press Ctrl+C to exit"

      sleep 2
    done
  '';
}
