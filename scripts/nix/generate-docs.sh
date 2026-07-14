#!/usr/bin/env bash
# Simple Documentation Generator for NixOS Modules

DOC_FILE="docs/MODULES_INDEX.md"

echo "# NixOS Module Index" > "$DOC_FILE"
echo "Auto-generated on $(date)" >> "$DOC_FILE"
echo "" >> "$DOC_FILE"

echo "## Modules List" >> "$DOC_FILE"

find modules -name "*.nix" | sort | while read -r module; do
    # Check if file has options (heuristic)
    if grep -q "options =" "$module" || grep -q "mkOption" "$module"; then
        echo "Processing $module..."
        echo "### $(basename "$module" .nix)" >> "$DOC_FILE"
        echo "- **Path**: \`$module\`" >> "$DOC_FILE"
        
        # Extract description lines (hacky but works for standard structure)
        desc=$(grep -A 1 "description =" "$module" | head -n 2 | tail -n 1 | sed 's/[\";]//g' | sed 's/^[ \t]*//')
        if [ ! -z "$desc" ]; then
             echo "- **Description**: $desc" >> "$DOC_FILE"
        fi
        echo "" >> "$DOC_FILE"
    fi
done

echo "Documentation generated at $DOC_FILE"
