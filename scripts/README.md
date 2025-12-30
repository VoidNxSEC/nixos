# 🛠️ NixOS Maintenance Scripts

Coleção de scripts utilitários para manutenção e gerenciamento do sistema NixOS.

## 📦 Showcase Projects Management

### `sync-showcase-projects.sh`

**Propósito**: Automatiza git commit, push e flake update para todos os 16 projetos showcase declarados no `flake.nix`.

**Uso**:
```bash
cd /etc/nixos
sudo ./scripts/sync-showcase-projects.sh
```

**O que faz**:
1. Itera sobre todos os projetos em `~/dev/projects` declarados como inputs no flake
2. Para cada projeto:
   - Verifica se há mudanças (`git diff-index`)
   - Se houver: `git add .`, `git commit`, `git push` 
   - Sempre executa: `nix flake update`
3. Ao final, atualiza o `flake.lock` principal do `/etc/nixos`

**Output**:
- ✅ Com mudanças: Commita com mensagem `chore: sync showcase project - YYYY-MM-DD`
- ⏭️ Sem mudanças: Skip, mas ainda faz `flake update`
- ❌ Falhas: Reporta projetos que falharam

**Estatísticas**:
- Total de projetos processados
- Commits/pushes bem-sucedidos
- Skips (sem mudanças)
- Falhas

**Projetos processados**:
1. ml-offload-api
2. securellm-mcp
3. securellm-bridge
4. cognitive-vault
5. vmctl
6. spider-nix
7. i915-governor
8. swissknife
9. arch-analyzer
10. docker-hub
11. notion-exporter
12. nixos-hyperlab
13. shadow-debug-pipeline
14. ai-agent-os
15. phantom
16. O.W.A.S.A.K.A.

---

## 🔄 Workflow Recomendado

### Antes de um rebuild:
```bash
cd /etc/nixos
sudo ./scripts/sync-showcase-projects.sh  # Sync todos os projetos
nix flake update                           # Update dependências externas
sudo nixos-rebuild switch                  # Apply changes
```

### Deploy contínuo:
```bash
# Cron job (rodar diariamente às 3am):
0 3 * * * cd /etc/nixos && ./scripts/sync-showcase-projects.sh
```

---

## 📊 Exemplo de Output

```
🚀 Git Commit, Push and Flake Update for All Projects

════════════════════════════════════════════════
📦 Processing: nixos-hyperlab
════════════════════════════════════════════════
✓ Changes detected
  → git add .
  → git commit -m "chore: sync showcase project - 2025-12-30"
  ✓ Committed
  → git push
  ✓ Pushed to remote
  → nix flake update
  ✓ Flake updated

════════════════════════════════════════════════
📊 Summary
════════════════════════════════════════════════
Total projects:        16
Committed & pushed:     4
Skipped (no changes): 12
Failed:                 0

════════════════════════════════════════════════
🔄 Updating main flake.lock (/etc/nixos)
════════════════════════════════════════════════
  → n flake update
...

✅ All done!
```

---

## 🔐 Segurança

- Script requer acesso de escrita aos projetos em `~/dev/projects`
- Push automático pode falhar se não houver remote configurado (não é erro fatal)
- Commits são sempre locais, push é "best effort"

---

## 🐛 Troubleshooting

### "Directory not found"
- Projeto pode ter sido removido de `~/dev/projects`
- Atualizar lista no script se necessário

### "Not a git repository"
- Projeto precisa ter `.git` folder
- Inicializar com `git init` se necessário

### "Push failed (no remote configured?)"
- Projeto não tem remote git configurado
- Commit foi feito localmente com sucesso
- Configurar remote: `git remote add origin <url>`

---

**Última atualização**: 2025-12-30  
**Versão**: 1.0  
**Autor**: NixOS Showcase Infrastructure
