#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3

import json
import subprocess
import os
import sys

def generate_nix_expr(repo_root):
    # Use path: to bypass restricted mode for local flakes
    flake_uri = "path:" + repo_root
    modules_path = repo_root + "/modules"
    
    # Constructing the Nix expression in parts to avoid Python string parsing issues
    parts = []
    
    parts.append("let")
    parts.append(f'  flake = builtins.getFlake "{flake_uri}";')
    parts.append("  sys = flake.nixosConfigurations.kernelcore;")
    parts.append("  lib = sys.pkgs.lib;")
    parts.append(f'  modulesPath = "{modules_path}";')
    
    parts.append('  safeVal = v: if builtins.isBool v then v else if builtins.isInt v then v else if builtins.isString v then v else if v == null then null else "<complex>";')

    parts.append('  findOptions = pathPrefix: optionsSet:')
    parts.append('    let attrs = builtins.attrNames optionsSet;')
    parts.append('    in lib.concatMap (name:')
    parts.append('      let opt = optionsSet.${name};')
    parts.append('          fullPath = if pathPrefix == "" then name else pathPrefix + "." + name;')
    parts.append('      in if lib.isOption opt then')
    parts.append('           if builtins.any (decl: lib.hasPrefix modulesPath (toString decl)) (opt.declarations or []) then')
    parts.append('             let val = lib.getAttrFromPath (lib.splitString "." fullPath) sys.config;')
    parts.append('             in [{ name = fullPath; value = safeVal val; isEnabled = if builtins.isBool val then val else false; files = map toString opt.declarations; }]')
    parts.append('           else []')
    parts.append('         else if lib.isAttrs opt then findOptions fullPath opt else []')
    parts.append('    ) attrs;')

    parts.append('  roots = [ "kernelcore" "services" "programs" "security" "virtualization" "hardware" "network" "ml" "containers" "development" ];')
    
    parts.append('  results = lib.concatMap (root: if builtins.hasAttr root sys.options then findOptions root sys.options.${root} else []) roots;')
    
    parts.append('in results')

    return "\n".join(parts)

def main():
    repo_root = os.getcwd()
    nix_expr = generate_nix_expr(repo_root)
    temp_file = "temp_check_options.nix"

    print(f"🔍 Scanning modules in {repo_root}/modules...")
    print("⏳ Evaluating Nix configuration (this might take 10-20 seconds)...")

    with open(temp_file, "w") as f:
        f.write(nix_expr)

    try:
        # Run nix eval
        cmd = [
            "nix", 
            "--extra-experimental-features", "nix-command flakes",
            "eval", 
            "--json", 
            "--impure", 
            "--file", temp_file
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        
        # Sort by name
        data.sort(key=lambda x: x['name'])

        print(f"\n📊 Found {len(data)} options defined in local modules.\n")
        
        # Print Table Header
        print(f"{ 'OPTION':<60} | { 'STATE':<10} | { 'VALUE':<20}")
        print("-" * 96)
        
        for item in data:
            name = item['name']
            val = item['value']
            
            # Format State
            if val is True:
                state = "✅ ON"
            elif val is False:
                state = "❌ OFF"
            else:
                state = "⚙️  CONF"
            
            # Truncate value string
            val_str = str(val)
            if len(val_str) > 20:
                val_str = val_str[:17] + "..."

            print(f"{name:<60} | {state:<10} | {val_str:<20}")

        # Save JSON output
        json_path = "reports/module_options_state.json"
        os.makedirs("reports", exist_ok=True)
        with open(json_path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"\n💾 Full JSON report saved to: {json_path}")

    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error evaluating Nix expression:\n{e.stderr}")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)

if __name__ == "__main__":
    main()