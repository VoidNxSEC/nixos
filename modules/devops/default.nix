{ ... }:

# ============================================================
# DevOps Module Aggregator
# ============================================================
# Purpose: Import all DevOps-related configurations
# Categories: GitLab CLI, CI/CD tools, infrastructure automation
# ============================================================

{
  imports = [
    # GitLab CLI tools and helpers
    ./gitlab-cli

    # Future DevOps modules can be added here:
    # ./terraform
    # ./ansible
    # ./kubernetes
  ];
}
