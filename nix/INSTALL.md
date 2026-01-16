# 🔧 Phoenix Aliases - Instalação NixOS

Aliases inteligentes para usar Phoenix de qualquer lugar do sistema.

---

## 🚀 INSTALAÇÃO RÁPIDA

### Método 1: Home-Manager (Recomendado)

Adicione ao seu `~/.config/home-manager/home.nix`:

```nix
{ config, pkgs, ... }:

{
  # Import phoenix aliases
  imports = [
    /home/kernelcore/dev/low-level/phoenix-cloud-run/nix/phoenix-aliases.nix
  ];

  # Environment variables (se não definido no import)
  home.sessionVariables = {
    ENGINE_ID = "seu-discovery-engine-id";  # IMPORTANTE: Set this!
  };
}
```

Depois:
```bash
home-manager switch
```

---

### Método 2: configuration.nix (System-wide)

Adicione ao seu `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    # ... outros imports
    /home/kernelcore/dev/low-level/phoenix-cloud-run/nix/phoenix-aliases.nix
  ];

  # Set ENGINE_ID para todos usuários (optional)
  environment.variables = {
    ENGINE_ID = "seu-discovery-engine-id";
  };
}
```

Depois:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 8 --cores 8
```

---

### Método 3: Shell RC direto (Sem Nix)

Se você quiser testar antes de adicionar ao Nix:

```bash
# Adicione ao ~/.bashrc ou ~/.zshrc
source /home/kernelcore/dev/low-level/phoenix-cloud-run/nix/phoenix-functions.sh
```

Crie `/home/kernelcore/dev/low-level/phoenix-cloud-run/nix/phoenix-functions.sh`:

```bash
#!/bin/bash
# Extract from phoenix-aliases.nix

# [Cole as funções do phoenixFunctions aqui]
```

---

## ⚙️ CONFIGURAÇÃO

### 1. Definir ENGINE_ID (OBRIGATÓRIO)

```bash
# Temporário (sessão atual)
export ENGINE_ID=seu-discovery-engine-id

# Permanente (adicionar ao shell config)
echo 'export ENGINE_ID=seu-discovery-engine-id' >> ~/.bashrc

# Via NixOS (recomendado)
# Adicione ao home.nix ou configuration.nix conforme acima
```

### 2. Configurar GCloud (One-time)

```bash
pxsetup
# Vai autenticar, enable APIs, etc
```

### 3. Testar

```bash
pxhelp
# Deve mostrar lista de comandos

pxst
# Deve mostrar credit status
```

---

## 📋 COMANDOS DISPONÍVEIS

### Queries (Core)

```bash
# Single query de qualquer lugar
pxq 'como configurar nvidia no nixos'

# Smart query (detecta contexto do dir)
cd ~/meu-projeto-rust
pxqs 'best practices for this project'
# Vai adicionar "Rust project context:" automaticamente

# Batch processing
pxb minhas_queries.txt 20

# Interactive mode
pxi
```

### Generation

```bash
# Generate queries
pxg 100                    # 100 queries
pxg 1000 custom.txt        # 1000 queries, custom output

# Specialized generators
pxsal 150000 300000        # Salary negotiation
pxtrend                    # Trend prediction
pxmoat                     # Personal moat
```

### Analysis

```bash
# Mine content
pxmine

# Strategy optimizer
pxopt

# Credit status
pxst

# List results
pxls              # Brief
pxls verbose      # With content preview

# Search results
pxfind 'nixos'
pxfind 'rust async'
```

### Workflows

```bash
# Daily digest (complete workflow)
pxdaily
# 1. Generates 50 queries
# 2. Processes them
# 3. Mines content
# 4. Shows status

# Setup GCloud
pxsetup
```

### Utils

```bash
# Navigate to phoenix dir
pxcd
px        # Alias

# Edit docs
pxedit                        # Opens EXECUTIVE_SUMMARY.md
pxedit HACKS_ROI.md          # Opens specific doc

# Quick view docs
pxdoc                         # Less EXECUTIVE_SUMMARY
pxhacks                       # Less HACKS_ROI
pxqueries                     # Less HIGH_ROI_QUERIES

# Help
pxhelp
pxh       # Alias
```

---

## 🎯 EXEMPLOS DE USO

### Exemplo 1: Query rápida sobre problema atual

```bash
# Você tá debugando algo
cd ~/projeto

# Query contexto-aware
pxqs 'por que esse erro de borrow checker'
# Detecta Rust, adiciona contexto automaticamente
```

### Exemplo 2: Research session

```bash
# Gerar queries sobre tópico
pxg 50 rust_async_queries.txt

# Editar/refinar queries
nvim rust_async_queries.txt

# Processar
pxb rust_async_queries.txt 10

# Ver resultados
pxls verbose

# Buscar específico
pxfind 'tokio'

# Transformar em content
pxmine
```

### Exemplo 3: Job search prep

```bash
# Generate salary negotiation intel
pxsal 150000 300000

# Wait for processing...

# Mine for content (prepare for interviews)
pxmine

# Check what you learned
pxfind 'google'
pxfind 'negotiation'
```

### Exemplo 4: Daily workflow

```bash
# Morning: Run daily digest
pxdaily

# Durante o dia: Queries ad-hoc
pxq 'kubernetes best practices 2025'
pxqs 'optimize this'  # From project dir

# Evening: Mine and plan content
pxmine
less content_output/content_calendar_30days.md
```

---

## 🔥 INTEGRATION HACKS

### Hack 1: Vim Integration

Adicione ao `~/.vimrc`:

```vim
" Phoenix query selected text
vnoremap <leader>pq :<C-u>!pxq '<C-r>"'<CR>

" Phoenix smart query sobre função atual
nnoremap <leader>pqs :!pxqs 'explain this function'<CR>
```

### Hack 2: Tmux Integration

Adicione ao `~/.tmux.conf`:

```bash
# Phoenix pane
bind-key P split-window -h "pxi"

# Quick status
bind-key S split-window -v "pxst; read"
```

### Hack 3: Git Hook Integration

`.git/hooks/pre-push`:

```bash
#!/bin/bash
# Auto-query sobre changes antes de push

git diff origin/main...HEAD > /tmp/changes.txt

pxq "Code review these changes: $(cat /tmp/changes.txt | head -n 50)"
```

### Hack 4: Systemd Timer (Daily auto-run)

`~/.config/systemd/user/phoenix-daily.service`:

```ini
[Unit]
Description=Phoenix Daily Digest

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash -c 'source ~/.bashrc && pxdaily'
```

`~/.config/systemd/user/phoenix-daily.timer`:

```ini
[Unit]
Description=Phoenix Daily Digest Timer

[Timer]
OnCalendar=daily
OnCalendar=06:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable:
```bash
systemctl --user enable --now phoenix-daily.timer
```

---

## 🐛 TROUBLESHOOTING

### "pxq: command not found"

```bash
# Check if sourced
type pxq

# Re-source
source ~/.bashrc  # ou ~/.zshrc

# If usando NixOS config
home-manager switch
# ou
sudo nixos-rebuild switch
```

### "ENGINE_ID not set"

```bash
# Check
echo $ENGINE_ID

# Set temporarily
export ENGINE_ID=seu-id

# Set permanently
echo 'export ENGINE_ID=seu-id' >> ~/.bashrc
source ~/.bashrc
```

### "gcloud not authenticated"

```bash
pxsetup
# Vai autenticar automaticamente
```

### Functions not working in fish shell

Fish tem sintaxe diferente. Use bash ou zsh, OU:

```bash
# Run via bash
bash -c 'pxq "query"'
```

---

## 📊 PERFORMANCE NOTES

### Command Performance

| Command | Speed | Notes |
|---------|-------|-------|
| `pxq` | 2-10s | Network call to GCP |
| `pxb` | Varies | Depends on workers and query count |
| `pxst` | 1-2s | BigQuery query |
| `pxls` | Instant | Local file list |
| `pxfind` | 1-5s | Local grep, depends on result count |
| `pxmine` | 5-30s | Depends on result files |

### Tips para Performance

1. **Use workers altos para batch:**
   ```bash
   pxb queries.txt 50  # Faster
   ```

2. **Cache results localmente:**
   ```bash
   # Results ficam em batch_results_*.json
   # Não precisa re-query, use pxfind
   ```

3. **pxqs vs pxq:**
   ```bash
   pxqs  # Ligeiramente mais lento (detecta contexto)
   pxq   # Direto
   ```

---

## 🎯 NEXT STEPS

1. **Instalar** (escolher método acima)
2. **Configurar ENGINE_ID**
3. **Testar:** `pxhelp && pxst`
4. **Primeira query:** `pxq 'test query'`
5. **Explorar workflows:** `pxdaily`

---

## 📚 DOCS RELACIONADAS

- **Full arsenal:** `scripts/README_ARSENAL.md`
- **Strategy:** `EXECUTIVE_SUMMARY.md`
- **Hacks:** `HACKS_ROI.md`
- **Queries prontas:** `HIGH_ROI_QUERIES.md`

---

**ALIASES INSTALADOS = PODER EM QUALQUER LUGAR DO SISTEMA** 🔥

Query from anywhere. Build knowledge moat. Make money.
