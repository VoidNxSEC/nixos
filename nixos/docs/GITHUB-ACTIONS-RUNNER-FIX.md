# GitHub Actions Runner - Correção de Problemas de Reboot

## 📋 Problema Identificado

O serviço GitHub Actions runner estava falhando a cada reboot do sistema devido a:

1. **Tokens de uso único**: GitHub Actions tokens só podem ser usados uma vez para configuração
2. **Reconfiguração desnecessária**: O serviço tentava reconfigurar o runner mesmo quando já estava configurado
3. **Falta de cleanup**: Runners antigos permaneciam registrados no GitHub como "offline"
4. **Logs insuficientes**: Difícil diagnosticar problemas sem logs detalhados

## ✅ Correções Implementadas

### 1. Verificação Inteligente de Estado

O serviço agora verifica o estado completo do runner antes de tentar reconfigurar:

```bash
# Verifica se ambos os arquivos de configuração existem
if [ -f /var/lib/actions-runner/.runner ] && [ -f /var/lib/actions-runner/.credentials ]; then
    # Runner já configurado - pula configuração
    echo "Runner already configured, skipping configuration"
else
    # Necessário configurar
    echo "Configuring new runner..."
fi
```

### 2. Detecção de Configuração Quebrada

Identifica e remove automaticamente configurações inválidas:

```bash
# Se .runner existe mas .credentials não
if [ -f /var/lib/actions-runner/.runner ] && [ ! -f /var/lib/actions-runner/.credentials ]; then
    echo "WARNING: Configuration exists but credentials file missing"
    echo "Removing stale configuration..."
    rm -f /var/lib/actions-runner/.runner
fi
```

### 3. Cleanup Automático no Shutdown

Implementado `preStop` para remover o runner do GitHub antes de parar o serviço:

```bash
preStop = ''
  # Remove runner from GitHub gracefully
  if ${pkgs.bash}/bin/bash ./config.sh remove --token "$REMOVAL_TOKEN"; then
    echo "Runner removed successfully from GitHub"
  fi
'';
```

**Benefícios:**
- Evita acúmulo de runners "offline" no GitHub
- Permite reconfiguração limpa no próximo boot
- Token pode ser reutilizado para nova configuração

### 4. Logs Detalhados

Todos os passos agora geram logs detalhados salvos em `/tmp/`:

- `/tmp/runner-config.log` - Logs de configuração
- `/tmp/runner-removal.log` - Logs de remoção

```bash
echo "=== GitHub Actions Runner PreStart ==="
echo "Working directory: /var/lib/actions-runner"
echo "Runner name: $RUNNER_NAME"
echo "Runner URL: $RUNNER_URL"
```

### 5. Validação de Token SOPS

Verifica se o token está disponível antes de tentar configurar:

```bash
if [ ! -f "${tokenPath}" ]; then
  echo "ERROR: SOPS secret not found at ${tokenPath}"
  echo "Path expected: ${tokenPath}"
  exit 1
fi
RUNNER_TOKEN=$(cat "${tokenPath}")
echo "Token loaded from SOPS (length: ${#RUNNER_TOKEN})"
```

## 🔧 Como Usar

### Primeira Configuração

1. **Gerar token no GitHub**:
   ```bash
   # Vá para: https://github.com/VoidNxSEC/nixos/settings/actions/runners/new
   # Copie o token gerado
   ```

2. **Adicionar token ao SOPS**:
   ```bash
   # Editar secrets/github.yaml
   sops secrets/github.yaml
   
   # Adicionar:
   github_runner_token: "YOUR_TOKEN_HERE"
   ```

3. **Ativar o serviço**:
   ```nix
   # Em configuration.nix
   kernelcore.services.github-runner = {
     enable = true;
     runnerName = "nixos-self-hosted";
     repoUrl = "https://github.com/VoidNxSEC/nixos";
   };
   ```

4. **Rebuild e ativar**:
   ```bash
   sudo nixos-rebuild switch
   ```

### Verificar Status

```bash
# Status do serviço
systemctl status actions-runner

# Logs em tempo real
journalctl -u actions-runner -f

# Verificar configuração
ls -la /var/lib/actions-runner/.runner
ls -la /var/lib/actions-runner/.credentials

# Verificar no GitHub
# https://github.com/VoidNxSEC/nixos/settings/actions/runners
```

### Reconfigurar Runner

Se precisar reconfigurar (novo token, novo nome, etc.):

```bash
# 1. Parar o serviço (remove automaticamente do GitHub)
sudo systemctl stop actions-runner

# 2. Remover configuração local
sudo rm -f /var/lib/actions-runner/.runner
sudo rm -f /var/lib/actions-runner/.credentials

# 3. Atualizar token no SOPS (se necessário)
sops secrets/github.yaml

# 4. Iniciar serviço (reconfigura automaticamente)
sudo systemctl start actions-runner
```

## 🐛 Troubleshooting

### Runner não inicia após reboot

```bash
# Verificar logs
journalctl -u actions-runner -n 50 --no-pager

# Verificar se token SOPS está acessível
sudo cat /run/secrets/github_runner_token

# Verificar permissões
ls -la /var/lib/actions-runner/
```

### "Runner already exists" error

```bash
# Remover runner manualmente do GitHub UI
# https://github.com/VoidNxSEC/nixos/settings/actions/runners

# Limpar configuração local
sudo systemctl stop actions-runner
sudo rm -f /var/lib/actions-runner/.{runner,credentials}
sudo systemctl start actions-runner
```

### Token expirado ou inválido

```bash
# 1. Gerar novo token no GitHub
# 2. Atualizar no SOPS
sops secrets/github.yaml

# 3. Restart do serviço
sudo systemctl restart actions-runner
```

### Verificar logs detalhados

```bash
# Logs de configuração
cat /tmp/runner-config.log

# Logs de remoção
cat /tmp/runner-removal.log

# Logs do systemd
journalctl -u actions-runner -b
```

## 📊 Monitoramento

### Health Check Script

```bash
#!/usr/bin/env bash
# /usr/local/bin/check-runner-health

set -euo pipefail

echo "=== GitHub Actions Runner Health Check ==="

# Check service status
if systemctl is-active --quiet actions-runner; then
    echo "✓ Service is running"
else
    echo "✗ Service is not running"
    exit 1
fi

# Check configuration files
if [ -f /var/lib/actions-runner/.runner ] && [ -f /var/lib/actions-runner/.credentials ]; then
    echo "✓ Runner is configured"
else
    echo "✗ Runner configuration incomplete"
    exit 1
fi

# Check runner name
RUNNER_NAME=$(jq -r '.agentName' /var/lib/actions-runner/.runner 2>/dev/null || echo "unknown")
echo "✓ Runner name: $RUNNER_NAME"

echo "=== Health Check Passed ==="
```

### Adicionar ao Cron (opcional)

```nix
services.cron = {
  enable = true;
  systemCronJobs = [
    "*/15 * * * * root /usr/local/bin/check-runner-health >> /var/log/runner-health.log 2>&1"
  ];
};
```

## 📝 Mudanças no Código

Arquivo modificado: `modules/services/users/actions.nix`

**Principais alterações:**

1. ✅ Verificação de `.runner` e `.credentials` antes de configurar
2. ✅ Detecção e remoção de configurações quebradas
3. ✅ Logs detalhados em cada etapa com `echo` statements
4. ✅ `preStop` hook para remover runner do GitHub
5. ✅ `postStop` para limpar arquivos temporários
6. ✅ Validação de token SOPS antes de usar
7. ✅ Mensagens de erro mais descritivas

## 🎯 Resultado Esperado

Após essas correções, o serviço deve:

1. ✅ Iniciar corretamente após reboot sem erros
2. ✅ Não tentar reconfigurar quando já configurado
3. ✅ Remover runner do GitHub ao parar o serviço
4. ✅ Fornecer logs claros para troubleshooting
5. ✅ Detectar e corrigir automaticamente configurações quebradas

## 🔄 Próximos Passos

1. **Testar após rebuild**: `sudo nixos-rebuild switch`
2. **Testar após reboot**: `sudo reboot`
3. **Verificar no GitHub**: Confirmar runner online
4. **Monitorar logs**: Acompanhar primeiros ciclos
5. **Validar workflow**: Testar com uma action real

---

**Data**: 2025-11-28  
**Autor**: AI Assistant  
**Status**: Implementado e pronto para teste