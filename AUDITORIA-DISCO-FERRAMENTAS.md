# 🔍 Ferramentas de Auditoria de Disco - Guia Completo

**Objetivo**: Identificar exatamente o que está ocupando os 394GB do seu laptop antes de formatar

---

## 🛠️ Ferramentas Disponíveis

### 1. Script Customizado (Mais Completo) ⭐

**Arquivo**: [`scripts/auditoria-disco.sh`](scripts/auditoria-disco.sh)

**O que faz**:
- Analisa TODO o sistema
- Top 30 maiores diretórios
- Breakdown detalhado do `/nix/store`
- Top 20 maiores pacotes individuais
- Análise de `/home`, `/var`, logs
- Gerações do sistema NixOS
- GC roots (o que impede limpeza)
- Top 50 maiores arquivos (>100MB)
- Gera relatório em texto

**Como usar**:
```bash
cd /etc/nixos
./scripts/auditoria-disco.sh
```

**Tempo**: 5-10 minutos (análise completa)  
**Output**: Arquivo `auditoria-disco-YYYYMMDD-HHMMSS.txt`

**Vantagens**:
- ✅ Análise completa e detalhada
- ✅ Relatório exportável
- ✅ Identifica exatamente quais pacotes ocupam espaço
- ✅ Mostra o que pode ser limpo

---

### 2. ncdu (NCurses Disk Usage) - Visual Interativo ⭐

**Screenshot ASCII**:
```
ncdu 1.15.1 ~ Use the arrow keys to navigate, press ? for help
--- /nix/store ----------------------------------------------------------------
  310.0 GiB [##########] /nix/store
   50.0 GiB [#         ] /home
   30.0 GiB [          ] /var
    4.0 GiB [          ] /tmp
```

**Como usar**:
```bash
# Instalar temporariamente e executar
nix-shell -p ncdu --run 'sudo ncdu /'

# Ou analisar apenas /nix/store
nix-shell -p ncdu --run 'sudo ncdu /nix/store'
```

**Controles**:
- `↑↓`: Navegar entre diretórios
- `Enter`: Entrar em diretório
- `d`: Deletar item (cuidado!)
- `q`: Sair
- `?`: Ajuda

**Vantagens**:
- ✅ Interface visual clara
- ✅ Navegação fácil
- ✅ Mostra percentuais
- ✅ Pode deletar arquivos diretamente

**Tempo**: 2-5 minutos para escanear

---

### 3. dust (du + rust) - Moderno e Colorido

**Screenshot ASCII**:
```
 310G ┌─ /nix/store          │███████████████████████████████ │ 78%
  50G ├─ /home               │████████                        │ 12%
  30G ├─ /var                │█████                           │  8%
   4G └─ /tmp                │█                               │  1%
```

**Como usar**:
```bash
# Análise rápida com cores
nix-shell -p du-dust --run 'sudo dust /'

# Mais profundo (até 5 níveis)
nix-shell -p du-dust --run 'sudo dust -d 5 /'

# Apenas /nix/store
nix-shell -p du-dust --run 'sudo dust /nix/store'
```

**Vantagens**:
- ✅ Muito rápido
- ✅ Saída colorida e bonita
- ✅ Gráficos de barras
- ✅ Fácil de ler

**Tempo**: 30 segundos - 2 minutos

---

### 4. dua-cli (Disk Usage Analyzer) - Rápido e Interativo

**Como usar**:
```bash
# Modo interativo
nix-shell -p dua --run 'sudo dua interactive /'

# Apenas análise rápida
nix-shell -p dua --run 'sudo dua /'
```

**Controles no modo interativo**:
- `j/k`: Navegar
- `Enter`: Expandir
- `d`: Marcar para deletar
- `x`: Deletar marcados
- `q`: Sair

**Vantagens**:
- ✅ Muito rápido
- ✅ Modo interativo poderoso
- ✅ Pode marcar múltiplos arquivos para deletar
- ✅ Suporte a threads

**Tempo**: 30 segundos - 1 minuto

---

### 5. Comandos Nativos (Sem Instalar Nada)

#### 5.1. du (Disk Usage) - Básico
```bash
# Top 20 maiores diretórios
sudo du -h / 2>/dev/null | sort -rh | head -20

# Apenas /nix/store
sudo du -sh /nix/store

# Breakdown de /nix/store
sudo du -sh /nix/store/* | sort -rh | head -30
```

#### 5.2. find - Buscar Arquivos Grandes
```bash
# Arquivos maiores que 500MB
sudo find / -type f -size +500M -exec ls -lh {} \; 2>/dev/null

# Top 50 maiores arquivos
sudo find / -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -50
```

#### 5.3. df - Uso Geral
```bash
# Resumo de uso
df -h /

# Com inodes
df -ih /
```

---

## 📋 Workflow Recomendado

### Passo 1: Análise Rápida (2 minutos)
```bash
# Ver uso geral
df -h /

# Top diretórios rápido
sudo du -sh /* 2>/dev/null | sort -h | tail -10
```

### Passo 2: Análise Visual (5 minutos)
```bash
# ncdu para navegar visualmente
nix-shell -p ncdu --run 'sudo ncdu /'
```

**No ncdu**:
- Navegue até `/nix/store`
- Veja os maiores pacotes
- Identifique se há muito lixo

### Passo 3: Análise Detalhada (10 minutos)
```bash
# Script completo
cd /etc/nixos
./scripts/auditoria-disco.sh
```

Vai gerar relatório completo com:
- Tudo que está ocupando espaço
- Gerações antigas
- GC roots
- Recomendações

### Passo 4: Decisão

Com base na análise:

**Se `/nix/store` < 200GB**:
```bash
# Tentar limpeza agressiva
sudo nix-collect-garbage -d
sudo nix-store --optimise
```

**Se `/nix/store` > 200GB**:
```bash
# Provavelmente reinstalar é melhor opção
./scripts/backup-rapido.sh
# Seguir GUIA-BACKUP-E-REINSTALACAO.md
```

---

## 🎯 O Que Procurar na Auditoria

### Sinais de que `/nix/store` está inchado:

1. **Muitas gerações antigas** (>20)
   ```bash
   sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
   ```

2. **Pacotes duplicados/antigos**
   - Várias versões do mesmo pacote
   - Compiladores múltiplos (gcc-10, gcc-11, gcc-12)
   - Toolchains completos (rust, go, python)

3. **Grandes pacotes individuais** (>5GB cada)
   - Cuda toolkits
   - LLMs
   - Docker images empacotados

4. **GC roots problemáticos**
   - Muitos roots antigos protegendo lixo
   - Perfis de usuário com builds antigos

### Calculadora Rápida:

```
Uso Total: 394GB

Se encontrar:
- /nix/store: 300GB+ → Reinstalar é melhor
- /nix/store: 200-300GB → Tentar limpeza primeiro
- /nix/store: <200GB → Limpeza resolve
- /home: >50GB → Mover dados para desktop
- /var: >30GB → Limpar logs e docker
```

---

## 💡 Exemplos Práticos

### Exemplo 1: Identificar Compiladores
```bash
# Ver todos os gcc instalados
sudo ls -lh /nix/store | grep gcc | head -20

# Tamanho total de gcc
sudo du -sh /nix/store/*gcc* | sort -h
```

### Exemplo 2: Identificar Python Environments
```bash
# Ver todos os python
sudo ls -lh /nix/store | grep python3 | wc -l

# Tamanho total
sudo du -sh /nix/store/*python* | awk '{sum+=$1} END {print sum}'
```

### Exemplo 3: Identificar Builds Antigos
```bash
# Listar por data
sudo ls -lt /nix/store | head -50

# Pacotes mais antigos
sudo ls -lt /nix/store | tail -50
```

---

## 🚀 Execute Agora

### Opção A: Análise Completa (Recomendado)
```bash
cd /etc/nixos
./scripts/auditoria-disco.sh
```

### Opção B: Análise Visual Rápida
```bash
nix-shell -p ncdu --run 'sudo ncdu /'
```

### Opção C: Análise Colorida Moderna
```bash
nix-shell -p du-dust --run 'sudo dust -d 3 /'
```

---

## 📊 Interpretando Resultados

### Cenário 1: /nix/store = 250-300GB
**Causa provável**: Muitas gerações + toolchains completos  
**Solução**: Limpeza agressiva pode liberar 100-150GB  
**Ação**: `sudo nix-collect-garbage -d && sudo nix-store --optimise`

### Cenário 2: /nix/store = 300-350GB
**Causa provável**: Anos de acúmulo + compiladores + SDKs  
**Solução**: Limpeza libera 50-100GB mas volta a encher  
**Ação**: Considere reinstalação com offload

### Cenário 3: /nix/store > 350GB
**Causa provável**: Tudo acumulado sem limpeza periódica  
**Solução**: Reinstalação limpa é mais eficiente  
**Ação**: Backup + Reinstalar com offload desde início

---

## ✅ Checklist Pós-Auditoria

Após executar a auditoria, você terá:

- [ ] Tamanho exato do `/nix/store`
- [ ] Lista dos 20 maiores pacotes
- [ ] Número de gerações antigas
- [ ] Tamanho de `/home` e `/var`
- [ ] Identificação de logs grandes
- [ ] Decisão clara: Limpar ou Reinstalar

---

**Recomendação**: Execute `./scripts/auditoria-disco.sh` primeiro para ter relatório completo!