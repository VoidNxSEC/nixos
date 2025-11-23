{
  config,
  lib,
  pkgs,
  ...
}:

# ============================================================
# MCP SERVER INTEGRATION - Laptop Defense Tools
# ============================================================
# Adiciona ferramentas de thermal forensics ao MCP server

with lib;

{
  options.services.mcp.laptopDefense = {
    enable = mkEnableOption "MCP Laptop Defense tools integration";
  };

  config = mkIf config.services.mcp.laptopDefense.enable {

    # Extend MCP server com novas tools
    environment.etc."mcp/tools/laptop-defense.json" = {
      text = builtins.toJSON {
        tools = [
          {
            name = "thermal_forensics";
            description = "Run complete thermal forensics analysis";
            inputSchema = {
              type = "object";
              properties = {
                duration = {
                  type = "integer";
                  description = "Test duration in seconds (default: 180)";
                  default = 180;
                };
              };
            };
            command = "${pkgs.bash}/bin/bash";
            args = [ "-c" "nix run /etc/nixos/modules/hardware/laptop-defense#thermal-forensics" ];
          }

          {
            name = "thermal_warroom";
            description = "Real-time thermal monitoring war room";
            inputSchema = {
              type = "object";
              properties = {};
            };
            command = "${pkgs.bash}/bin/bash";
            args = [ "-c" "nix run /etc/nixos/modules/hardware/laptop-defense#thermal-warroom" ];
          }

          {
            name = "thermal_check";
            description = "Quick thermal check before operation";
            inputSchema = {
              type = "object";
              properties = {
                max_temp = {
                  type = "integer";
                  description = "Maximum acceptable temperature (°C)";
                  default = 75;
                };
              };
            };
            command = "${pkgs.writeShellScript "thermal-check" ''
              MAX_ACCEPTABLE="''${1:-75}"
              CURRENT=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")

              echo "{\"current_temp\": $CURRENT, \"max_acceptable\": $MAX_ACCEPTABLE, \"safe\": $([ $CURRENT -le $MAX_ACCEPTABLE ] && echo true || echo false)}"

              if [ "$CURRENT" -le "$MAX_ACCEPTABLE" ]; then
                exit 0
              else
                exit 1
              fi
            ''}";
            args = [];
          }

          {
            name = "laptop_verdict";
            description = "Generate laptop replacement verdict from evidence";
            inputSchema = {
              type = "object";
              properties = {
                evidence_dir = {
                  type = "string";
                  description = "Path to evidence directory";
                };
              };
              required = [ "evidence_dir" ];
            };
            command = "${pkgs.bash}/bin/bash";
            args = [ "-c" "nix run /etc/nixos/modules/hardware/laptop-defense#verdict -- $1" ];
          }

          {
            name = "mcp_knowledge_extract";
            description = "Extract MCP knowledge related to thermal/rebuild issues";
            inputSchema = {
              type = "object";
              properties = {
                days_back = {
                  type = "integer";
                  description = "Days to look back (default: 7)";
                  default = 7;
                };
              };
            };
            command = "${pkgs.bash}/bin/bash";
            args = [ "-c" "nix run /etc/nixos/modules/hardware/laptop-defense#mcp-extract" ];
          }

          {
            name = "rebuild_safety_check";
            description = "Pre-rebuild safety check (thermal + resources)";
            inputSchema = {
              type = "object";
              properties = {};
            };
            command = "${pkgs.writeShellScript "rebuild-safety-check" ''
              set -e

              RESULT="{"

              # Thermal check
              TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | grep -oP '\+\K[0-9]+' | sort -rn | head -1 || echo "0")
              RESULT="$RESULT\"thermal_temp\": $TEMP, \"thermal_safe\": $([ $TEMP -le 75 ] && echo true || echo false),"

              # Memory check
              MEM_AVAIL=$(free -m | grep Mem | awk '{print $7}')
              RESULT="$RESULT\"memory_available_mb\": $MEM_AVAIL, \"memory_safe\": $([ $MEM_AVAIL -ge 2000 ] && echo true || echo false),"

              # Load check
              LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs | cut -d'.' -f1)
              RESULT="$RESULT\"load_average\": $LOAD, \"load_safe\": $([ $LOAD -le 10 ] && echo true || echo false),"

              # Overall verdict
              if [ $TEMP -le 75 ] && [ $MEM_AVAIL -ge 2000 ] && [ $LOAD -le 10 ]; then
                RESULT="$RESULT\"verdict\": \"SAFE\""
              else
                RESULT="$RESULT\"verdict\": \"UNSAFE\""
              fi

              RESULT="$RESULT}"

              echo "$RESULT"

              # Exit code based on verdict
              [ $TEMP -le 75 ] && [ $MEM_AVAIL -ge 2000 ] && [ $LOAD -le 10 ]
            ''}";
            args = [];
          }
        ];
      };
    };

    # Wrapper scripts para MCP
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "mcp-thermal-check" ''
        ${pkgs.curl}/bin/curl -X POST http://localhost:3000/tools/thermal_check \
          -H "Content-Type: application/json" \
          -d '{"max_temp": ''${1:-75}}'
      '')

      (pkgs.writeShellScriptBin "mcp-rebuild-check" ''
        ${pkgs.curl}/bin/curl -X POST http://localhost:3000/tools/rebuild_safety_check \
          -H "Content-Type: application/json"
      '')
    ];
  };
}
