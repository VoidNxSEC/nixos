# GitLab Duo Nix Configuration

Configuração declarativa e desacoplada do GitLab Duo via Nix, implementada a nível de repositório root.

## 📁 Estrutura

```
nix/
├── flake.nix                    # Flake principal com configuração GitLab Duo
├── gitlab-duo/
│   ├── settings.yaml            # Configuração YAML (versionada)
│   ├── module.nix               # Módulo Nix reutilizável
│   └── default.nix              # Package definition
├── modules/
│   └── default.nix              # Central de módulos
├── scripts/
│   └── validate-gitlab-duo.sh   # Script de validação
└── README.md                    # Este arquivo
```

## 🚀 Quick Start

### 1. Configurar API Key

```bash
mkdir -p ~/.config/gitlab-duo
echo "your_api_key_here" > ~/.config/gitlab-duo/api-key
chmod 600 ~/.config/gitlab-duo/api-key
```

### 2. Usar a Configuração

```bash
# Entrar no ambiente Nix com GitLab Duo configurado
nix develop nix#

# Ou especificamente
nix develop ./nix
```

### 3. Validar Configuração

```bash
bash nix/scripts/validate-gitlab-duo.sh
```

## ⚙️ Configuração

### settings.yaml

Arquivo YAML que declara todas as settings:

```yaml
duo:
  enabled: true
  api:
    endpoint: "https://gitlab.com/api/v4"
  features:
    code_completion: true
    code_review: true
    security_scanning: true
    documentation_generation: true
  models:
    code_generation: "claude-3-5-sonnet"
    code_review: "claude-3-5-sonnet"
    security: "claude-3-5-sonnet"
  rate_limit:
    requests_per_minute: 60
    tokens_per_minute: 90000
  cache:
    enabled: true
    ttl_seconds: 3600
  logging:
    level: "info"
    format: "json"
```

### Variáveis de Ambiente

Todas as variáveis são carregadas automaticamente ao entrar em `nix develop`:

```bash
GITLAB_DUO_ENABLED=true
GITLAB_DUO_ENDPOINT=https://gitlab.com/api/v4
GITLAB_DUO_FEATURES_CODE_COMPLETION=true
GITLAB_DUO_FEATURES_CODE_REVIEW=true
GITLAB_DUO_FEATURES_SECURITY_SCANNING=true
GITLAB_DUO_FEATURES_DOCUMENTATION=true
GITLAB_DUO_MODEL_CODE_GENERATION=claude-3-5-sonnet
GITLAB_DUO_MODEL_CODE_REVIEW=claude-3-5-sonnet
GITLAB_DUO_MODEL_SECURITY=claude-3-5-sonnet
GITLAB_DUO_RATE_LIMIT_RPM=60
GITLAB_DUO_RATE_LIMIT_TPM=90000
GITLAB_DUO_CACHE_ENABLED=true
GITLAB_DUO_CACHE_TTL=3600
GITLAB_DUO_LOG_LEVEL=info
GITLAB_DUO_LOG_FORMAT=json
```

## 🔐 Segurança

- **API Key**: Armazenada em `~/.config/gitlab-duo/api-key` (não versionada)
- **Permissões**: 600 (apenas leitura do usuário)
- **Carregamento**: Dinâmico no shellHook do flake.nix

## 🔧 Customização

### Alterar Log Level

Edite `nix/gitlab-duo/settings.yaml`:

```yaml
logging:
  level: "debug"  # ou "info", "warning", "error"
```

### Desabilitar Features

```yaml
features:
  code_review:
    enabled: false
```

### Ajustar Rate Limits

```yaml
rate_limit:
  requests_per_minute: 120
  tokens_per_minute: 180000
```

## 📊 Validação

```bash
bash nix/scripts/validate-gitlab-duo.sh
```

Verifica:
- ✓ Variáveis de ambiente
- ✓ Feature flags
- ✓ Configuração de modelos
- ✓ Rate limiting
- ✓ Cache
- ✓ Logging
- ✓ Arquivos de configuração
- ✓ Sintaxe YAML

## 🐛 Troubleshooting

### API Key não encontrada

```bash
# Verificar arquivo
ls -la ~/.config/gitlab-duo/api-key

# Recriar se necessário
mkdir -p ~/.config/gitlab-duo
echo "your_key" > ~/.config/gitlab-duo/api-key
chmod 600 ~/.config/gitlab-duo/api-key
```

### Variáveis não carregadas

```bash
# Verificar se está no nix develop
echo $GITLAB_DUO_ENABLED

# Se vazio, entrar no ambiente
nix develop ./nix
```

### Erro de sintaxe YAML

```bash
# Validar
yq eval '.' nix/gitlab-duo/settings.yaml
```

## 📚 Referências

- [GitLab Duo Docs](https://docs.gitlab.com/ee/user/ai_features/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [YAML Spec](https://yaml.org/)

## ✅ Checklist

- [ ] Criar `~/.config/gitlab-duo/api-key`
- [ ] Executar `nix develop ./nix`
- [ ] Executar `bash nix/scripts/validate-gitlab-duo.sh`
- [ ] Verificar variáveis de ambiente
- [ ] Testar features do GitLab Duo
