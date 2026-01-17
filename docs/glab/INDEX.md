# 🎯 GitLab Duo Nix Configuration - Complete Setup

## ✅ Status: Configuração Completa e Desacoplada

Toda a configuração do GitLab Duo foi movida para um repositório separado em `nix/`, mantendo a independência do projeto principal.

---

## 📚 Documentação Disponível

### 🚀 Para Começar Rápido
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Guia rápido com comandos essenciais
- **[README.md](./README.md)** - Documentação principal completa

### 🏗️ Para Entender a Arquitetura
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Diagramas e fluxos de configuração
- **[INTEGRATION.md](./INTEGRATION.md)** - Como integrar no seu flake principal

### 📋 Para Detalhes
- **[SETUP_SUMMARY.md](./SETUP_SUMMARY.md)** - Sumário detalhado de setup

### 💡 Para Exemplos
- **[examples/usage.sh](./examples/usage.sh)** - Exemplo de uso
- **[examples/flake-integration.nix](./examples/flake-integration.nix)** - Exemplo de integração

---

## 🚀 Quick Start (3 Passos)

### 1️⃣ Configurar API Key

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

---

## 📁 Estrutura de Arquivos

```
nix/
├── 📄 flake.nix                    # Flake principal com GitLab Duo
├── 📄 README.md                    # Documentação principal
├── 📄 QUICK_REFERENCE.md           # Guia rápido
├── 📄 ARCHITECTURE.md              # Diagramas e arquitetura
├── 📄 INTEGRATION.md               # Guia de integração
├── 📄 SETUP_SUMMARY.md             # Sumário de setup
│
├── 📁 gitlab-duo/
│   ├── 📄 settings.yaml            # Configuração YAML (versionada)
│   ├── 📄 module.nix               # Módulo Nix reutilizável
│   └── 📄 default.nix              # Package definition
│
├── 📁 modules/
│   └── 📄 default.nix              # Central de módulos
│
├── 📁 scripts/
│   └── 📄 validate-gitlab-duo.sh   # Script de validação
│
└── 📁 examples/
    ├── 📄 usage.sh                 # Exemplo de uso
    └── 📄 flake-integration.nix    # Exemplo de integração
```

---

## 🎯 Funcionalidades

### ✅ Habilitadas por Padrão

- ✓ Code Completion
- ✓ Code Review
- ✓ Security Scanning
- ✓ Documentation Generation
- ✓ Caching (TTL 1h)
- ✓ Rate Limiting (60 RPM, 90k TPM)
- ✓ Logging JSON

### 🔧 Configuráveis

- Log Level (debug, info, warning, error)
- Feature Flags (ativar/desativar)
- Rate Limits (RPM, TPM)
- Cache TTL
- Modelos de IA
- E muito mais...

---

## 📊 Variáveis de Ambiente

Todas as variáveis são carregadas automaticamente ao entrar em `nix develop ./nix`:

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
GITLAB_DUO_API_KEY=<carregado de ~/.config/gitlab-duo/api-key>
```

---

## 🔐 Segurança

| Aspecto | Implementação |
|---------|---------------|
| **API Key** | Armazenada em `~/.config/gitlab-duo/api-key` (não versionada) |
| **Permissões** | 600 (apenas leitura do usuário) |
| **Carregamento** | Dinâmico no shellHook |
| **Versionamento** | Apenas configuração pública |

---

## 🔄 Fluxo de Uso

```
1. Setup Inicial
   └── mkdir -p ~/.config/gitlab-duo
   └── echo "api_key" > ~/.config/gitlab-duo/api-key
   └── chmod 600 ~/.config/gitlab-duo/api-key

2. Entrar no Ambiente
   └── nix develop ./nix

3. Validar Configuração
   └── bash nix/scripts/validate-gitlab-duo.sh

4. Usar GitLab Duo
   └── Variáveis de ambiente disponíveis
   └── Features habilitadas
   └── Pronto para usar!
```

---

## 🎓 Próximos Passos

### Imediato
1. Criar `~/.config/gitlab-duo/api-key`
2. Executar `nix develop ./nix`
3. Executar `bash nix/scripts/validate-gitlab-duo.sh`

### Customização
1. Editar `nix/gitlab-duo/settings.yaml`
2. Commit e push das mudanças
3. Validar novamente

### Integração (Opcional)
1. Ler `nix/INTEGRATION.md`
2. Integrar no seu flake principal
3. Ou usar `nix develop ./nix` sempre que precisar

---

## 📞 Suporte

### Documentação
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Comandos rápidos
- [README.md](./README.md) - Documentação completa
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Diagramas

### Troubleshooting
- [QUICK_REFERENCE.md#-troubleshooting-rápido](./QUICK_REFERENCE.md) - Soluções rápidas
- [README.md#-troubleshooting](./README.md) - Soluções detalhadas

### Exemplos
- [examples/usage.sh](./examples/usage.sh) - Exemplo de uso
- [examples/flake-integration.nix](./examples/flake-integration.nix) - Exemplo de integração

---

## ✨ Benefícios

✓ **Desacoplado** - Independente do projeto principal
✓ **Versionado** - Rastreável no Git
✓ **Reproducível** - Mesma config em todos os ambientes
✓ **Seguro** - Secrets não versionados
✓ **Flexível** - Fácil de customizar
✓ **Reutilizável** - Pode ser usado em múltiplos projetos
✓ **Documentado** - Documentação completa
✓ **Validado** - Script de validação incluído

---

## 🎉 Pronto para Usar!

```bash
# 1. Setup
mkdir -p ~/.config/gitlab-duo
echo "your_api_key" > ~/.config/gitlab-duo/api-key
chmod 600 ~/.config/gitlab-duo/api-key

# 2. Usar
nix develop ./nix

# 3. Validar
bash nix/scripts/validate-gitlab-duo.sh

# ✅ Pronto!
```

---

## 📖 Índice de Documentação

| Documento | Propósito | Público |
|-----------|-----------|---------|
| [README.md](./README.md) | Documentação principal | Todos |
| [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | Guia rápido | Iniciantes |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Diagramas e fluxos | Arquitetos |
| [INTEGRATION.md](./INTEGRATION.md) | Integração com flake | Desenvolvedores |
| [SETUP_SUMMARY.md](./SETUP_SUMMARY.md) | Sumário detalhado | Referência |
| [examples/usage.sh](./examples/usage.sh) | Exemplo de uso | Aprendizado |
| [examples/flake-integration.nix](./examples/flake-integration.nix) | Exemplo de integração | Aprendizado |

---

**Última atualização**: 2026-01-17
**Status**: ✅ Completo e Pronto para Usar
