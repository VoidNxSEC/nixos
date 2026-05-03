{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.soc;

  # SOC Status Tool
  soc-status = pkgs.writeShellScriptBin "soc-status" ''
    #!/usr/bin/env bash
    set -euo pipefail

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
    echo -e "''${BLUE}       🛡️  SECURITY OPERATIONS CENTER STATUS''${NC}"
    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
    echo ""

    check_service() {
      local service=$1
      local name=$2
      if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "  ''${GREEN}✓''${NC} $name: ''${GREEN}Active''${NC}"
        return 0
      else
        echo -e "  ''${RED}✗''${NC} $name: ''${RED}Inactive''${NC}"
        return 1
      fi
    }

    echo -e "''${YELLOW}📊 Core Services:''${NC}"
    check_service "auditd" "Audit Daemon" || true
    check_service "wazuh-manager" "Wazuh SIEM" || true
    check_service "opensearch" "OpenSearch" || true
    check_service "suricata" "Suricata IDS" || true
    check_service "grafana" "Grafana" || true

    echo ""
    echo -e "''${YELLOW}📈 Metrics:''${NC}"

    # Audit events in last hour
    AUDIT_COUNT=$(ausearch -ts recent 2>/dev/null | grep -c "^type=" || echo "0")
    echo "  📋 Audit events (last hour): $AUDIT_COUNT"

    # Suricata alerts
    if [ -f /var/log/suricata/fast.log ]; then
      ALERT_COUNT=$(tail -1000 /var/log/suricata/fast.log 2>/dev/null | wc -l || echo "0")
      echo "  🚨 IDS alerts (recent): $ALERT_COUNT"
    fi

    # Active connections
    CONN_COUNT=$(ss -tuln 2>/dev/null | wc -l || echo "0")
    echo "  🔌 Active connections: $CONN_COUNT"

    echo ""
    echo -e "''${YELLOW}💾 Storage:''${NC}"

    # Log storage usage
    if [ -d /var/log ]; then
      LOG_SIZE=$(du -sh /var/log 2>/dev/null | cut -f1 || echo "N/A")
      echo "  📁 /var/log: $LOG_SIZE"
    fi

    if [ -d /var/lib/opensearch ]; then
      OS_SIZE=$(du -sh /var/lib/opensearch 2>/dev/null | cut -f1 || echo "N/A")
      echo "  📁 OpenSearch data: $OS_SIZE"
    fi

    echo ""
    echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
  '';

  # SOC Alerts Tool
  soc-alerts = pkgs.writeShellScriptBin "soc-alerts" ''
    #!/usr/bin/env bash
    set -euo pipefail

    LIMIT=''${1:-20}

    echo "🚨 Recent Security Alerts (last $LIMIT)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Suricata alerts
    if [ -f /var/log/suricata/fast.log ]; then
      echo "📡 Suricata IDS Alerts:"
      tail -n "$LIMIT" /var/log/suricata/fast.log 2>/dev/null || echo "  No alerts found"
      echo ""
    fi

    # Audit failures
    echo "📋 Audit Failures (recent):"
    ausearch -ts recent -sv no 2>/dev/null | head -n "$LIMIT" || echo "  No failures found"
    echo ""

    # Failed logins
    echo "🔐 Failed Login Attempts:"
    journalctl -p err -t sshd --since "1 hour ago" 2>/dev/null | head -n "$LIMIT" || echo "  No failures found"
  '';

  # SOC Hunt Tool (threat hunting)
  soc-hunt = pkgs.writeShellScriptBin "soc-hunt" ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [ $# -eq 0 ]; then
      echo "🔍 SOC Threat Hunting Tool"
      echo ""
      echo "Usage: soc-hunt <command> [options]"
      echo ""
      echo "Commands:"
      echo "  ip <address>       - Hunt for IP address"
      echo "  user <username>    - Hunt for user activity"
      echo "  process <name>     - Hunt for process execution"
      echo "  file <path>        - Hunt for file access"
      echo "  network <port>     - Hunt for network connections"
      echo "  hash <sha256>      - Hunt for file hash"
      exit 0
    fi

    COMMAND=$1
    shift

    case $COMMAND in
      ip)
        IP=$1
        echo "🔍 Hunting for IP: $IP"
        echo ""
        echo "📡 Network connections:"
        ss -tuln | grep "$IP" || echo "  No active connections"
        echo ""
        echo "📋 Audit logs:"
        ausearch -a $(date +%s) -i 2>/dev/null | grep -i "$IP" | head -20 || echo "  No audit entries"
        echo ""
        echo "🔥 Firewall logs:"
        journalctl -k | grep "$IP" | tail -20 || echo "  No firewall entries"
        ;;
      user)
        USER=$1
        echo "🔍 Hunting for user: $USER"
        echo ""
        echo "📋 User audit activity:"
        ausearch -ua "$USER" 2>/dev/null | tail -50 || echo "  No audit entries"
        echo ""
        echo "🔐 Authentication logs:"
        journalctl _SYSTEMD_UNIT=sshd.service | grep "$USER" | tail -20 || echo "  No auth entries"
        ;;
      process)
        PROC=$1
        echo "🔍 Hunting for process: $PROC"
        echo ""
        echo "📋 Process executions:"
        ausearch -c "$PROC" 2>/dev/null | tail -50 || echo "  No audit entries"
        echo ""
        echo "🔄 Current instances:"
        pgrep -a "$PROC" 2>/dev/null || echo "  Not running"
        ;;
      file)
        FILE=$1
        echo "🔍 Hunting for file: $FILE"
        echo ""
        echo "📋 File access audit:"
        ausearch -f "$FILE" 2>/dev/null | tail -50 || echo "  No audit entries"
        ;;
      network)
        PORT=$1
        echo "🔍 Hunting for port: $PORT"
        echo ""
        echo "📡 Listening services:"
        ss -tlnp | grep ":$PORT" || echo "  No services on this port"
        echo ""
        echo "🔗 Active connections:"
        ss -tn | grep ":$PORT" || echo "  No active connections"
        ;;
      hash)
        HASH=$1
        echo "🔍 Hunting for hash: $HASH"
        echo ""
        echo "🔎 Searching system..."
        find /usr /opt /home -type f -exec sha256sum {} \; 2>/dev/null | grep "$HASH" || echo "  Hash not found"
        ;;
      *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
    esac
  '';

  # SOC Incident Tool
  soc-incident = pkgs.writeShellScriptBin "soc-incident" ''
    #!/usr/bin/env bash
    set -euo pipefail

    INCIDENT_DIR="/var/lib/soc/incidents"
    mkdir -p "$INCIDENT_DIR"

    if [ $# -eq 0 ]; then
      echo "🚨 SOC Incident Management"
      echo ""
      echo "Usage: soc-incident <command> [options]"
      echo ""
      echo "Commands:"
      echo "  new <title>        - Create new incident"
      echo "  list               - List open incidents"
      echo "  snapshot           - Take system snapshot"
      echo "  export <id>        - Export incident data"
      exit 0
    fi

    COMMAND=$1
    shift

    case $COMMAND in
      new)
        TITLE="$*"
        ID=$(date +%Y%m%d-%H%M%S)
        DIR="$INCIDENT_DIR/$ID"
        mkdir -p "$DIR"

        echo "🚨 Creating incident: $ID"
        echo "$TITLE" > "$DIR/title.txt"
        echo "$(date -Iseconds)" > "$DIR/created.txt"
        echo "open" > "$DIR/status.txt"

        # Auto-collect initial data
        echo "📋 Collecting initial data..."
        ps auxf > "$DIR/processes.txt" 2>/dev/null
        ss -tuln > "$DIR/network.txt" 2>/dev/null
        ausearch -ts recent > "$DIR/audit.txt" 2>/dev/null || true

        echo "✓ Incident created: $ID"
        echo "  Location: $DIR"
        ;;
      list)
        echo "📋 Open Incidents:"
        for dir in "$INCIDENT_DIR"/*/; do
          if [ -d "$dir" ]; then
            id=$(basename "$dir")
            title=$(cat "$dir/title.txt" 2>/dev/null || echo "Unknown")
            status=$(cat "$dir/status.txt" 2>/dev/null || echo "unknown")
            echo "  [$id] $title ($status)"
          fi
        done
        ;;
      snapshot)
        SNAP_ID=$(date +%Y%m%d-%H%M%S)
        SNAP_DIR="/var/lib/soc/snapshots/$SNAP_ID"
        mkdir -p "$SNAP_DIR"

        echo "📸 Taking system snapshot: $SNAP_ID"
        ps auxf > "$SNAP_DIR/processes.txt"
        ss -tuln > "$SNAP_DIR/network.txt"
        netstat -rn > "$SNAP_DIR/routes.txt" 2>/dev/null || true
        lsmod > "$SNAP_DIR/modules.txt"
        mount > "$SNAP_DIR/mounts.txt"
        ausearch -ts boot > "$SNAP_DIR/audit-boot.txt" 2>/dev/null || true

        echo "✓ Snapshot saved: $SNAP_DIR"
        ;;
      export)
        ID=$1
        DIR="$INCIDENT_DIR/$ID"
        if [ ! -d "$DIR" ]; then
          echo "Incident not found: $ID"
          exit 1
        fi

        EXPORT_FILE="/tmp/incident-$ID.tar.gz"
        tar -czf "$EXPORT_FILE" -C "$INCIDENT_DIR" "$ID"
        echo "✓ Exported to: $EXPORT_FILE"
        ;;
      *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
    esac
  '';

  # SOC Report Tool
  soc-report = pkgs.writeShellScriptBin "soc-report" ''
    #!/usr/bin/env bash
    set -euo pipefail

    REPORT_DIR="/var/lib/soc/reports"
    mkdir -p "$REPORT_DIR"

    DATE=$(date +%Y-%m-%d)
    REPORT_FILE="$REPORT_DIR/daily-$DATE.md"

    echo "📊 Generating SOC Daily Report: $DATE"
    echo ""

    cat > "$REPORT_FILE" << EOF
    # SOC Daily Report - $DATE

    Generated: $(date -Iseconds)

    ## Executive Summary

    - **System Status**: $(systemctl is-system-running 2>/dev/null || echo "degraded")
    - **Active Alerts**: $(tail -1000 /var/log/suricata/fast.log 2>/dev/null | wc -l || echo "N/A")
    - **Failed Logins**: $(journalctl -p err -t sshd --since "24 hours ago" 2>/dev/null | wc -l || echo "0")

    ## Security Events

    ### Audit Summary
    $(ausearch -ts today --summary 2>/dev/null | head -30 || echo "No audit data available")

    ### Network Alerts
    $(tail -20 /var/log/suricata/fast.log 2>/dev/null || echo "No IDS alerts")

    ### Failed Authentication
    $(journalctl -p err -t sshd --since "24 hours ago" 2>/dev/null | tail -20 || echo "None")

    ## System Health

    - **Uptime**: $(uptime -p)
    - **Load**: $(cat /proc/loadavg)
    - **Memory**: $(free -h | grep Mem | awk '{print $3 "/" $2}')
    - **Disk**: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')

    EOF

    echo "✓ Report saved: $REPORT_FILE"
    echo ""
    cat "$REPORT_FILE"
  '';

in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [
      soc-status
      soc-alerts
      soc-hunt
      soc-incident
      soc-report

      # Additional analysis tools
      pkgs.audit
      pkgs.nmap
      pkgs.tcpdump
      pkgs.jq
      pkgs.yq
    ];

    # Create SOC data directories
    systemd.tmpfiles.rules = [
      "d /var/lib/soc 0750 root root -"
      "d /var/lib/soc/incidents 0750 root root -"
      "d /var/lib/soc/snapshots 0750 root root -"
      "d /var/lib/soc/reports 0750 root root -"
    ];

    # Shell aliases for quick access (using soc- prefix to avoid conflicts)
    environment.shellAliases = {
      soc-s = "soc-status";
      soc-a = "soc-alerts";
      soc-h = "soc-hunt";
      soc-i = "soc-incident";
      soc-r = "soc-report";
    };
  };
}
