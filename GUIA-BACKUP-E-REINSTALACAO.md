# 🔄 Guia: Backup → Reinstalação → Offload Configurado

**Decisão**: Formatar laptop e começar limpo com offload desde o início ✅  
**Motivo**: 394GB ocupados (provavelmente compiladores e full stacks)  
**Resultado Final**: Sistema limpo com 40-60GB + offload para builds pesados

---

## 📦 FASE 1: BACKUP (Transferir para Desktop)

### Passo 1.1: Backup de Configurações (NO LAPTOP)

```bash
# 1. Criar pacote com suas configs
cd ~
tar czf nixos-config-backup-$(date +%Y%m%d).tar.gz \
  /etc/nixos \
  ~/.ssh \
  ~/.config \
  ~/.zshrc \
  ~/.bashrc \
  ~/.gitconfig

# 2. Transferir para desktop
scp nixos-config-backup-*.tar.gz cypher@192.168.15.7:~/backup-laptop/

# 3. Lista de pacotes instalados (para referência)
nix-env -q > ~/installed-packages.txt
cat /etc/nixos/hosts/kernelcore/configuration.nix > ~/current-config.nix
scp ~/installed-packages.txt ~/current-config.nix cypher@192.168.15.7:~/backup-laptop/
```

### Passo 1.2: Backup de Dados Pessoais

```bash
# Identifique seus diretórios importantes:
# - Projetos de código
# - Documentos
# - Dotfiles personalizados
# - Chaves/certificados privados

# Exemplo (ajuste conforme necessário):
cd ~
tar czf dados-pessoais-$(date +%Y%m%d).tar.gz \
  ~/Projects \
  ~/Documents \
  ~/Downloads/*.important \
  ~/.local/share/secrets

# Transferir para desktop
scp dados-pessoais-*.tar.gz cypher@192.168.15.7:~/backup-laptop/
```

### Passo 1.3: Backup de Secrets/Chaves

```bash
# Copiar chaves importantes
mkdir -p ~/backup-secrets
cp -r /etc/nixos/secrets ~/backup-secrets/
cp -r ~/.ssh ~/backup-secrets/
cp -r ~/.gnupg ~/backup-secrets/

# Transferir para desktop (CUIDADO - sensível!)
scp -r ~/backup-secrets cypher@192.168.15.7:~/backup-laptop/

# NO DESKTOP: Proteger backup
ssh cypher@192.168.15.7 'chmod 700 ~/backup-laptop/backup-secrets'
```

### Passo 1.4: Verificar Backup no Desktop

```bash
# Conectar ao desktop
ssh cypher@192.168.15.7

# Verificar arquivos
ls -lh ~/backup-laptop/
du -sh ~/backup-laptop/

# Descompactar um teste para verificar
tar tzf ~/backup-laptop/nixos-config-backup-*.tar.gz | head -20
```

---

## 🖥️ FASE 2: PREPARAR DESKTOP (Antes de Formatar Laptop)

### Passo 2.1: Habilitar Offload Server no Desktop

```bash
# NO DESKTOP (via SSH)
ssh cypher@192.168.15.7

# Editar configuração
sudo nano /etc/nixos/hosts/kernelcore/configuration.nix
```

**Adicionar antes da última linha `}`:**

```nix
  # ===== BUILD SERVER PARA LAPTOP =====
  services.offload-server = {
    enable = true;
    cachePort = 5000;
    builderUser = "nix-builder";
    enableNFS = true;  # Opcional: compartilhar /nix/store
  };

  # Abrir firewall para cache
  networking.firewall.allowedTCPPorts = [ 5000 ];
```

```bash
# Aplicar configuração
sudo nixos-rebuild switch

# Gerar chaves do cache
offload-generate-cache-keys

# COPIAR A CHAVE PÚBLICA (você vai precisar na reinstalação)
cat /var/cache-pub-key.pem
# Exemplo: cache.local:abc123xyz789...=

# Salvar em um arquivo para facilitar
cat /var/cache-pub-key.pem > ~/backup-laptop/cache-public-key.txt

# Verificar status
offload-server-status
```

---

## 💿 FASE 3: REINSTALAR LAPTOP (Sistema Mínimo + Offload)

### Passo 3.1: Instalar NixOS Básico

1. Boot do USB com NixOS ISO
2. Particionar disco (conforme preferência)
3. Instalar sistema básico

### Passo 3.2: Configuration.nix MÍNIMO com Offload

**`/etc/nixos/configuration.nix` após instalação:**

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ===== BOOT =====
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ===== NETWORK =====
  networking.hostName = "kernelcore";
  networking.networkmanager.enable = true;

  # ===== TIME =====
  time.timeZone = "America/Sao_Paulo";  # Ajuste conforme necessário

  # ===== USER =====
  users.users.kernelcore = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      # Adicionar sua chave SSH pública aqui
    ];
  };

  # ===== SSH =====
  services.openssh.enable = true;

  # ===== NIX SETTINGS =====
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    
    # OFFLOAD CONFIGURADO DESDE O INÍCIO!
    max-jobs = 2;  # Apenas 2 builds locais simultâneos
    
    # Desktop como build server
    builders = [
      "ssh://nix-builder@192.168.15.7 x86_64-linux /etc/nix/builder_key 8 1"
    ];
    
    # Desktop cache + oficial
    substituters = [
      "http://192.168.15.7:5000"
      "https://cache.nixos.org"
    ];
    
    # Chaves públicas (COLE A CHAVE DO DESKTOP AQUI)
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "COLE_AQUI_A_CHAVE_DO_DESKTOP"  # Do arquivo ~/backup-laptop/cache-public-key.txt
    ];
    
    # Otimizações
    builders-use-substitutes = true;
    connect-timeout = 2;
    fallback = true;
  };

  # ===== PACKAGES ESSENCIAIS MÍNIMOS =====
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    tmux
  ];

  # ===== SYSTEM =====
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
}
```

### Passo 3.3: Configurar Chave SSH para Builds

```bash
# Criar chave para builds remotos
sudo mkdir -p /etc/nix
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N ""

# Copiar chave pública para o desktop
ssh-copy-id -i /etc/nix/builder_key.pub nix-builder@192.168.15.7

# Testar conexão
ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 'echo "Build server OK!"'

# Aplicar configuração
sudo nixos-rebuild switch
```

### Passo 3.4: Testar Offload

```bash
# Verificar configuração
nix show-config | grep -E "^builders|^substituters"

# Teste de build remoto
nix-build '<nixpkgs>' -A hello --no-out-link

# Deve mostrar: "building on remote machine..."
```

---

## 🔄 FASE 4: RESTAURAR CONFIGS (Gradualmente)

### Passo 4.1: Recuperar Backup do Desktop

```bash
# Copiar backup do desktop para laptop
scp cypher@192.168.15.7:~/backup-laptop/nixos-config-backup-*.tar.gz ~/

# Extrair para análise
mkdir ~/backup-old
tar xzf nixos-config-backup-*.tar.gz -C ~/backup-old/
```

### Passo 4.2: Migrar Configs Importantes (Seletivamente)

```bash
# NÃO copie tudo! Migre seletivamente:

# 1. Configs de usuário
cp ~/backup-old/home/kernelcore/.zshrc ~/
cp ~/backup-old/home/kernelcore/.gitconfig ~/

# 2. Secrets importantes (se necessário)
sudo cp -r ~/backup-old/etc/nixos/secrets /etc/nixos/

# 3. SSH keys antigas
cp ~/backup-old/home/kernelcore/.ssh/id_* ~/.ssh/
chmod 600 ~/.ssh/id_*

# 4. Analisar configuration.nix antigo
# COPIAR apenas os APPS/CONFIGS que você realmente precisa
# NÃO copie compiladores/toolchains - deixe o desktop compilar!
vim ~/backup-old/etc/nixos/hosts/kernelcore/configuration.nix
```

### Passo 4.3: Adicionar Apps Essenciais (Apenas o que precisa)

Edite `/etc/nixos/configuration.nix` e adicione APENAS o necessário:

```nix
  environment.systemPackages = with pkgs; [
    # Essenciais
    vim git wget curl htop

    # Desenvolvimento (MÍNIMO - deixe compilação para o desktop)
    vscode
    # NÃO adicione: gcc, cmake, rust, go, etc.
    # Deixe o desktop compilar via offload!

    # Apps do dia-a-dia
    firefox
    # outros apps que você usa
  ];
```

---

## 📊 RESULTADO ESPERADO

### Comparação Antes vs Depois:

**ANTES (Sistema Antigo):**
```
/nix/store: ~300GB
Total usado: 394GB (91%)
Livre: 41GB
Compiladores: gcc, rust, go, python full, etc.
Builds: Locais e lentos
```

**DEPOIS (Sistema Novo com Offload):**
```
/nix/store: 20-30GB
Total usado: 40-60GB (10-15%)
Livre: 390-410GB ✅✅✅
Compiladores: NO DESKTOP (via offload)
Builds: Remotos e rápidos
```

### Uso a Longo Prazo:

```
Mês 1: 40-60GB (apenas essenciais)
Mês 3: 60-80GB (com alguns projetos)
Mês 6: 70-100GB (estável)
Permanente: <100GB (offload previne acúmulo)
```

---

## ✅ CHECKLIST COMPLETO

### Antes de Formatar:
- [ ] Backup de `/etc/nixos` no desktop
- [ ] Backup de `~/.ssh` no desktop
- [ ] Backup de projetos/documentos no desktop
- [ ] Backup de secrets/chaves no desktop
- [ ] Desktop com offload-server habilitado
- [ ] Chave pública do cache salva
- [ ] Testar acesso SSH ao desktop

### Durante Reinstalação:
- [ ] Particionar disco
- [ ] Instalar NixOS base
- [ ] Configurar offload no configuration.nix
- [ ] Colar chave pública do desktop
- [ ] Criar chave SSH para builds (`/etc/nix/builder_key`)
- [ ] Copiar chave para desktop
- [ ] `sudo nixos-rebuild switch`
- [ ] Testar build remoto

### Após Reinstalação:
- [ ] Recuperar backup do desktop
- [ ] Migrar configs seletivamente
- [ ] Adicionar apenas apps essenciais
- [ ] Testar offload: `nix-build '<nixpkgs>' -A hello`
- [ ] Verificar espaço: `df -h /`
- [ ] Sistema com >390GB livres ✅

---

## 💡 DICAS IMPORTANTES

### O Que NÃO Instalar no Laptop:

❌ **Compiladores completos** (gcc, clang)  
❌ **Toolchains** (rust, go, python full)  
❌ **Build tools** (cmake, ninja, make)  
❌ **SDKs pesados** (Android, Flutter)

**Por quê?** O desktop vai compilar tudo via offload!

### O Que Instalar no Laptop:

✅ **Editors/IDEs** (vscode, vim)  
✅ **Browsers** (firefox, chromium)  
✅ **Utils diários** (terminal, git client)  
✅ **Apps específicos** que você usa regularmente

### Fluxo de Trabalho Pós-Reinstalação:

1. Precisa de um pacote? Adicione ao `configuration.nix`
2. `sudo nixos-rebuild switch` → Build automático no desktop
3. Binário copiado para laptop via cache
4. Instante e sem ocupar espaço com dependências de build

---

## 🆘 TROUBLESHOOTING

### Se o offload não funcionar após reinstalação:

```bash
# 1. Verificar conectividade
ping 192.168.15.7

# 2. Testar SSH como nix-builder
ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 'echo OK'

# 3. Verificar cache
curl http://192.168.15.7:5000/nix-cache-info

# 4. Ver logs de build
nix-build '<nixpkgs>' -A hello --verbose

# 5. Rebuild local temporário (emergência)
sudo nixos-rebuild switch --option builders "" --option max-jobs auto
```

---

**PRONTO PARA COMEÇAR O BACKUP?**  
**Siga a Fase 1 → Fase 2 → Formatar → Fase 3 → Fase 4**

**Tempo total estimado**: 2-4 horas (incluindo instalação)  
**Resultado**: Sistema limpo com 400GB livres e builds automáticos no desktop ✅