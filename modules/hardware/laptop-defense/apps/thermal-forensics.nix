# Laptop Defense — thermal-forensics: scientific thermal evidence collection
# (baseline/stress/analysis phases). Part of the flake.nix split; see ../flake.nix.
{ pkgs }:

pkgs.writeShellApplication {
  name = "thermal-forensics";
  runtimeInputs = with pkgs; [
    lm_sensors
    stress-ng
    s-tui
    gnuplot
    jq
    python313
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
}
