import json
import subprocess
import os
import sys
from datetime import datetime

def run_nix_eval():
    print("⏳ Evaluating NixOS configuration using 'nixos-rebuild dry-run --json' (this may take a moment)")
    
    try:
        # Use nixos-rebuild dry-run --json to get a comprehensive view of the config
        # This command runs with proper privileges and context to access all options
        cmd = ["sudo", "nixos-rebuild", "dry-run", "--flake", "/etc/nixos#kernelcore", "--json"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # The output of dry-run --json is a list of events. We need the evaluation result.
        # Find the event that contains the configuration data.
        events = json.loads(result.stdout)
        
        config_data = None
        for event in events:
            if event.get("action") == "evaluate" and "result" in event:
                config_data = event["result"]
                break
        
        if not config_data:
            raise ValueError("Could not find configuration evaluation result in dry-run --json output.")

        # From the config_data, we need to extract options relevant to our local flake
        # This requires another Nix evaluation to filter these options, as dry-run --json itself
        # doesn't filter by declaration location easily.
        # So, we still need a nix expression to get the options and filter by local declarations.
        # The 'dry-run --json' primarily tells us if the configuration can be built and gives an eval path,
        # but not the filtered option details.
        
        # We need the full option list from a specific configuration to then filter.
        # Let's use `nix-instantiate` or `nix eval` on the options directly from the flake.
        # The previous issue was that `nix eval` was restricted.
        # But `nixos-rebuild dry-run` might grant more context.
        
        # New approach: dry-run gives us `nixosConfigurations."kernelcore".options` as a result path.
        # We can then `nix eval` that path.
        
        # THIS IS MORE COMPLEX THAN I THOUGHT. `nixos-rebuild dry-run --json` output contains 
        # a lot of info but not a direct JSON representation of the *options* filtered by path.
        # It's better to stick to the original Nix expression but solve the PATH issue.
        
        # Reverting to previous strategy, but with absolute path handling.
        # The problem is `nix eval --impure` blocking `/etc` access.
        
        # Let's try to get the full path to the current directory safely.
        # os.getcwd() will return /etc/nixos.
        # The error is that `nix eval` itself, when run from /etc/nixos, treats it as restricted.
        # This implies it's not the `toString ./.` but the *context* it's running in.
        
        # The solution for "access to absolute path '/etc' is forbidden in restricted mode"
        # when evaluating flake inputs is typically to use `builtins.getFlake "git+file:///etc/nixos"`
        # or similar, ensuring it's treated as a flake URI, not a bare path.
        
        # I will modify the generate_nix_expr to use "git+file://" for the flake path.
        raise NotImplementedError("Reverting dry-run approach, fixing flake path in generate_nix_expr.")

    except subprocess.CalledProcessError as e:
        print(f"❌ Error during Nix evaluation:\n{e.stderr}")
        sys.exit(1)
    except ValueError as e:
        print(f"❌ Error processing Nix output: {e}")
        sys.exit(1)

def generate_nix_expr():

    # Use "git+file:///..." to explicitly treat it as a flake input from a git repo.

    # This should bypass the "/etc" restriction if the directory is indeed a git repo.

    current_dir = os.getcwd() # Should be /etc/nixos

    flake_uri = f"git+file://{current_dir}"



    return f"""

let

  flake = builtins.getFlake "{flake_uri}";

  host = "kernelcore";

  sys = flake.nixosConfigurations.${{host}};

  pkgs = sys.pkgs;

  lib = pkgs.lib;

  

  rootDir = "{current_dir}"; # The root directory of the repository

  

  # Helper to safely convert values to strings for JSON

  safeStr = v: 

    if builtins.isBool v then (if v then "true" else "false")

    else if builtins.isInt v then builtins.toString v

    else if builtins.isString v then v

    else if v == null then "null"

    else "<complex>";



  # Define common top-level paths that user-defined options usually reside under

  # We will directly query these paths for options

  commonOptionPaths = [

    "kernelcore"

    "services"

    "programs"

    "users"

    "security"

    "hardware"

    "boot"

    "networking"

    "environment"

  ];



  # Function to get all options and their values from a given path prefix

  # This avoids the deep recursion on the whole options tree.

  getOptionsFromPath = pathPrefix:

    let

      # Get the options subtree for the pathPrefix

      optionsSubtree = lib.getAttrFromPath (lib.splitString "." pathPrefix) sys.options;

      configSubtree = lib.getAttrFromPath (lib.splitString "." pathPrefix) sys.config;



      # Recursively flatten the subtree into a list of option definitions

      flatten = name: value:

        if lib.isAttrs value && value ? _type && value._type == "option" then

          [ {{

              inherit name;

              description = value.description or "No description provided.";

              value = safeStr (lib.getAttrFromPath (lib.splitString "." name) configSubtree);

              declarations = value.declarations or [];

              isEnable = (lib.hasSuffix "enable" name) || (lib.hasSuffix "Enable" name);

            }} ]

        else if lib.isAttrs value then

          lib.concatMapAttrs (subName: subValue: flatten (name + "." + subName) subValue) value

        else

          [];

    in

      lib.concatMapAttrs (subName: subValue: flatten subName subValue) optionsSubtree;



  # Collect options from all common paths

  allCollectedOptions = lib.concatMap (path: getOptionsFromPath path) commonOptionPaths;



  # Filter: Keep options where at least one declaration file starts with our rootDir

  localOptions = builtins.filter (opt: 

    builtins.any (decl: lib.hasPrefix rootDir (builtins.toString decl)) (opt.declarations or [])

  ) allCollectedOptions;



in

  localOptions

"""



def run_nix_eval_with_flake_uri():

    print("⏳ Evaluating NixOS configuration with flake URI (this may take a moment)")

    nix_expr = generate_nix_expr()

    

    # Write temp file to avoid quoting hell in CLI

    with open("temp_audit_eval.nix", "w") as f:

        f.write(nix_expr)

        

    try:

        cmd = [

            "nix", "--extra-experimental-features", "nix-command flakes",

            "eval", "--json", "--impure", "--file", "temp_audit_eval.nix"

        ]

        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        return json.loads(result.stdout)

    except subprocess.CalledProcessError as e:

        print(f"❌ Error during Nix evaluation:\n{e.stderr}")

        print("💡 Hint: Ensure '/etc/nixos' is a clean git repository or add `--override-input nixpkgs path:/path/to/nixpkgs` if you're using a local nixpkgs source.")

        sys.exit(1)

    finally:

        if os.path.exists("temp_audit_eval.nix"):

            os.remove("temp_audit_eval.nix")

def generate_markdown(options):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    enabled = []
    disabled = []
    configured = []
    
    for opt in options:
        val = opt['value']
        if opt['isEnable']:
            if val == "true":
                enabled.append(opt)
            else:
                disabled.append(opt)
        else:
            configured.append(opt)
            
    enabled.sort(key=lambda x: x['name'])
    disabled.sort(key=lambda x: x['name'])
    configured.sort(key=lambda x: x['name'])
    
    md = f"# 🛡️ NixOS Configuration Audit Report\n\n"
    md += f"**Date:** {now}\n"
    md += f"**Repository:** {os.getcwd()}\n"
    md += f"**Total Local Options:** {len(options)}\n\n"
    
    md += "---\n\n"
    
    md += "## 📊 Executive Summary\n\n"
    md += f"- **🟢 Enabled Features:** {len(enabled)}\n"
    md += f"- **🔴 Disabled Features:** {len(disabled)}\n"
    md += f"- **⚙️  Configured Settings:** {len(configured)}\n\n"
    
    md += "---\n\n"
    
    md += "## 🟢 Active Capabilities (Enabled)\n\n"
    md += "| Option | Description | Value |\n"
    md += "| :--- | :--- | :---: |\n"
    for opt in enabled:
        desc = opt['description'].split('\n')[0].strip()
        if len(desc) > 80: desc = desc[:77] + "..."
        md += f"| `{opt['name']}` | {desc} | **true** |\n"
    md += "\n"
    
    md += "## 🔴 Inactive Capabilities (Disabled)\n\n"
    md += "> These modules are present in the codebase but currently turned off or set to a disabling value.\n\n"
    md += "| Option | Description | Value |\n"
    md += "| :--- | :--- | :---: |\n"
    for opt in disabled:
        desc = opt['description'].split('\n')[0].strip()
        if len(desc) > 80: desc = desc[:77] + "..."
        val_display = opt['value']
        if val_display == "false": val_display = "**false**"
        else: val_display = f"`{val_display}`"
        md += f"| `{opt['name']}` | {desc} | {val_display} |\n"
    md += "\n"
    
    md += "## ⚙️  Detailed Configuration\n\n"
    md += "| Option | Value | Description |\n"
    md += "| :--- | :--- | :--- |\n"
    for opt in configured:
        desc = opt['description'].split('\n')[0].strip()
        if len(desc) > 80: desc = desc[:77] + "..."
        val = opt['value']
        if len(val) > 50: val = val[:47] + "..."
        md += f"| `{opt['name']}` | `{val}` | {desc} |\n"
    
    return md

def main():
    options = run_nix_eval_with_flake_uri()
    report = generate_markdown(options)
    
    filename = f"reports/audit_report_{datetime.now().strftime('%Y%m%d')}.md"
    os.makedirs("reports", exist_ok=True)
    
    with open(filename, "w") as f:
        f.write(report)
        
    print(f"\n✅ Audit complete!")
    print(f"📄 Report generated: {filename}")
    print(f"📊 Stats: {len(options)} options analyzed.")

if __name__ == "__main__":
    main()
