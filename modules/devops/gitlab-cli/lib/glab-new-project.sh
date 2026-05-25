#!/usr/bin/env bash
# modules/devops/gitlab-cli/lib/glab-new-project.sh

set -euo pipefail

NAME="${1:-}"
NAMESPACE_ID="${2:-$GITLAB_DEFAULT_NAMESPACE_ID}"

if [ -z "$NAME" ]; then
  echo "🚨 Uso: $0 <nome-projeto> [namespace_id]"
  exit 1
fi

if [ -z "$NAMESPACE_ID" ]; then
  echo "⚠️ Define GITLAB_DEFAULT_NAMESPACE_ID ou passa o ID."
  exit 1
fi

echo "🚀 Criando projeto: $NAME (namespace: $NAMESPACE_ID)"

glab api POST projects \
  --field "name=$NAME" \
  --field "namespace_id=$NAMESPACE_ID" \
  --field "visibility=internal" \
  --field "initialize_with_readme=false" \
  --field "issues_enabled=false" \
  --field "merge_requests_enabled=true" \
  --field "jobs_enabled=true" \
  --field "container_registry_enabled=false" \
  --field "packages_enabled=false" \
  --field "wiki_enabled=false" |
  jq -r '
  .web_url as $url |
  "✅ Criado: \(.path_with_namespace)",
  "🌐 Acessar: \($url)",
  "🔗 git remote add origin \(.http_url_to_repo)"'

echo "💡 Após confirmar, faz:"
echo "   git remote add origin <URL> && git push -u origin main"
