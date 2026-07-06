# 🚀 Guia de Integração - Shell Module

Este documento explica como integrar o novo sistema modular de shell no NixOS.

## 📋 Sumário

- [Arquivos Criados](#arquivos-criados)
- [Passo a Passo de Integração](#passo-a-passo-de-integração)
- [Validação](#validação)
- [Rollback (se necessário)](#rollback-se-necessário)
- [Migração de Home-Manager](#migração-de-home-manager)

---

## 📁 Arquivos Criados

```
/etc/nixos/modules/shell/
├── default.nix                          # ✅ Orquestrador principal
├── gpu-flags.nix                        # ✅ Flags GPU testadas (centralizadas)
├── aliases/
│   └── docker-build.nix                 # ✅ Aliases Docker build/run
├── scripts/
│   └── python/
│       ├── gpu_monitor.py               # ✅ Monitor GPU avançado
│       └── model_manager.py             # ✅ Gerenciador de modelos AI
├── INTEGRATION.md                       # ✅ Este arquivo
└── README.md                            # ✅ Documentação (criada pelo default.nix)
```

---

## 🔧 Passo a Passo de Integração

### **Passo 1: Backup da Configuração Atual**

```bash
# Backup completo
cd /etc/nixos
sudo cp -r . ~/nixos-backup-$(date +%Y%m%d-%H%M%S)

# Backup específico do configuration.nix
sudo cp hosts/kernelcore/configuration.nix hosts/kernelcore/configuration.nix.backup
```

### **Passo 2: Editar Configuration.nix**

Abra o arquivo de configuração principal:

```bash
sudo nvim /etc/nixos/hosts/kernelcore/configuration.nix
```

**Adicione a importação** do novo módulo shell:

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    # ... outras importações existentes ...

    # ===== NOVO MÓDULO SHELL =====
    ../../modules/shell  # Adicione esta linha
  ];

  # ... resto da configuração ...
}
```

**Localização exata**: Adicione na seção `imports` junto com os outros módulos.

### **Passo 3: Verificar Permissões dos Scripts**

```bash
# Tornar scripts Python executáveis
sudo chmod +x /etc/nixos/modules/shell/scripts/python/*.py

# Verificar
ls -la /etc/nixos/modules/shell/scripts/python/
```

Output esperado:
```
-rwxr-xr-x 1 root root ... gpu_monitor.py
-rwxr-xr-x 1 root root ... model_manager.py
```

### **Passo 4: Validar Sintaxe Nix (IMPORTANTE)**

Antes de fazer rebuild, valide a sintaxe:

```bash
# Testa sintaxe sem aplicar mudanças
sudo nix-instantiate --parse /etc/nixos/modules/shell/default.nix

# Se retornar sem erros, prossiga
# Se houver erro, corrija antes de continuar
```

### **Passo 5: Build (Teste sem Ativar)**

```bash
# Build sem ativar (teste seguro)
sudo nixos-rebuild build --flake /etc/nixos#kernelcore

# Se build for bem-sucedido:
echo "✓ Build OK! Pronto para switch"

# Se falhar:
echo "✗ Build falhou. Verifique erros acima"
```

### **Passo 6: Switch (Ativar Nova Configuração)**

```bash
# Apply a nova configuração
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore

# Aguarde conclusão (pode demorar alguns minutos)
```

### **Passo 7: Recarregar Shell**

```bash
# Recarrega variáveis de ambiente
source /etc/profile

# Ou abra um novo terminal
exec bash
```

---

## ✅ Validação

### **1. Verificar Aliases Docker**

```bash
# Teste alias básico
dbuild --help

# Teste função
type dbuild-tag
# Output esperado: dbuild-tag is a function

# Teste GPU flags
echo $DOCKER_GPU_FLAGS
# Output esperado: --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g
```

### **2. Verificar Scripts Python**

```bash
# GPU Monitor
gpu-monitor-summary
# Output esperado: GPU summary com temperatura, uso, etc.

# Model Manager
model-list
# Output esperado: Lista de modelos instalados (pode estar vazia)
```

### **3. Testar GPU**

```bash
# Teste rápido GPU
dgpu-test
# Output esperado: "CUDA available: True" + nome da GPU
```

### **4. Testar Docker GPU**

```bash
# Run PyTorch com GPU
drun-gpu-workspace pytorch/pytorch:latest python -c "import torch; print(torch.cuda.is_available())"
# Output esperado: True
```

### **5. Verificar Help**

```bash
# Shell help
shell-help
# Output esperado: Lista de comandos disponíveis

# Docker functions help (embedded no arquivo)
type drun-gpu-port
# Output esperado: função definida
```

---

## 🔙 Rollback (Se Necessário)

Se algo der errado, você pode reverter:

### **Opção 1: Rollback via NixOS**

```bash
# Lista gerações
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback para geração anterior
sudo nixos-rebuild switch --rollback

# Reinicia shell
exec bash
```

### **Opção 2: Remover Módulo Manualmente**

```bash
# Editar configuration.nix
sudo nvim /etc/nixos/hosts/kernelcore/configuration.nix

# Remover linha:
# ../../modules/shell

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

### **Opção 3: Restaurar Backup**

```bash
# Restaurar configuration.nix do backup
sudo cp ~/nixos-backup-XXXXXXXX/hosts/kernelcore/configuration.nix /etc/nixos/hosts/kernelcore/configuration.nix

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore
```

---

## 🏠 Migração de Home-Manager (Opcional)

### **Situação Atual**

Aliases estão em **dois lugares**:
1. `hosts/kernelcore/home/aliases/` (home-manager)
2. `modules/shell/` (novo sistema kernel-level)

### **Proposta de Migração**

#### **Opção A: Dual-Mode (Recomendado no início)**

Mantenha ambos temporariamente para validação:

```nix
# home.nix - Manter aliases de desenvolvimento pessoal
bashrcExtra = ''
  # Aliases pessoais (git, navegação, etc.)
  source ~/.config/NixHM/aliases/dev-personal.sh

  # Sistema já carrega automaticamente:
  # - GPU/Docker aliases (kernel-level)
  # - Scripts Python (system-wide)
'';
```

#### **Opção B: Full Migration (após validação)**

Após confirmar que tudo funciona, remova duplicatas do home-manager:

1. **Identificar aliases duplicados**:
   ```bash
   # Comparar aliases
   comm -12 \
     <(grep -o "^alias [^=]*" /etc/nixos/hosts/kernelcore/home/aliases/*.sh | sort) \
     <(grep -o "^alias [^=]*" /etc/profile.d/*.sh | sort)
   ```

2. **Remover do home.nix**:
   ```nix
   # Comentar imports de aliases que já estão no kernel
   # bashrcExtra = ''
   #   source ~/.config/NixHM/aliases/gpu-docker-core.sh  # Agora no kernel
   #   source ~/.config/NixHM/aliases/ai-ml-stack.sh      # Agora no kernel
   # '';
   ```

3. **Rebuild home-manager**:
   ```bash
   home-manager switch --flake ~/.config/NixHM#kernelcore
   ```

---

## 📊 Checklist Final

Após integração, confirme:

- [ ] `sudo nixos-rebuild switch` executou sem erros
- [ ] `dbuild --help` funciona
- [ ] `drun-gpu` funciona
- [ ] `gpu-monitor-summary` mostra info da GPU
- [ ] `model-list` executa (mesmo que vazio)
- [ ] `shell-help` mostra comandos
- [ ] `dgpu-test` retorna "CUDA available: True"
- [ ] Flags GPU: `echo $DOCKER_GPU_FLAGS` mostra flags corretas
- [ ] Aliases antigos ainda funcionam (se mantidos no home-manager)

---

## 🆘 Troubleshooting

### Problema: "command not found: dbuild"

**Solução**:
```bash
# Recarregar perfil
source /etc/profile
exec bash
```

### Problema: "python3: No such file or directory"

**Solução**:
```bash
# Verificar se Python está instalado
which python3

# Se não estiver, adicione ao configuration.nix:
environment.systemPackages = [ pkgs.python3 ];
```

### Problema: "nvidia-smi: command not found"

**Solução**:
```bash
# Verificar drivers NVIDIA
lsmod | grep nvidia

# Se não aparecer nada, instale drivers NVIDIA
# (fora do escopo deste guia)
```

### Problema: Scripts Python não executam

**Solução**:
```bash
# Verificar permissões
ls -la /etc/nixos-shell/scripts/*.py

# Tornar executável
sudo chmod +x /etc/nixos-shell/scripts/*.py
```

---

## 📚 Próximos Passos

Após integração bem-sucedida:

1. **Teste todos aliases Docker** no dia-a-dia
2. **Valide flags GPU** em workflows reais
3. **Documente problemas encontrados**
4. **Após 1 semana de validação**, considere migrar aliases do home-manager
5. **Adicione novos scripts Python** conforme necessário

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique logs: `journalctl -xe`
2. Verifique Docker: `docker info`
3. Verifique GPU: `nvidia-smi`
4. Rollback se necessário (instruções acima)

---

**Última atualização**: $(date +%Y-%m-%d)
**Versão**: 1.0
**Status**: Pronto para produção
