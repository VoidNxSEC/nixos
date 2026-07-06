# GitHub Actions Self-Hosted Runner - Implementation Summary

## What Was Done

### 1. Updated GitHub Actions Workflow (`.github/workflows/nixos-build.yml`)
- ✅ Changed from `ubuntu-latest` to `runs-on: [self-hosted, nixos]`
- ✅ Added multiple test pipelines:
  - **check**: Flake validation and metadata checks
  - **build**: Builds toplevel, ISO, and VM images (parallel matrix)
  - **test-modules**: Tests dev shells, Docker images, systemd services
  - **security**: Vulnerability scanning, secret detection
  - **format**: Nix code formatting checks
  - **deploy**: Automatic deployment to NixOS (manual trigger)
  - **report**: Build summary generation
- ✅ Added `workflow_dispatch` for manual deployments
- ✅ Added artifact upload for ISO and VM images

### 2. Migrated to SOPS Secret Management
- ✅ Created `.sops.yaml` with age encryption configuration
- ✅ Configured encryption rules for all secret files
- ✅ Using existing age key: `age1h0m5uwsjq9twc0rvpm3nv2uqtwarxpq6mq5uqxsxwu6tgzgwcagqw3d0xn`

### 3. Refactored `actions.nix` Module
**New features:**
- ✅ Modular configuration with options
- ✅ SOPS integration for secure token management
- ✅ Automatic runner download and setup
- ✅ Configurable runner name, labels, and repository URL
- ✅ Proper systemd service with restart logic
- ✅ Security: runs as unprivileged `actions` user
- ✅ Error handling and validation

**Configuration options:**
```nix
kernelcore.services.github-runner = {
  enable = true;
  useSops = true;  # SOPS secret management
  runnerName = "nixos-self-hosted";
  repoUrl = "https://github.com/VoidNxSEC/nixos";
  extraLabels = [ "nixos" "nix" "gpu" ];
};
```

### 4. Security Improvements
- ❌ **Removed hardcoded token** from `actions.nix`
- ✅ Token now stored encrypted in `secrets/github.yaml` (SOPS)
- ✅ Secrets accessible only to `actions` user (mode 0400)
- ✅ Secrets stored in tmpfs (`/run/secrets`) - never on disk
- ✅ Added secret scanning to CI pipeline
- ✅ Service runs as unprivileged user

### 5. Documentation
- ✅ Created comprehensive `GITHUB_ACTIONS_SETUP.md` guide
- ✅ Step-by-step instructions for:
  - Generating runner token
  - Encrypting with SOPS
  - Enabling the module
  - Building and deploying
  - Troubleshooting

## File Changes

### Modified Files
1. `/etc/nixos/.github/workflows/nixos-build.yml` - Complete rewrite for self-hosted
2. `/etc/nixos/modules/services/users/actions.nix` - Refactored with SOPS support

### New Files
1. `/etc/nixos/.sops.yaml` - SOPS encryption configuration
2. `/etc/nixos/GITHUB_ACTIONS_SETUP.md` - Setup guide
3. `/etc/nixos/SUMMARY.md` - This file

## Next Steps (For You)

### Step 1: Get GitHub Runner Token
```bash
# Open this URL in browser:
https://github.com/VoidNxSEC/nixos/settings/actions/runners/new

# Copy the token (expires in 1 hour!)
```

### Step 2: Encrypt Token with SOPS
```bash
# Create secret file
cat > /tmp/github-runner.yaml << EOF
github:
  runner:
    token: "PASTE_YOUR_TOKEN_HERE"
