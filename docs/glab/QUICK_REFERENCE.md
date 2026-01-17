# GitLab Duo Nix Configuration - Quick Reference

## 📦 Arquivos Criados

```
nix/
├── flake.nix                          ✓ Flake principal
├── gitlab-duo/
│   ├── settings.yaml                  ✓ Configuração YAML
│   ├── module.nix                     ✓ Módulo Nix
│   └── default.nix                    ✓ Package definition
├── modules/
│   └── default.nix                    ✓ Central de módulos
├── scripts/
│   └── validate-gitlab-duo.sh         ✓ Script de validação
├── examples/
│   ├── usage.sh                       ✓ Exemplo de uso
│   └── flake-integration.nix          ✓ Exemplo de integração
├── README.md                          ✓ Documentação
├── INTEGRATION.md                     ✓ Guia de integração
└── SETUP_SUMMARY.md                   ✓ Sumário de setup
```

## 🚀 Setup em 3 Passos

### 1️⃣ Configurar API Key (Uma Única Vez)

```bash
mkdir -p ~/.config/gitlab-duo
echo "your_api_key_here" > ~/.config/gitlab-duo/api-key
chmod 600 ~/.config/gitlab-duo/api-key
```

### 2️⃣ Entrar no Ambiente

```bash
nix develop ./nix
```

### 3️⃣ Validar

```bash
bash nix/scripts/validate-gitlab-duo.sh
```

## 📋 Variáveis de Ambiente Carregadas

| Variável | Valor |
|----------|-------|
| `GITLAB_DUO_ENABLED` | `true` |
| `GITLAB_DUO_ENDPOINT` | `https://gitlab.com/api/v4` |
| `GITLAB_DUO_FEATURES_CODE_COMPLETION` | `true` |
| `GITLAB_DUO_FEATURES_CODE_REVIEW` | `true` |
| `GITLAB_DUO_FEATURES_SECURITY_SCANNING` | `true` |
| `GITLAB_DUO_FEATURES_DOCUMENTATION` | `true` |
| `GITLAB_DUO_MODEL_CODE_GENERATION` | `claude-3-5-sonnet` |
| `GITLAB_DUO_MODEL_CODE_REVIEW` | `claude-3-5-sonnet` |
| `GITLAB_DUO_MODEL_SECURITY` | `claude-3-5-sonnet` |
| `GITLAB_DUO_RATE_LIMIT_RPM` | `60` |
| `GITLAB_DUO_RATE_LIMIT_TPM` | `90000` |
| `GITLAB_DUO_CACHE_ENABLED` | `true` |
| `GITLAB_DUO_CACHE_TTL` | `3600` |
| `GITLAB_DUO_LOG_LEVEL` | `info` |
| `GITLAB_DUO_LOG_FORMAT` | `json` |
| `GITLAB_DUO_API_KEY` | `<from ~/.config/gitlab-duo/api-key>` |

## 🎯 Comandos Úteis

```bash
# Entrar no ambiente
nix develop ./nix

# Validar configuração
bash nix/scripts/validate-gitlab-duo.sh

# Ver exemplo de uso
bash nix/examples/usage.sh

# Editar configuração
vim nix/gitlab-duo/settings.yaml

# Verificar variáveis carregadas
env | grep GITLAB_DUO

# Verificar API key
cat ~/.config/gitlab-duo/api-key
```

## 🔧 Customização Rápida

### Alterar Log Level

```bash
# Editar settings.yaml
vim nix/gitlab-duo/settings.yaml

# Mudar:
# logging:
#   level: "debug"  # ou "info", "warning", "error"
```

### Desabilitar Feature

```bash
# Editar settings.yaml
vim nix/gitlab-duo/settings.yaml

# Mudar:
# features:
#   code_review:
#     enabled: false
```

### Ajustar Rate Limits

```bash
# Editar settings.yaml
vim nix/gitlab-duo/settings.yaml

# Mudar:
# rate_limit:
#   requests_per_minute: 120
#   tokens_per_minute: 180000
```

## 🐛 Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| `GITLAB_DUO_ENABLED` vazio | Execute `nix develop ./nix` |
| API key não encontrada | Crie `~/.config/gitlab-duo/api-key` |
| Erro de sintaxe YAML | Execute `yq eval '.' nix/gitlab-duo/settings.yaml` |
| Variáveis não carregadas | Verifique `echo $GITLAB_DUO_ENABLED` |

## 📚 Documentação

- **`nix/README.md`** - Documentação completa
- **`nix/INTEGRATION.md`** - Como integrar no seu flake
- **`nix/SETUP_SUMMARY.md`** - Sumário detalhado
- **`nix/examples/usage.sh`** - Exemplo de uso
- **`nix/examples/flake-integration.nix`** - Exemplo de integração

## ✅ Checklist

- [ ] Criar `~/.config/gitlab-duo/api-key`
- [ ] Executar `nix develop ./nix`
- [ ] Executar `bash nix/scripts/validate-gitlab-duo.sh`
- [ ] Verificar `echo $GITLAB_DUO_ENABLED`
- [ ] Testar features do GitLab Duo
- [ ] (Opcional) Integrar no seu flake principal

## 🎉 Pronto!

Sua configuração do GitLab Duo está:
- ✓ Desacoplada do projeto principal
- ✓ Versionada no Git
- ✓ Reproducível em qualquer ambiente
- ✓ Segura (secrets não versionados)
- ✓ Fácil de customizar
- ✓ Pronta para usar

**Próximo passo**: `nix develop ./nix`
