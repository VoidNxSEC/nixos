#!/usr/bin/env bash
set -euo pipefail

cd /etc/nixos

# Create temporary file with updated GitLab secrets
cat > /tmp/gitlab-updated.yaml << 'EOF'
gitlab_token: <YOUR_GITLAB_TOKEN_HERE>
gitlab_username: marcosfpina
gitlab_email: sec@voidnxlabs.com
gitlab_deploy_token: <YOUR_GITLAB_DEPLOY_TOKEN_HERE>
gitlab_deploy_username: voidnx
EOF

# Encrypt using SOPS from the NixOS directory (so it finds .sops.yaml)
sops -e /tmp/gitlab-updated.yaml > secrets/gitlab.yaml

# Secure delete of temporary file
shred -vfz -n 3 /tmp/gitlab-updated.yaml 2>/dev/null || rm -f /tmp/gitlab-updated.yaml

echo "✓ GitLab secrets updated successfully!"
echo ""
echo "Verifying encryption..."
sops -d secrets/gitlab.yaml

echo ""
echo "Next steps:"
echo "  1. Review the secrets above"
echo "  2. git add secrets/gitlab.yaml"
echo "  3. git commit -m 'sec: update GitLab tokens'"
