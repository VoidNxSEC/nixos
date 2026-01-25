#!/usr/bin/env bash
set -euo pipefail

cd /etc/nixos

# Backup current secrets
cp secrets/gitlab.yaml secrets/gitlab.yaml.backup-$(date +%Y%m%d-%H%M%S)

# Create temp file in proper location for SOPS rules to match
cat > secrets/gitlab-temp.yaml << 'EOF'
gitlab_token: <YOUR_GITLAB_TOKEN_HERE>
gitlab_username: marcosfpina
gitlab_email: sec@voidnxlabs.com
gitlab_deploy_token: <YOUR_GITLAB_DEPLOY_TOKEN_HERE>
gitlab_deploy_username: voidnx
EOF

# Encrypt it (should match secrets/.*\.yaml$ rule)
sops -e secrets/gitlab-temp.yaml > secrets/gitlab.yaml.new

# Replace old file
mv secrets/gitlab.yaml.new secrets/gitlab.yaml

# Clean up
rm -f secrets/gitlab-temp.yaml

echo "✓ GitLab secrets updated successfully!"
echo ""
echo "Verifying encryption..."
sops -d secrets/gitlab.yaml
