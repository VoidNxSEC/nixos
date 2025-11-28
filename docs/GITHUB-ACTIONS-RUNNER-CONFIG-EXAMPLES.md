# GitHub Actions Runner - Exemplos de Configuração

## 🎯 Configurações Disponíveis

O módulo agora suporta três modos de operação:

1. **Persistent Runner** (Padrão) - Runner permanente que persiste entre reboots
2. **Ephemeral Runner** - Runner descartável, removido após cada job
3. **Rotational Runner** - Runner que é removido e reconfigurado a cada início

## 📝 Exemplos de Configuração

### 1. Runner Persistente (Padrão - Recomendado para Produção)

```nix
# Em configuration.nix ou módulo específico
kernelcore.services.github-runner = {
  enable = true;
  useSops = true;  # Usar SOPS para gerenciar token (recomendado)
  
  runnerType = "repository";  # Registrar para repositório específico
  runnerName = "nixos-prod-runner";
  repoUrl = "https://github.com/VoidNxSEC/nixos";
  
  extraLabels = [
    "nixos"
    "nix"
    "production"
    "linux-x64"
  ];
  
  # Modo persistente (padrão)
  rotateRunner = false;
  ephemeral = false;
};
```

**Características:**
- ✅ Runner persiste entre reboots
- ✅ Não requer novo token a cada inicialização
- ✅ Ideal para ambientes de produção estáveis
- ✅ Melhor performance (não há overhead de reconfiguração)

**Uso em workflows:**
```yaml
jobs:
  build:
    runs-on: [self-hosted, nixos, production]
    steps:
      - uses: actions/checkout@v4
      - name: Build with Nix
        run: nix build
```

### 2. Runner Efêmero (Ephemeral - Recomendado para CI/CD Limpo)

```nix
kernelcore.services.github-runner = {
  enable = true;
  useSops = true;
  
  runnerType = "repository";
  runnerName = "nixos-ephemeral-runner";
  repoUrl = "https://github.com/VoidNxSEC/nixos";
  
  extraLabels = [
    "nixos"
    "nix"
    "ephemeral"
    "clean-state"
  ];
  
  # Modo efêmero - removido após cada job
  ephemeral = true;
  rotateRunner = false;
};
```

**Características:**
- ✅ Runner é automaticamente removido após completar UM job
- ✅ Ambiente limpo para cada execução
- ✅ Ideal para testes que requerem estado limpo
- ✅ Menor risco de acúmulo de artefatos
- ⚠️ Requer novo runner para cada job (pode ser mais lento)

**Uso em workflows:**
```yaml
jobs:
  test:
    runs-on: [self-hosted, nixos, ephemeral]
    steps:
      - uses: actions/checkout@v4
      - name: Run tests in clean environment
        run: nix-shell --run "make test"
```

### 3. Runner Rotacional (Para Desenvolvimento/Teste)

```nix
kernelcore.services.github-runner = {
  enable = true;
  useSops = true;
  
  runnerType = "repository";
  runnerName = "nixos-dev-runner";
  repoUrl = "https://github.com/VoidNxSEC/nixos";
  
  extraLabels = [
    "nixos"
    "nix"
    "development"
    "rotating"
  ];
  
  # Modo rotacional - reconfigura a cada início
  rotateRunner = true;
  ephemeral = false;
};
```

**Características:**
- ✅ Runner é removido e recriado a cada reinício do serviço
- ✅ Útil para desenvolvimento e testes
- ✅ Garante configuração limpa após mudanças
- ⚠️ Requer novo token a cada reinício
- ⚠️ Não recomendado para produção

**Uso em workflows:**
```yaml
jobs:
  dev-test:
    runs-on: [self-hosted, nixos, development]
    steps:
      - uses: actions/checkout@v4
      - name: Test new configuration
        run: nix flake check
```

### 4. Runner em Nível de Organização

```nix
kernelcore.services.github-runner = {
  enable = true;
  useSops = true;
  
  runnerType = "organization";  # Runner disponível para toda organização
  runnerName = "nixos-org-runner";
  repoUrl = "https://github.com/VoidNxSEC";  # URL da organização
  
  extraLabels = [
    "nixos"
    "nix"
    "organization-wide"
    "shared"
  ];
  
  ephemeral = false;
  rotateRunner = false;
};
```

**Características:**
- ✅ Um runner para todos os repositórios da organização
- ✅ Economia de recursos
- ✅ Gestão centralizada
- ⚠️ Requer permissões de organização para configurar

**Uso em workflows (qualquer repo da org):**
```yaml
jobs:
  shared-build:
    runs-on: [self-hosted, nixos, organization-wide]
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: nix build
```

## 🔧 Configuração de Secrets (SOPS)

### Adicionar Token ao SOPS

```bash
# Editar arquivo de secrets
sops secrets/github.yaml

# Adicionar o token:
github_runner_token: "YOUR_GITHUB_TOKEN_HERE"
```

### Gerar Novo Token no GitHub

**Para Repositório:**
```bash
# Acesse: https://github.com/VoidNxSEC/nixos/settings/actions/runners/new
# Copie o token gerado (válido por 1 hora)
```

**Para Organização:**
```bash
# Acesse: https://github.com/organizations/VoidNxSEC/settings/actions/runners/new
# Requer permissões de admin da organização
```

## 🎭 Estratégias de Uso

### Estratégia 1: Runner Único Persistente

```nix
# Melhor para: projetos pequenos/médios, recursos limitados
{
  kernelcore.services.github-runner = {
    enable = true;
    runnerName = "nixos-main";
    # ... configuração persistente
  };
}
```

**Prós:**
- Simples de gerenciar
- Baixo overhead
- Um token dura para sempre

**Contras:**
- Estado pode acumular
- Conflitos entre jobs

### Estratégia 2: Múltiplos Runners Especializados

```nix
# Melhor para: projetos grandes, CI/CD complexo
{
  # Runner para builds
  kernelcore.services.github-runner = {
    enable = true;
    runnerName = "nixos-build";
    extraLabels = [ "build" "compile" ];
    ephemeral = false;
  };
  
  # Runner para testes (limpo a cada vez)
  kernelcore.services.github-runner-test = {
    enable = true;
    runnerName = "nixos-test";
    extraLabels = [ "test" "clean" ];
    ephemeral = true;
  };
}
```

**Prós:**
- Isolamento de workloads
- Performance otimizada por tipo de job
- Estado limpo onde necessário

**Contras:**
- Mais complexo de gerenciar
- Requer mais recursos

### Estratégia 3: Híbrida (Recomendado)

```nix
# Melhor para: maioria dos casos
{
  # Runner principal persistente
  kernelcore.services.github-runner = {
    enable = true;
    runnerName = "nixos-persistent";
    extraLabels = [ "main" "build" ];
    ephemeral = false;
  };
  
  # Runner secundário efêmero para testes críticos
  kernelcore.services.github-runner-ephemeral = {
    enable = true;
    runnerName = "nixos-ephemeral";
    extraLabels = [ "test" "isolated" ];
    ephemeral = true;
  };
}
```

## 📊 Comparação de Modos

| Característica | Persistente | Efêmero | Rotacional |
|----------------|-------------|---------|------------|
| **Persiste entre reboots** | ✅ Sim | ✅ Sim* | ❌ Não |
| **Removido após job** | ❌ Não | ✅ Sim | ❌ Não |
| **Requer novo token** | ❌ Não | ❌ Não | ✅ Sim |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Estado limpo** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Uso em produção** | ✅ Recomendado | ✅ OK | ⚠️ Não recomendado |
| **Uso em desenvolvimento** | ✅ OK | ✅ OK | ✅ Recomendado |

*O runner persiste mas será recriado após cada job

## 🚀 Quick Start

### 1. Configuração Mínima (Persistente)

```nix
{ config, pkgs, ... }:
{
  kernelcore.services.github-runner.enable = true;
  # Usar defaults, apenas configurar o token via SOPS
}
```

### 2. Ativar e Testar

```bash
# 1. Adicionar token ao SOPS
sops secrets/github.yaml

# 2. Rebuild
sudo nixos-rebuild switch

# 3. Verificar status
systemctl status actions-runner

# 4. Ver logs
journalctl -u actions-runner -f

# 5. Verificar no GitHub
# https://github.com/VoidNxSEC/nixos/settings/actions/runners
```

### 3. Workflow de Teste

```yaml
name: Test Self-Hosted Runner
on: push

jobs:
  test:
    runs-on: [self-hosted, nixos]
    steps:
      - uses: actions/checkout@v4
      - name: Test Nix
        run: nix --version
      - name: Show system info
        run: uname -a
```

## 🔍 Troubleshooting

### Runner não aparece no GitHub

```bash
# Verificar logs
journalctl -u actions-runner -n 100

# Verificar configuração
cat /var/lib/actions-runner/.runner | jq

# Verificar token SOPS
sudo cat /run/secrets/github_runner_token
```

### Ephemeral runner não está sendo removido

```bash
# Verificar se flag --ephemeral foi aplicado
cat /tmp/runner-config.log | grep ephemeral

# Verificar comportamento
journalctl -u actions-runner | grep "ephemeral"
```

### Rotation mode não está funcionando

```bash
# Verificar se configuração foi removida
ls -la /var/lib/actions-runner/.{runner,credentials}

# Ver logs de remoção
cat /tmp/runner-rotation-removal.log
```

## 📚 Recursos Adicionais

- [GitHub Actions Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Self-hosted runners security](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)
- [Using labels with self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-labels-with-self-hosted-runners)

---

**Atualizado**: 2025-11-28  
**Versão do Runner**: 2.329.0