# Laptop Defense — laptop-verdict: automated decision framework over the
# collected evidence. Part of the flake.nix split; see ../flake.nix.
{ pkgs }:

pkgs.writeShellApplication {
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
}
