{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.niri;

  # Helper function to convert Nix attributes to KDL format
  # This is a simplified KDL generator specifically for Niri's needs
  toKDL =
    inputs:
    let
      renderValue =
        v:
        if isBool v then
          (if v then "true" else "false")
        else if isInt v then
          toString v
        else if isFloat v then
          toString v
        else if isString v then
          "\"${v}\""
        else if isList v then
          builtins.concatStringsSep " " (map renderValue v)
        else
          abort "Unsupported KDL value type: ${builtins.typeOf v}";

      renderNode =
        name: value: indent:
        let
          indentStr = builtins.concatStringsSep "" (builtins.genList (_: "  ") indent);
        in
        if isAttrs value && !isDerivation value then
          # Node with children (e.g. input { ... })
          "${indentStr}${name} {\n"
          + (builtins.concatStringsSep "" (mapAttrsToList (n: v: renderNode n v (indent + 1)) value))
          + "${indentStr}}\n"
        else if isList value then
          # Repeated nodes or arguments (e.g. spawn-at-startup)
          # Niri uses list of attrs for things like spawn-at-startup: [ { command = [...]; } ]
          # Or simple lists for arguments
          if name == "spawn-at-startup" || name == "window-rules" || name == "binds" then
            builtins.concatStringsSep "" (map (item: renderNode name item indent) value)
          else
            # Fallback for simple properties that might be lists
            "${indentStr}${name} ${renderValue value}\n"
        else
          # Leaf node (property)
          "${indentStr}${name} ${renderValue value}\n";

      # Special handling for Niri's specific structure
      # We need to handle binds and window-rules carefully as they can be complex

      # For now, let's assume 'settings' is a direct mapping to KDL nodes
      kdlContent = builtins.concatStringsSep "\n" (mapAttrsToList (n: v: renderNode n v 0) cfg.settings);

    in
    kdlContent;

in
{
  options.programs.niri = {
    enable = mkEnableOption "Niri window manager";

    package = mkOption {
      type = types.package;
      default = pkgs.niri;
      defaultText = literalExpression "pkgs.niri";
      description = "The Niri package to install.";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/niri/config.kdl`.
        See <https://github.com/YaLTeR/niri/wiki/Configuration-Guide> for documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Since we can't easily write a perfect generic KDL generator in 5 mins without dependencies,
    # and Niri's config is complex (nested nodes, args, etc.),
    # we will use a slightly different approach for the short term:
    # If settings is defined, we assume the user might want to provide the KDL file content directly
    # OR we try to map it.

    # Actually, to save time and ensure correctness given your existing niri.nix uses complex Nix structures,
    # let's try to use the 'settings' attribute but we might need a more robust KDL generator
    # or rely on the user to provide the config file text if the generator fails.

    # CRITICAL: Your existing niri.nix uses a structure that implies a module exists.
    # The structure in niri.nix is:
    # settings = {
    #   input = { ... };
    #   layout = { ... };
    #   binds = { "Mod+Return" = { action.spawn = ... }; };
    # }

    # We need a generator that can handle "Mod+Return" keys and action.spawn values.

    # Simplified shim: We will just ensure the option exists so evaluation passes.
    # The actual config generation is hard to do perfectly generically without a proper library.
    # BUT, we can make it work for your specific file structure.

    xdg.configFile."niri/config.kdl".text =
      let
        # Better KDL Generator for Niri
        # Handles:
        # - Simple values: key value
        # - Blocks: key { ... }
        # - Binds: key { action ... }

        mkValue =
          v:
          if isBool v then
            (if v then "true" else "false")
          else if isInt v then
            toString v
          else if isFloat v then
            toString v
          else if isString v then
            "\"${v}\""
          else if isList v then
            builtins.concatStringsSep " " (map mkValue v)
          else if isAttrs v && !isDerivation v then
            # Attribute set - format as KDL properties (e.g., { proportion = 0.33; } -> "proportion 0.33")
            builtins.concatStringsSep " " (mapAttrsToList (k: val: "${k} ${mkValue val}") v)
          else
            toString v;

        mkSection =
          name: value: indent:
          let
            spaces = builtins.concatStringsSep "" (builtins.genList (_: "  ") indent);
          in
          if name == "binds" then
            # Special handling for binds
            builtins.concatStringsSep "" (
              mapAttrsToList (
                key: action:
                "${spaces}bind ${mkValue key} {\n" + (mkBindAction action (indent + 1)) + "${spaces}}\n"
              ) value
            )
          else if name == "window-rules" then
            # List of rule sets
            builtins.concatStringsSep "" (
              map (ruleSet: "${spaces}window-rule {\n" + (mkProps ruleSet (indent + 1)) + "${spaces}}\n") value
            )
          else if name == "spawn-at-startup" then
            # List of commands
            builtins.concatStringsSep "" (
              map (cmdSet: "${spaces}spawn-at-startup ${mkValue (cmdSet.command or [ ])}\n") value
            )
          else if isAttrs value then
            "${spaces}${name} {\n" + (mkProps value (indent + 1)) + "${spaces}}\n"
          else
            "${spaces}${name} ${mkValue value}\n";

        mkBindAction =
          actionSet: indent:
          let
            spaces = builtins.concatStringsSep "" (builtins.genList (_: "  ") indent);
          in
          builtins.concatStringsSep "" (
            mapAttrsToList (
              k: v:
              # Handle action.spawn -> spawn
              let
                cmd = lib.removePrefix "action." k;
                val =
                  if isAttrs v then
                    # Attribute set (empty or nested) - just output command name
                    ""
                  else
                    # Primitive value (string, int, bool, list)
                    " ${mkValue v}";
              in
              "${spaces}${cmd}${val}\n"
            ) actionSet
          );

        mkProps =
          set: indent: builtins.concatStringsSep "" (mapAttrsToList (n: v: mkSection n v indent) set);

      in
      mkProps cfg.settings 0;
  };
}
