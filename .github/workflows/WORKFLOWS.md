# GitHub Actions Workflows - NixOS Repository

> Renamed from `README.md` to `WORKFLOWS.md` so GitHub's directory rendering
> does not shadow the repository root `README.md`. See the root
> [README.md](../../README.md) and [.github/CI-CD.md](../CI-CD.md) for catalog
> and quick start.

## Workflows Disponíveis

### 1. `ci-observability.yml` - Observabilidade e Debug Completo
Workflow reutilizável com observabilidade completa e debug remoto via tmate.

**Funcionalidades**:
- **tmate Debug Session** - Acesso SSH remoto para debug
- **Métricas Detalhadas** - Build time, store size, memory usage
- **Logs Estruturados** - JSON metrics + HTML reports
- **Notificações Instantâneas** - Discord, Telegram, Slack
- **Build Analytics** - Performance tracking

**Como usar**:

#### Opção 1: Workflow Dispatch (Manual)
```bash
# Ir para Actions > CI Observability & Debug > Run workflow
- Enable tmate: true (para debug antes do build)
- Test notifications: true (para testar notificações)
```

#### Opção 2: Como Workflow Reutilizável
```yaml
jobs:
  my-build:
    uses: ./.github/workflows/ci-observability.yml
    with:
      enable-tmate: false          # true para sempre habilitar
      tmate-on-failure: true       # Habilita tmate apenas em falha
    secrets:
      DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
      TELEGRAM_BOT_TOKEN: ${{ secrets.TELEGRAM_BOT_TOKEN }}
      TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

---

### 2. `nixos-build.yml` - Build Principal
Build e teste do NixOS com suporte a tmate.

**Inputs**:
- `enable-tmate`: Habilita sessão tmate antes do build
- `tmate-on-failure`: Habilita tmate apenas em caso de falha

**Como usar**:
```bash
# Via GitHub UI:
Actions > NixOS Build & Test > Run workflow
- enable-tmate: true (para debug)
- tmate-on-failure: true (apenas em falha)
```

---

### 3. `pr-validation.yml` - Validação de PRs
Workflow reutilizável para validação de Pull Requests.

---

## Como Usar tmate para Debug

### O que é tmate?
tmate cria uma sessão SSH reversa que permite acesso remoto ao runner do GitHub Actions para debug em tempo real.

### Quando Usar?
- Build falhando e precisa investigar
- Testar comandos interativamente
- Inspecionar estado do sistema
- Debug de problemas específicos de CI

### Passo a Passo:

#### 1. Habilitar tmate
```bash
# Opção A: Via Workflow Dispatch
Actions > [Workflow] > Run workflow > enable-tmate: true

# Opção B: Via Git Push com tmate
git commit --allow-empty -m "debug: enable tmate [tmate]"
git push
```

#### 2. Aguardar Sessão Iniciar
O workflow vai pausar e exibir:
```
Setting up tmate session...

SSH: ssh XYZ@nyc1.tmate.io
Web: https://tmate.io/t/XYZ
```

#### 3. Conectar via SSH
```bash
# Copiar comando SSH dos logs do Actions
ssh XYZ@nyc1.tmate.io
```

#### 4. Debug Interativo
```bash
# Você está agora no runner!
# Exemplos de comandos úteis:

# Ver ambiente
env | grep GITHUB

# Testar build manualmente
nix build .#nixosConfigurations.kernelcore.config.system.build.toplevel --show-trace

# Ver logs
cat build.log | less

# Inspecionar store
nix-store --query --tree /nix/store/...

# Testar comando específico
nix eval .#nixosConfigurations.kernelcore.config.system.build.toplevel.drvPath
```

#### 5. Encerrar Sessão
```bash
# Opção A: Sair normalmente (workflow continua)
exit

# Opção B: Cancelar workflow (Actions > Cancel)
```

### Importante:
- **Segurança**: Sessão limitada ao actor (só você pode conectar)
- **Timeout**: 30 minutos máximo
- **Acesso**: Apenas com autenticação GitHub
- **Logs**: Tudo é logado no GitHub Actions

---

## Configurar Notificações

### Discord

1. Criar Webhook:
   - Server Settings > Integrations > Webhooks > New Webhook
   - Copiar Webhook URL

2. Adicionar Secret:
   ```bash
   # Repo > Settings > Secrets and Variables > Actions > New secret
   Name: DISCORD_WEBHOOK
   Value: https://discord.com/api/webhooks/...
   ```

### Telegram

1. Criar Bot:
   ```bash
   # Conversar com @BotFather no Telegram
   /newbot
   # Copiar token
   ```

2. Obter Chat ID:
   ```bash
   # Enviar mensagem para o bot
   # Acessar: https://api.telegram.org/bot<TOKEN>/getUpdates
   # Copiar "chat": {"id": 123456789}
   ```

3. Adicionar Secrets:
   ```bash
   TELEGRAM_BOT_TOKEN: <bot-token>
   TELEGRAM_CHAT_ID: <chat-id>
   ```

### Slack

1. Criar Incoming Webhook:
   - Your Apps > Create New App > Incoming Webhooks
   - Copiar Webhook URL

2. Adicionar Secret:
   ```bash
   SLACK_WEBHOOK: https://hooks.slack.com/services/...
   ```

---

## Métricas e Relatórios

### Métricas Coletadas:
- **Build Duration**: Tempo de build em segundos
- **Store Size**: Tamanho do /nix/store
- **Memory Usage**: Memória utilizada
- **Disk Usage**: Espaço em disco usado
- **Error Count**: Número de erros encontrados
- **Log Size**: Tamanho dos logs de build

### Acessar Relatórios:

1. **Via Artifacts**:
   ```
   Actions > [Workflow Run] > Artifacts
   - build-artifacts-XXX (logs + metrics.json)
   - observability-report-XXX (relatório HTML)
   ```

2. **Métricas JSON**:
   ```bash
   # Download metrics.json e visualizar
   cat metrics.json | jq '.'
   ```

3. **Relatório HTML**:
   ```bash
   # Download report.html e abrir no navegador
   # Contém gráficos interativos e métricas
   ```

---

## Exemplos de Uso

### Exemplo 1: Debug de Build Falhando
```bash
# 1. Workflow falhou
# 2. tmate-on-failure ativado automaticamente
# 3. Conectar via SSH (ver logs do Actions)
# 4. Investigar erro:
nix build .#nixosConfigurations.kernelcore --show-trace
# 5. Fixar problema localmente
# 6. Exit e commit fix
```

### Exemplo 2: Testar Nova Feature
```bash
# 1. Push branch com nova feature
# 2. Run workflow with tmate enabled
# 3. Conectar e testar interativamente:
nix eval .#nixosConfigurations.kernelcore.config.my.new.feature
# 4. Validar comportamento
# 5. Exit e ajustar se necessário
```

### Exemplo 3: Performance Profiling
```bash
# 1. Run workflow com observabilidade
# 2. Revisar métricas:
cat metrics.json | jq '.build_duration_seconds'
# 3. Comparar com runs anteriores
# 4. Identificar regressões
```

---

## Troubleshooting

### tmate Não Conecta
```bash
# Verificar:
1. Sessão expirou? (30 min timeout)
2. Workflow cancelado?
3. SSH key correto?
4. Firewall bloqueando porta 22?

# Alternativa: Usar Web Shell
https://tmate.io/t/XYZ
```

### Notificações Não Funcionam
```bash
# Verificar:
1. Secrets configurados corretamente?
2. Webhook URL válido?
3. Token/Chat ID corretos?
4. Verificar logs do workflow
```

### Build Muito Lento
```bash
# Otimizações:
1. Usar Cachix (já configurado)
2. Reduzir max-jobs
3. Usar build remoto
4. Profiles de observabilidade
```

---

## Recursos

- [tmate Documentation](https://tmate.io/)
- [GitHub Actions tmate Action](https://github.com/mxschmitt/action-tmate)
- [NixOS Manual - CI/CD](https://nixos.org/manual/nixos/stable/#sec-building-cd)
- [Cachix Documentation](https://docs.cachix.org/)

---

## Roadmap

### Próximas Features:
- [ ] Grafana Dashboard para métricas
- [ ] Prometheus metrics export
- [ ] Loki log aggregation
- [ ] Build performance trends
- [ ] Flake lock diff analyzer
- [ ] Dependency graph visualization
- [ ] Security vulnerability scanning
- [ ] Auto-rollback on failure

---

**Última Atualização**: 2026-05-13
**Mantido por**: kernelcore
