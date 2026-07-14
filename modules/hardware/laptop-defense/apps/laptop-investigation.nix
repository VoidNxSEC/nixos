# Laptop Defense — laptop-investigation: all-in-one evidence collector that
# chains the other tools. Part of the flake.nix split; see ../flake.nix.
{
  pkgs,
  thermalForensics,
  mcpLogExtractor,
  decisionFramework,
}:

pkgs.writeShellApplication {
  name = "laptop-investigation";
  runtimeInputs = [
    thermalForensics
    mcpLogExtractor
    decisionFramework
  ];

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
}
