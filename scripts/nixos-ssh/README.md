# SSH Configuration - NixOS

This system uses declarative SSH configuration managed by NixOS.

## Key Files

- Personal: ~/.ssh/id_ed25519_marcos
- Org: ~/.ssh/id_ed25519_voidnxlabs
- Server: ~/.ssh/id_ed25519
- GitLab: ~/.ssh/id_ed25519_gitlab

## Usage Examples

### Git with different identities

```bash
# Personal repository
git clone git@github.com-marcos:username/repo.git

# Organization repository
git clone git@github.com-voidnxlabs:voidnxlabs/repo.git

# GitLab
git clone git@gitlab.com:user/project.git
```

### Server connections

```bash
# Desktop/builder
ssh desktop
# or
ssh-desktop

# Internal server
ssh voidnx-server
# or
ssh-server
```

### Key Management

```bash
# Add all keys to agent
ssh-add-all

# List loaded keys
ssh-list

# Test GitHub connection
ssh-test-github

# Generate new key
ssh-keygen-ed25519 "your-email@example.com"
```

## Configuration

Edit module options in:
/etc/nixos/modules/system/ssh-config.nix

Available options:
- kernelcore.ssh.enable
- kernelcore.ssh.sshDir
- kernelcore.ssh.personalKey
- kernelcore.ssh.orgKey
- kernelcore.ssh.serverKey
- kernelcore.ssh.serverHost
- kernelcore.ssh.serverUser

## Security Notes

- ForwardAgent is disabled by default
- Only modern crypto algorithms allowed
- Keys are added to agent with 1h timeout
- Connection multiplexing enabled for performance
- Known hosts verified to prevent MITM

## Troubleshooting

### Key not being used
```bash
ssh -vvv git@github.com-marcos
```

### Agent not running
```bash
eval $(ssh-agent)
ssh-add-all
```

### Wrong key being used
```bash
# Make sure IdentitiesOnly is set in config
ssh -o IdentitiesOnly=yes -i ~/.ssh/specific_key git@github.com
```
