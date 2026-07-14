#!/usr/bin/env bash

# Define search directories relative to the repository root
SEARCH_DIRS="flake.nix modules hosts"

if ! command -v rg &> /dev/null; then
  echo "Error: 'rg' (ripgrep) is required."
  exit 1
fi

mkdir -p reports
OUTPUT_FILE="reports/config_summary.md"

# --- Report Generation ---
{
echo "# NixOS Configuration Summary"
echo ""
echo "Generated on: $(date)"
echo "Repository: $(pwd)"
echo ""

echo "## 🟢 Enabled Features"
echo "| File | Feature | State |"
echo "| :--- | :--- | :--- |"

# Search for 'enable = true;'
rg --type nix --no-heading --line-number '([a-zA-Z0-9_.]+\.)?enable\s*=\s*true;' ${SEARCH_DIRS} \
| awk -F':' '{ 
    file=$1;
    gsub("hosts/kernelcore/", "", file);
    gsub("modules/", "", file);
    
    line=$3;
    gsub(/^[ \t]+/, "", line); # Trim leading whitespace
    gsub(/;$/, "", line);      # Remove trailing semicolon
    
    print "| " file " | `" line "` | ✅ Enabled |"
}' | sort

echo ""
echo "## 🔴 Disabled Features"
echo "| File | Feature | State |"
echo "| :--- | :--- | :--- |"

# Search for 'enable = false;'
rg --type nix --no-heading --line-number '([a-zA-Z0-9_.]+\.)?enable\s*=\s*false;' ${SEARCH_DIRS} \
| awk -F':' '{ 
    file=$1;
    gsub("hosts/kernelcore/", "", file);
    gsub("modules/", "", file);
    
    line=$3;
    gsub(/^[ \t]+/, "", line);
    gsub(/;$/, "", line);
    
    print "| " file " | `" line "` | ❌ Disabled |"
}' | sort

echo ""
echo "## 📦 Key Packages & Services"
echo "| File | Service/Package |"
echo "| :--- | :--- |"

# Search for top-level service definitions
rg --type nix --no-heading --line-number '^\s*(services|programs|security|virtualisation)\.[a-zA-Z0-9_-]+\s*=\s*\{' ${SEARCH_DIRS} \
| awk -F':' '{ 
    file=$1;
    gsub("hosts/kernelcore/", "", file);
    gsub("modules/", "", file);
    
    line=$3;
    gsub(/^[ \t]+/, "", line);
    gsub(/\s*=\s*\{$/, "", line); # Remove " = {"
    
    print "| " file " | `" line "` |"
}' | sort

} > "$OUTPUT_FILE"

echo "✅ Clean summary generated: $OUTPUT_FILE"
