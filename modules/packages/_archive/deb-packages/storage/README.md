# .deb Package Storage

This directory is configured for Git LFS to store `.deb` package files efficiently.

## Setup Git LFS

### First-time setup

```bash
# Install git-lfs (NixOS)
nix-shell -p git-lfs

# Initialize git-lfs in the repository
cd /etc/nixos
git lfs install

# Track .deb files (already configured in .gitattributes)
git lfs track "*.deb"
```

### Verify Git LFS is working

```bash
# Check LFS status
git lfs status

# List tracked files
git lfs ls-files
```

## Adding .deb Files

### Option 1: Manual

```bash
# Copy your .deb file
cp /path/to/package.deb /etc/nixos/modules/packages/deb-packages/storage/

# Get SHA256 hash
nix-prefetch-url file://$(pwd)/storage/package.deb

# Add to git
git add storage/package.deb

# Commit
git commit -m "Add package.deb"

# Git LFS will automatically handle the large file
```

### Option 2: Using deb-add script

```bash
# The script will handle everything
deb-add --name my-package \
        --deb /path/to/package.deb \
        --storage git-lfs
```

## Configuration

### Reference stored files in package configs

```nix
{
  my-package = {
    enable = true;
    method = "auto";

    source = {
      # Use relative path from package configuration
      path = ../storage/my-package.deb;
      sha256 = "sha256-HASH-HERE";
    };

    # ... rest of configuration
  };
}
```

## Storage Layout

```
storage/
├── .gitattributes       # Git LFS configuration
├── README.md            # This file
├── package-name.deb     # Your .deb files (tracked with LFS)
└── package-name-v2.deb  # Multiple versions if needed
```

## Best Practices

### 1. Naming Convention

Use descriptive names with version numbers:
```
tool-name_1.0.0_amd64.deb
app-name_2.3.1_amd64.deb
```

### 2. Version Management

Keep multiple versions if needed:
```
my-tool_1.0.0_amd64.deb
my-tool_1.1.0_amd64.deb
my-tool_2.0.0_amd64.deb
```

Update package configurations to point to the desired version.

### 3. Security

Always verify checksums:
```bash
# Generate SHA256
sha256sum storage/package.deb

# Or using nix-prefetch-url
nix-prefetch-url file://$(pwd)/storage/package.deb
```

### 4. Repository Size

Git LFS stores actual files on the LFS server, keeping your repository clone lightweight.

```bash
# Check repository size
du -sh .git

# Check LFS storage
git lfs ls-files --size
```

## When to Use Git LFS vs URLs

### Use Git LFS for:
- ✅ Internal/proprietary packages
- ✅ Packages not available via public URLs
- ✅ Packages requiring version control
- ✅ Critical dependencies you want to preserve

### Use URLs for:
- ✅ Public packages with stable URLs
- ✅ Packages from official repositories
- ✅ Large packages to keep repo smaller
- ✅ Frequently updated packages

## Troubleshooting

### LFS files not downloading

```bash
# Fetch LFS files
git lfs fetch
git lfs pull
```

### Check LFS file status

```bash
# Verify file is tracked by LFS
git lfs ls-files

# Check file is stored correctly
file storage/package.deb
# Should show: "Debian binary package"
```

### Migrate existing files to LFS

```bash
# If you added .deb files before setting up LFS
git lfs migrate import --include="*.deb"
```

## Security Considerations

1. **Checksum verification**: Always verify SHA256 before use
2. **Source tracking**: Document where packages came from
3. **License compliance**: Ensure you can redistribute stored packages
4. **Access control**: Limit who can add packages to this directory
5. **Audit trail**: Git history tracks all package additions

## Maintenance

### Clean old versions

```bash
# Remove old package versions
git rm storage/old-package.deb
git commit -m "Remove old package version"

# Prune LFS objects (requires server access)
git lfs prune
```

### Verify integrity

```bash
# Check all stored packages
for deb in storage/*.deb; do
  echo "Checking $deb..."
  dpkg-deb -I "$deb" || echo "ERROR: $deb is corrupted"
done
```
