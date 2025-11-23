{
  description = "Laptop Defense Framework - Hardware Forensics Suite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # ============================================
    # THERMAL FORENSICS - Evidência científica
    # ============================================

    thermalForensics = pkgs.writeShellApplication {
      name = "thermal-forensics";
      runtimeInputs = with pkgs; [
        lm_sensors
        stress-ng
        s-tui
        gnuplot
        jq
        python3
        curl
      ];

      text = ''
        set -e

        REPORT_DIR="/tmp/thermal-evidence-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$REPORT_DIR"/{raw,graphs,analysis}

        echo "🔥 THERMAL FORENSICS SUITE"
        echo "=========================="
        echo "Report: $REPORT_DIR"
        echo ""

        # ============================================
        # Phase 1: BASELINE (idle)
        # ============================================

        echo "📊 Phase 1: Baseline measurements (60s idle)..."

        for i in {1..60}; do
          TIMESTAMP=$(date +%s)

          # CPU temps
          TEMPS=$(sensors -j 2>/dev/null || echo '{}')

          # CPU freq
          FREQ=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')

          # Load
          LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)

          # Throttle status
          THROTTLE=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -1)

          echo "$TIMESTAMP,baseline,$TEMPS,$FREQ,$LOAD,$THROTTLE" >> "$REPORT_DIR/raw/thermal-timeline.csv"

          sleep 1
        done

        echo "✅ Baseline complete"

        # ============================================
        # Phase 2: STRESS TEST (controlled load)
        # ============================================

        echo "📊 Phase 2: Stress test (120s CPU stress)..."

        # Background monitoring
        (
          while true; do
            TIMESTAMP=$(date +%s)
            TEMPS=$(sensors -j 2>/dev/null || echo '{}')
            FREQ=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')
            LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)
            THROTTLE=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -1)

            echo "$TIMESTAMP,stress,$TEMPS,$FREQ,$LOAD,$THROTTLE" >> "$REPORT_DIR/raw/thermal-timeline.csv"

            sleep 1
          done
        ) &
        MONITOR_PID=$!

        # Stress CPU
        timeout 120 stress-ng --cpu $(nproc) --timeout 120s --metrics-brief > "$REPORT_DIR/raw/stress-output.txt" 2>&1 || true

        kill $MONITOR_PID 2>/dev/null || true

        echo "✅ Stress test complete"

        # ============================================
        # Phase 3: REBUILD SIMULATION
        # ============================================

        echo "📊 Phase 3: Rebuild simulation (nix build)..."

        # Monitor during actual nix build
        (
          while true; do
            TIMESTAMP=$(date +%s)
            TEMPS=$(sensors -j 2>/dev/null || echo '{}')
            FREQ=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}')
            LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)
            THROTTLE=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | head -1)

            echo "$TIMESTAMP,rebuild,$TEMPS,$FREQ,$LOAD,$THROTTLE" >> "$REPORT_DIR/raw/thermal-timeline.csv"

            sleep 1
          done
        ) &
        MONITOR_PID=$!

        # Build something non-trivial
        timeout 300 nix build nixpkgs#hello --rebuild 2>&1 | tee "$REPORT_DIR/raw/rebuild-output.txt" || true

        kill $MONITOR_PID 2>/dev/null || true

        echo "✅ Rebuild simulation complete"

        # ============================================
        # Phase 4: ANALYSIS
        # ============================================

        echo "📊 Phase 4: Analyzing data..."

        python3 <<'PYTHON' > "$REPORT_DIR/analysis/thermal-analysis.json"
import json
import csv
import statistics
from collections import defaultdict

# Parse CSV
data = {'baseline': [], 'stress': [], 'rebuild': []}

try:
    with open('$REPORT_DIR/raw/thermal-timeline.csv', 'r') as f:
        for line in f:
            parts = line.strip().split(',')
            if len(parts) >= 3:
                timestamp = int(parts[0])
                phase = parts[1]

                # Extract temp from JSON (simplified - adapt to your sensors output)
                try:
                    temps_str = ','.join(parts[2:-3])
                    # Basic extraction - you'll need to adapt this
                    data[phase].append({
                        'timestamp': timestamp,
                        'raw': temps_str
                    })
                except:
                    pass
except FileNotFoundError:
    pass

# Analysis
analysis = {
    'baseline': {
        'duration_s': len(data['baseline']),
        'samples': len(data['baseline'])
    },
    'stress': {
        'duration_s': len(data['stress']),
        'samples': len(data['stress'])
    },
    'rebuild': {
        'duration_s': len(data['rebuild']),
        'samples': len(data['rebuild'])
    },
    'verdict': 'ANALYZE_MANUALLY'  # Will be refined
}

print(json.dumps(analysis, indent=2))
PYTHON

        # ============================================
        # Phase 5: HARDWARE CHECKS
        # ============================================

        echo "🔍 Phase 5: Hardware diagnostics..."

        # CPU info
        lscpu > "$REPORT_DIR/raw/cpu-info.txt"

        # Thermal zones
        for zone in /sys/class/thermal/thermal_zone*; do
          echo "=== $(basename $zone) ===" >> "$REPORT_DIR/raw/thermal-zones.txt"
          cat "$zone/type" >> "$REPORT_DIR/raw/thermal-zones.txt" 2>/dev/null || true
          cat "$zone/temp" >> "$REPORT_DIR/raw/thermal-zones.txt" 2>/dev/null || true
          echo "" >> "$REPORT_DIR/raw/thermal-zones.txt"
        done

        # Cooling devices
        for cool in /sys/class/thermal/cooling_device*; do
          echo "=== $(basename $cool) ===" >> "$REPORT_DIR/raw/cooling-devices.txt"
          cat "$cool/type" >> "$REPORT_DIR/raw/cooling-devices.txt" 2>/dev/null || true
          cat "$cool/cur_state" >> "$REPORT_DIR/raw/cooling-devices.txt" 2>/dev/null || true
          echo "" >> "$REPORT_DIR/raw/cooling-devices.txt"
        done

        # DMI/SMBIOS info
        sudo dmidecode -t processor > "$REPORT_DIR/raw/dmi-processor.txt" 2>/dev/null || echo "dmidecode not available" > "$REPORT_DIR/raw/dmi-processor.txt"
        sudo dmidecode -t system > "$REPORT_DIR/raw/dmi-system.txt" 2>/dev/null || echo "dmidecode not available" > "$REPORT_DIR/raw/dmi-system.txt"

        # Power profile
        cat /sys/firmware/acpi/platform_profile 2>/dev/null > "$REPORT_DIR/raw/power-profile.txt" || echo "N/A" > "$REPORT_DIR/raw/power-profile.txt"

        # Governor
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort -u > "$REPORT_DIR/raw/cpu-governor.txt" 2>/dev/null || echo "N/A" > "$REPORT_DIR/raw/cpu-governor.txt"

        # Turbo status
        cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null > "$REPORT_DIR/raw/turbo-status.txt" || echo "N/A (AMD or not available)" > "$REPORT_DIR/raw/turbo-status.txt"

        echo "✅ Hardware diagnostics complete"

        # ============================================
        # Phase 6: SUSPICIOUS PROCESS CHECK
        # ============================================

        echo "🔍 Phase 6: Checking for thermal saboteurs..."

        # Top CPU consumers
        ps aux | head -20 > "$REPORT_DIR/raw/top-cpu-processes.txt" 2>/dev/null || echo "ps not available" > "$REPORT_DIR/raw/top-cpu-processes.txt"

        # ClamAV status
        systemctl status clamav-daemon 2>&1 > "$REPORT_DIR/raw/clamav-status.txt" || echo "Not running or not installed" > "$REPORT_DIR/raw/clamav-status.txt"

        # Check if ClamAV is scanning during builds
        if pgrep clamd >/dev/null; then
          echo "⚠️  ClamAV is running - SUSPECT" > "$REPORT_DIR/analysis/clamav-verdict.txt"
          lsof -p $(pgrep clamd) > "$REPORT_DIR/raw/clamav-files.txt" 2>&1 || true
        else
          echo "✅ ClamAV not active" > "$REPORT_DIR/analysis/clamav-verdict.txt"
        fi

        # Other suspects
        pgrep -a "tracker|baloo|updatedb|freshclam" > "$REPORT_DIR/raw/background-indexers.txt" 2>/dev/null || echo "None found" > "$REPORT_DIR/raw/background-indexers.txt"

        echo "✅ Process analysis complete"

        # ============================================
        # Phase 7: GENERATE VERDICT
        # ============================================

        echo ""
        echo "📋 GENERATING VERDICT..."
        echo ""

        cat > "$REPORT_DIR/VERDICT.txt" <<'EOF'
╔════════════════════════════════════════════════════════════╗
║           THERMAL FORENSICS - EVIDENCE REPORT             ║
╚════════════════════════════════════════════════════════════╝

CRITICAL INDICATORS TO REVIEW:

1. TEMPERATURE PATTERN
   [ ] Stable under load → NORMAL
   [ ] Gradual increase → NORMAL
   [ ] Intermittent spikes → SUSPICIOUS (thermal paste?)
   [ ] Erratic fluctuations → CRITICAL (hardware failure)
   [ ] Immediate thermal throttle → COOLING FAILURE

2. FREQUENCY SCALING
   [ ] Consistent under stress → NORMAL
   [ ] Throttling at <80°C → CONFIG ISSUE
   [ ] No throttling at >95°C → SENSOR FAILURE
   [ ] Random freq drops → POWER DELIVERY ISSUE

3. PROCESS INTERFERENCE
   [ ] ClamAV active during builds → DISABLE IT
   [ ] Indexing services running → DISABLE THEM
   [ ] Unknown CPU hogs → INVESTIGATE

4. HARDWARE HEALTH
   [ ] Review dmi-processor.txt for errors
   [ ] Check cooling-devices.txt for active cooling
   [ ] Verify turbo-status.txt shows turbo enabled

DECISION MATRIX:

IF erratic temps + no throttling → HARDWARE FAILURE (replace)
IF high temps + proper throttling → COOLING ISSUE (repaste/clean)
IF normal temps + slow builds → SOFTWARE ISSUE (ClamAV/config)
IF intermittent + random → POWER DELIVERY (check battery/PSU)

NEXT STEPS:
1. Review graphs in ./graphs/
2. Check raw data in ./raw/
3. Compare with manufacturer specs
4. Run warranty check if suspicious

Generated: $(date)
EOF

        echo "✅ Report complete: $REPORT_DIR"
        echo ""
        echo "📊 Quick summary:"
        cat "$REPORT_DIR/VERDICT.txt"

        # Archive
        tar czf "$REPORT_DIR.tar.gz" "$REPORT_DIR"
        echo ""
        echo "📦 Evidence archived: $REPORT_DIR.tar.gz"
        echo "📍 Location: $REPORT_DIR"
      '';
    };

    # ============================================
    # MCP LOG EXTRACTOR - Puxa histórico
    # ============================================

    mcpLogExtractor = pkgs.writeShellApplication {
      name = "mcp-log-extract";
      runtimeInputs = with pkgs; [ curl jq sqlite ];

      text = ''
        set -e

        OUTPUT_DIR="/tmp/mcp-evidence-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$OUTPUT_DIR"

        echo "🔍 Extracting MCP knowledge database..."
        echo ""

        # SQLite local knowledge database
        if [ -f "/var/lib/mcp-knowledge/knowledge.db" ]; then
          echo "📂 Found MCP knowledge database"

          sqlite3 /var/lib/mcp-knowledge/knowledge.db <<'SQL' > "$OUTPUT_DIR/recent-knowledge.json"
SELECT json_group_array(
  json_object(
    'id', id,
    'timestamp', timestamp,
    'entry_type', entry_type,
    'content', content,
    'tags', tags
  )
)
FROM knowledge_entries
WHERE timestamp > datetime('now', '-7 days')
ORDER BY timestamp DESC;
SQL

          echo "✅ Extracted recent knowledge entries"

          # Extract rebuild/thermal related
          sqlite3 /var/lib/mcp-knowledge/knowledge.db <<'SQL' > "$OUTPUT_DIR/rebuild-knowledge.json"
SELECT json_group_array(
  json_object(
    'id', id,
    'timestamp', timestamp,
    'entry_type', entry_type,
    'content', substr(content, 1, 200)
  )
)
FROM knowledge_entries
WHERE content LIKE '%rebuild%' OR content LIKE '%thermal%' OR content LIKE '%freeze%'
ORDER BY timestamp DESC
LIMIT 50;
SQL

          echo "✅ Extracted rebuild/thermal related entries"
        else
          echo "⚠️  MCP knowledge database not found"
        fi

        # Parse for relevant snippets
        echo ""
        echo "📊 Analyzing knowledge base for evidence..."

        if [ -f "$OUTPUT_DIR/rebuild-knowledge.json" ]; then
          jq -r '.[] | select(.content | contains("panic") or contains("freeze") or contains("thermal")) | .id' \
            "$OUTPUT_DIR/rebuild-knowledge.json" > "$OUTPUT_DIR/relevant-entry-ids.txt" 2>/dev/null || true
        fi

        echo "✅ Evidence extracted to: $OUTPUT_DIR"

        tar czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
        echo "📦 Archive: $OUTPUT_DIR.tar.gz"
      '';
    };

    # ============================================
    # REAL-TIME THERMAL MONITOR - War room display
    # ============================================

    thermalMonitor = pkgs.writeShellApplication {
      name = "thermal-warroom";
      runtimeInputs = with pkgs; [ lm_sensors watch ncurses ];

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
    };

    # ============================================
    # DECISION FRAMEWORK - Automated verdict
    # ============================================

    decisionFramework = pkgs.writeShellApplication {
      name = "laptop-verdict";
      runtimeInputs = with pkgs; [ jq ];

      text = ''
        set -e

        EVIDENCE_DIR="''${1:?Usage: laptop-verdict <evidence-dir>}"

        echo "🎯 DECISION FRAMEWORK - Laptop Replacement Analysis"
        echo "=================================================="
        echo ""

        SCORE=0
        CRITICAL=0

        # Check 1: Thermal behavior
        if grep -q "erratic" "$EVIDENCE_DIR/VERDICT.txt" 2>/dev/null; then
          echo "❌ CRITICAL: Erratic thermal behavior detected"
          CRITICAL=$((CRITICAL + 1))
          SCORE=$((SCORE + 50))
        fi

        # Check 2: Hardware age
        if [ -f "$EVIDENCE_DIR/raw/dmi-system.txt" ]; then
          YEAR=$(grep "Release Date" "$EVIDENCE_DIR/raw/dmi-system.txt" | grep -oP '\d{4}' | head -1 || echo "2020")
          AGE=$(($(date +%Y) - YEAR))

          if [ "$AGE" -gt 5 ]; then
            echo "⚠️  Laptop is $AGE years old (>5 years)"
            SCORE=$((SCORE + 20))
          fi
        fi

        # Check 3: Warranty status
        echo ""
        read -p "Is laptop still under warranty? (y/n): " WARRANTY
        if [ "$WARRANTY" = "n" ]; then
          echo "⚠️  Out of warranty - repair costs likely high"
          SCORE=$((SCORE + 15))
        fi

        # Check 4: Repair history
        echo ""
        read -p "Has this issue happened before? (y/n): " RECURRING
        if [ "$RECURRING" = "y" ]; then
          echo "❌ CRITICAL: Recurring issue"
          CRITICAL=$((CRITICAL + 1))
          SCORE=$((SCORE + 30))
        fi

        # Check 5: ClamAV interference
        if grep -q "ClamAV is running" "$EVIDENCE_DIR/analysis/clamav-verdict.txt" 2>/dev/null; then
          echo "⚠️  ClamAV may be interfering (try disabling first)"
          SCORE=$((SCORE - 20))  # Lower replacement score
        fi

        # Generate verdict
        echo ""
        echo "════════════════════════════════════════"
        echo "FINAL SCORE: $SCORE/100"
        echo "CRITICAL FLAGS: $CRITICAL"
        echo "════════════════════════════════════════"
        echo ""

        if [ "$CRITICAL" -ge 2 ] || [ "$SCORE" -ge 80 ]; then
          echo "🔴 VERDICT: REPLACE LAPTOP"
          echo ""
          echo "Reasoning:"
          echo "- Multiple critical hardware indicators"
          echo "- Likely hardware failure beyond economical repair"
          echo "- Risk of data loss and work disruption"
          echo ""
          echo "Recommended action:"
          echo "1. Backup ALL data immediately"
          echo "2. Document evidence for warranty/insurance claim"
          echo "3. Research replacement options"
          echo "4. Plan migration timeline"

        elif [ "$SCORE" -ge 50 ]; then
          echo "🟡 VERDICT: INVESTIGATE FURTHER"
          echo ""
          echo "Recommended actions:"
          echo "1. Disable ClamAV and re-test"
          echo "2. Clean fans and reapply thermal paste"
          echo "3. Check BIOS settings"
          echo "4. Monitor for 1 week"
          echo "5. Re-evaluate with new data"

        else
          echo "🟢 VERDICT: SOFTWARE ISSUE"
          echo ""
          echo "Likely causes:"
          echo "- ClamAV interfering with builds"
          echo "- Misconfigured power management"
          echo "- Background indexing services"
          echo ""
          echo "Recommended actions:"
          echo "1. Disable ClamAV during rebuilds"
          echo "2. Optimize Nix daemon settings"
          echo "3. Review systemd services"
        fi

        # Generate report
        cat > "$EVIDENCE_DIR/FINAL-VERDICT.txt" <<EOF
LAPTOP REPLACEMENT DECISION FRAMEWORK
=====================================

Score: $SCORE/100
Critical Flags: $CRITICAL

Evidence Location: $EVIDENCE_DIR
Generated: $(date)

[See detailed analysis above]
EOF

        echo ""
        echo "📄 Final verdict saved to: $EVIDENCE_DIR/FINAL-VERDICT.txt"
      '';
    };

  in {

    packages.${system} = {
      inherit thermalForensics mcpLogExtractor thermalMonitor decisionFramework;

      # All-in-one evidence collector
      fullInvestigation = pkgs.writeShellApplication {
        name = "laptop-investigation";
        runtimeInputs = [ thermalForensics mcpLogExtractor decisionFramework ];

        text = ''
          set -e

          echo "🔬 FULL LAPTOP INVESTIGATION SUITE"
          echo "=================================="
          echo ""

          # Step 1: Thermal forensics
          echo "Step 1/3: Collecting thermal evidence..."
          thermal-forensics

          LATEST_THERMAL=$(ls -td /tmp/thermal-evidence-* 2>/dev/null | head -1 || echo "")

          if [ -z "$LATEST_THERMAL" ]; then
            echo "❌ Thermal evidence collection failed"
            exit 1
          fi

          # Step 2: MCP logs
          echo ""
          echo "Step 2/3: Extracting MCP knowledge history..."
          mcp-log-extract || true

          # Step 3: Decision
          echo ""
          echo "Step 3/3: Generating verdict..."
          laptop-verdict "$LATEST_THERMAL"

          echo ""
          echo "✅ INVESTIGATION COMPLETE"
          echo ""
          echo "Evidence package: $LATEST_THERMAL.tar.gz"
        '';
      };
    };

    apps.${system} = {
      thermal-forensics = {
        type = "app";
        program = "${thermalForensics}/bin/thermal-forensics";
      };

      thermal-warroom = {
        type = "app";
        program = "${thermalMonitor}/bin/thermal-warroom";
      };

      mcp-extract = {
        type = "app";
        program = "${mcpLogExtractor}/bin/mcp-log-extract";
      };

      verdict = {
        type = "app";
        program = "${decisionFramework}/bin/laptop-verdict";
      };

      full-investigation = {
        type = "app";
        program = "${self.packages.${system}.fullInvestigation}/bin/laptop-investigation";
      };
    };

    # NixOS module pra proteção térmica
    nixosModules.thermalProtection = { config, lib, pkgs, ... }:
    with lib;
    {
      options.hardware.thermalProtection = {
        enable = mkEnableOption "Thermal protection and emergency brake";

        maxTemp = mkOption {
          type = types.int;
          default = 95;
          description = "Maximum temperature (°C) before emergency brake";
        };
      };

      config = mkIf config.hardware.thermalProtection.enable {
        # Disable ClamAV durante rebuilds
        systemd.services.clamav-daemon.serviceConfig = mkIf (config.services.clamav.daemon.enable or false) {
          Nice = 19;  # Baixa prioridade
          CPUQuota = "25%";  # Limita CPU
        };

        # Thermal emergency brake
        systemd.services.thermal-emergency = {
          description = "Emergency thermal protection";
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "30s";

            ExecStart = pkgs.writeShellScript "thermal-guard" ''
              while true; do
                MAX_TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")

                if [ "''${MAX_TEMP:-0}" -gt ${toString config.hardware.thermalProtection.maxTemp} ]; then
                  echo "🚨 THERMAL EMERGENCY: ''${MAX_TEMP}°C" | ${pkgs.systemd}/bin/systemd-cat -t thermal-emergency -p err

                  # Kill rebuild if running
                  ${pkgs.procps}/bin/pkill -TERM nixos-rebuild || true
                  ${pkgs.procps}/bin/pkill -TERM nix || true

                  # Force CPU governor to powersave
                  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                    echo powersave > "$cpu" 2>/dev/null || true
                  done

                  # Disable turbo (Intel)
                  echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

                  sleep 30
                fi

                sleep 5
              done
            '';
          };
        };

        # Install forensics tools
        environment.systemPackages = with self.packages.${system}; [
          thermalForensics
          thermalMonitor
          mcpLogExtractor
          decisionFramework
          fullInvestigation
        ];
      };
    };
  };
}
