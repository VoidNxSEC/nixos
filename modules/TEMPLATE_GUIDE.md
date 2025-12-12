# Nix Module Template Usage Guide

This guide explains how to use the `TEMPLATE.nix` file to create new modules for your NixOS configuration.

## 1. Creating a New Module

1.  **Copy the template**:
    ```bash
    cp modules/TEMPLATE.nix modules/your-category/your-module.nix
    ```

2.  **Update the Header**:
    Edit the top comments to reflect the new module's purpose and maintainer.

3.  **Define the Namespace**:
    Update the `cfg` variable and `options` path.
    *   Example: Change `category.module-name` to `programs.my-app` or `services.custom-daemon`.

## 2. Defining Options

Use `lib.mkOption` to define user-configurable settings.

### Common Types (`lib.types`)
*   `types.bool`: Boolean (true/false)
*   `types.str`: String
*   `types.int`: Integer
*   `types.path`: File system path
*   `types.package`: Nix package
*   `types.listOf types.str`: List of strings
*   `types.enum [ "one" "two" ]`: Enumerated list

### Example
```nix
options.programs.my-app = {
  enable = mkEnableOption "My App";
  
  theme = mkOption {
    type = types.enum [ "light" "dark" ];
    default = "dark";
    description = "Theme selection";
  };
};
```

## 3. Implementation (`config`)

The `config` block defines what happens when the module is enabled.

### Common Implementation Patterns

*   **Installing Packages**:
    ```nix
    environment.systemPackages = [ pkgs.my-app ];
    ```

*   **Configuration Files**:
    ```nix
    environment.etc."myapp/config.toml".text = ''
      theme = "${cfg.theme}"
    '';
    ```

*   **Systemd Services**:
    ```nix
    systemd.services.my-app = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.my-app}/bin/my-app";
    };
    ```

## 4. Importing the Module

Add your new module to the `imports` list in the `default.nix` of its category or directly in `configuration.nix`.

**Example (`modules/your-category/default.nix`):**
```nix
{
  imports = [
    ./your-module.nix
  ];
}
```

## 5. Testing

To verify your module without applying changes:

1.  **Check Syntax**:
    ```bash
    nix-instantiate --parse modules/your-category/your-module.nix
    ```

2.  **Dry Run Build**:
    ```bash
    nixos-rebuild build --dry-run
    ```

3.  **Check Options**:
    You can inspect your new options in the NixOS REPL:
    ```bash
    nix repl '<nixpkgs/nixos>'
    > config.programs.my-app.enable
    ```
