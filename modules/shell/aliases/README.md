# Shell Aliases - Professional Structure

Este diretório contém aliases organizados por categoria para facilitar manutenção e descoberta.

## 📁 Estrutura

```
aliases/
├── default.nix          # Aggregator - importa todos os aliases
├── docker/              # Docker-related aliases
│   ├── build.nix       # Docker build shortcuts
│   ├── compose.nix     # Docker compose management
│   └── gpu.nix         # GPU-enabled docker runs
├── kubernetes/          # Kubernetes aliases
│   └── kubectl.nix     # kubectl shortcuts and contexts
├── gcloud/              # Google Cloud Platform
│   └── gcloud.nix      # gcloud, gsutil, k8s on GCP
├── ai/                  # AI/ML specific
│   ├── ollama.nix      # Ollama model management
│   └── gpu.nix         # GPU/ML stack management
├── nix/                 # Nix ecosystem
│   └── system.nix      # nix-build, nix-shell, nixos-rebuild
├── security/            # Security & secrets management
│   └── secrets.nix     # SOPS secrets management
└── system/              # General system utilities
    └── utils.nix       # ls, grep, find shortcuts
```

## 🎯 Filosofia de Organização

### 1. Separação por Domínio
Cada categoria tem seu próprio diretório:
- **docker/** - Tudo relacionado a Docker
- **kubernetes/** - Orchestração K8s
- **gcloud/** - Google Cloud Platform
- **ai/** - Machine Learning e AI stacks
- **nix/** - Nix/NixOS específico
- **security/** - Gerenciamento de segurança e secrets (SOPS)
- **system/** - Utilidades gerais do sistema

### 2. Nomenclatura Clara
- Nomes descritivos: `docker-build-gpu` não `dbg`
- Prefixos consistentes por categoria
- Fácil descoberta via tab completion

### 3. Documentação Inline
Cada alias deve ter comentário explicando:
- O que faz
- Quando usar
- Exemplos de uso

## 🚀 Como Usar

### Importar Todos os Aliases
No seu `flake.nix` ou `configuration.nix`:

```nix
./modules/shell/aliases
```

Isso importa automaticamente todos os aliases via `default.nix`.

### Importar Categoria Específica
Se quiser apenas uma categoria:

```nix
./modules/shell/aliases/docker
```

### Adicionar Novo Alias

1. Escolha a categoria apropriada
2. Edite o arquivo correspondente
3. Siga o padrão existente:

```nix
{
  # Categoria: Descrição
  alias-name = "command-here";  # Comentário explicativo
}
```

## 📋 Convenções

### Prefixos por Categoria
- `d-*` - Docker (d-build, d-run, d-compose)
- `k-*` - Kubernetes (k-pods, k-logs, k-deploy)
- `gc-*` - Google Cloud (gc-list, gc-ssh, gc-logs)
- `ai-*` - AI/ML (ai-up, ai-logs, ai-status)
- `nx-*` - Nix (nx-build, nx-shell, nx-search)

### Flags GPU
Aliases que usam GPU devem ter sufixo `-gpu`:
- `d-run-gpu` - Docker run com GPU
- `ai-jupyter-gpu` - Jupyter com GPU

### Operações Comuns
Aliases que seguem o padrão CRUD:
- `*-up` - Inicia serviço
- `*-down` - Para serviço
- `*-restart` - Reinicia serviço
- `*-logs` - Mostra logs
- `*-status` - Mostra status

## 🔧 Manutenção

### Adicionar Nova Categoria
1. Criar diretório: `mkdir aliases/nova-categoria`
2. Criar `default.nix` na categoria
3. Adicionar import em `aliases/default.nix`

### Remover Aliases Obsoletos
- Marcar como deprecated com comentário
- Adicionar mensagem sugerindo alternativa
- Remover após 1 mês

### Refatorar Aliases
- Sempre manter compatibilidade
- Adicionar alias novo, deprecar antigo
- Documentar mudanças

## 📊 Estatísticas

**Total de Aliases**: ~300+
**Categorias**: 6
**Tamanho**: ~40KB (antes: 113KB em 13 arquivos)

## 🎓 Exemplos de Uso

### Docker
```bash
# Build e run com GPU
d-build-gpu myimage
d-run-gpu myimage:latest

# Compose stack
d-compose-up ai-stack
d-compose-logs -f ollama
```

### Kubernetes
```bash
# Listar pods
k-pods

# Ver logs
k-logs pod-name -f

# Port forward
k-port-forward service 8080:80
```

### Google Cloud
```bash
# Listar VMs
gc-list-vms

# SSH em VM
gc-ssh vm-name

# Ver logs
gc-logs service-name
```

### AI/ML
```bash
# Subir stack AI
ai-up

# Status dos serviços
ai-status

# Logs do Ollama
ai-ollama-logs
```

### Nix
```bash
# Build local
nx-build

# Nix shell
nx-shell python

# Rebuild sistema
nx-rebuild
```

### Security/Secrets (SOPS)
```bash
# Listar secrets
secrets-list  # ou: sl

# Ver secret descriptografado
sv /etc/nixos/secrets/api.yaml
view-api      # Atalho para API keys

# Editar secret
se /etc/nixos/secrets/api.yaml
secret-api    # Atalho para editar API keys

# Extrair valor específico
secret-get api.yaml openai_api_key

# Verificar integridade
secrets-verify

# Ver todos os comandos
secrets-help
```

---

**Última Atualização**: 2025-11-07
**Mantido por**: kernelcore
**Versão**: 2.1.0 (Adicionado: Security/Secrets aliases)
