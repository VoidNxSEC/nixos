{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # The path we want to filter by.
  # Note: In a built system, declarations might point to the nix store source.
  # We'll look for "modules/" in the path string.

  # Function to convert values to JSON-safe strings
  safeVal =
    v:
    if isBool v then
      v
    else if isInt v then
      v
    else if isString v then
      v
    else if v == null then
      null
    else
      "<complex>";

  # Top-level roots to scan
  roots = [
    "kernelcore"
    "services"
    "programs"
    "security"
    "virtualization"
    "hardware"
    "network"
    "ml"
    "containers"
    "development"
  ];

  # Recursively find options
  findOptions =
    pathPrefix: optionsSet:
    concatMap (
      name:
      let
        opt = optionsSet.${name};
        fullPath = if pathPrefix == "" then name else pathPrefix + "." + name;
      in
      if isOption opt then
        # Check if declared in a "modules" directory
        if any (decl: hasInfix "/modules/" (toString decl)) (opt.declarations or [ ]) then
          let
            val = getAttrFromPath (splitString "." fullPath) config;
          in
          [
            {
              name = fullPath;
              value = safeVal val;
              isEnabled = if isBool val then val else false;
              # We don't export file paths to avoid large strings in closure
            }
          ]
        else
          [ ]
      else if isAttrs opt then
        findOptions fullPath opt
      else
        [ ]
    ) (attrNames optionsSet);

  # Collect all results
  auditData = concatMap (
    root: if hasAttr root options then findOptions root options.${root} else [ ]
  ) roots;

  # Write to JSON file in store
  auditJson = pkgs.writeText "config-audit.json" (builtins.toJSON auditData);

  # Python script to read and print the JSON

  # Using writeScriptBin to avoid strict linting from writers.writePython3Bin

  auditScript = pkgs.writeScriptBin "config-audit" ''

    #!${pkgs.python3}/bin/python3

    import json

    json_path = "${auditJson}"

    try:

        with open(json_path, 'r') as f:

            data = json.load(f)

        data.sort(key=lambda x: x['name'])

        print(f"\n📊 Found {len(data)} options defined in local modules.\n")

        print(f"{'OPTION':<60} | {'STATE':<10} | {'VALUE':<20}")

        print("-" * 96)

        for item in data:

            name = item['name']

            val = item['value']

            if val is True:

                state = "✅ ON"

            elif val is False:

                state = "❌ OFF"

            else:

                state = "⚙️  CONF"

            val_str = str(val)

            if len(val_str) > 20:

                val_str = val_str[:17] + "..."

            print(f"{name:<60} | {state:<10} | {val_str:<20}")

    except Exception as e:

        print(f"Error: {e}")

  '';

in
{
  options.services.config-auditor = {
    enable = mkEnableOption "Configuration Auditor Tool";
  };

  config = mkIf config.services.config-auditor.enable {
    environment.systemPackages = [ auditScript ];
  };
}
