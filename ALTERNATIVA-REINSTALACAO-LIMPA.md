# 🔄 Alternativa: Reinstalação Limpa com Offload desde o Início

**Situação**: Disco 91% cheio (394GB usados) e considerando formatar  
**Alternativa Melhor**: Reinstalação mínima com desktop offload configurado desde o início

---

## 🎯 Por Que Reinstalar em Vez de Limpar?

### Vantagens da Reinstalação Limpa:
- ✅ Sistema limpo (10-30GB inicial)
- ✅ Offload configurado DESDE O INÍCIO
- ✅ Sem acúmulo de lixo histórico
- ✅ Configuração otimizada
- ✅ Backup de configs importantes no desktop

### Vs Limpeza Atual:
- ⚠️ Ainda tem 394GB usados (origem desconhecida)
- ⚠️ Possível fragmentação/problemas ocultos
- ⚠️ Limpeza pode não liberar espaço suficiente

---

## 📋 PLANO: Reinstalação Mínima com Offload

### Fase 1: Backup (NO DESKTOP via SSH)

```bash
# 1. Conectar ao desktop
ssh cypher@192.168.15.7

# 2. Criar diretório de backup no desktop
mkdir -p ~/backup-laptop-$(date +%Y%m%d)
cd ~/backup-laptop-$(date +%Y%m%d)

# 3. Copiar configuração do laptop para desktop
scp -r kernelcore@192.168.15.8:/etc/nixos ./nixos-config
scp -r kernelcore@192.168.15.8:~/.ssh ./ssh-keys
scp -r kernelcore@192.168.15.8:~/.config ./user-config

# 4. Listar pacotes instalados do laptop
ssh kernelcore@192.168.15.8 'nix-env -q' > installed-packages.txt

# 5. Backup de dados pessoais (ajuste conforme necessário)
scp -r kernelcore@192.168.15.8:~/Documents ./documents
scp -r kernelcore@192.168.15.8:~/Projects ./projects
```

---

### Fase 2: Preparar Desktop como Build Server

**NO DESKTOP**, adicionar ao `/etc/nixos/hosts/kernelcore/configuration.nix`:

```nix
# Build server para laptop
services.offload-server = {
  enable = true;
  cachePort = 5000;
  builderUser = "nix-builder";
  enableNFS = true;  # Compartilhar /nix/store
};
```

```bash
# Aplicar
sudo nixos-rebuild switch

# Gerar chaves
offload-generate-cache-keys

# Copiar chave pública (você vai precisar depois)
cat /var/cache-pub-key.pem
```

---

### Fase 3: Reinstalar Laptop (Configuração Mínima)

#### ISO de Instalação

Use o ISO mínimo do NixOS 25.05 (ou unstable)

#### Durante Instalação - configuration.nix MÍNIMO:

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "kernelcore";
  networking.networkmanager.enable = true;

  # User
  users.users.kernelcore = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  # System
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  # OFFLOAD CLIENT (configurado desde o início!)
  nix.settings = {
    max-jobs = 2;  # Apenas 2 jobs locais
    builders = [
      "ssh://nix-builder@192.168.15.7 x86_64-linux /etc/nix/builder_key 8 1"
    ];
    substituters = [
      "http://192.168.15.7:5000"  # Desktop cache primeiro
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "COLE_CHAVE_DO_DESKTOP_AQUI"
    ];
  };

  # SSH
  services.openssh.enable = true;

  # Pacotes essenciais MÍNIMOS
  environment.systemPackages = with pkgs; [
    vim git wget curl
  ];
}
```

#### Após Primeira Boot:

```bash
# 1. Configurar chave SSH para builds
sudo mkdir -p /etc/nix
sudo ssh-keygen -t ed25519 -f /etc/nix/builder_key -N ""
ssh-copy-id -i /etc/nix/builder_key.pub nix-builder@192.168.15.7

# 2. Testar conexão
ssh -i /etc/nix/builder_key nix-builder@192.168.15.7 'echo OK'

# 3. Clonar configs do backup (do desktop)
git clone ssh://cypher@192.168.15.7/~/backup-laptop-YYYYMMDD/nixos-config /etc/nixos-old

# 4. Migrar configs gradualmente conforme necessário
```

---

### Fase 4: Sistema Pós-Reinstalação

#### Uso de Disco Esperado:

```
Imediatamente após instalação:
/nix/store: 5-10GB
Total usado: 15-20GB
Livre: 430-440GB ✅✅✅

Após adicionar seus programas essenciais:
/nix/store: 20-30GB (builds vêm do desktop!)
Total usado: 40-50GB
Livre: 400-410GB ✅✅

A longo prazo (com offload ativo):
/nix/store: 30-50GB (estável)
Total usado: 60-80GB
Livre: 370-390GB ✅
```

---

## 🆚 Comparação: Limpar vs Reinstalar

### Opção A: Limpar Atual
```
Tempo: 2-4 horas
Espaço liberado: 50-150GB (incerto)
Resultado: 200-300GB usados
Risco: Problemas ocultos permanecem
Offload: Precisa configurar depois
```

### Opção B: Reinstalar Limpo
```
Tempo: 3-5 horas (incluindo backup)
Espaço liberado: 350GB+
Resultado: 40-80GB usados
Risco: Sistema novo, sem problemas
Offload: Configurado DESDE O INÍCIO ✅
```

---

## 🔧 Opção C: Limpeza Agressiva (Última Tentativa)

Se preferir NÃO reinstalar, tente isso:

```bash
# 1. Verificar o que está ocupando espaço
sudo du -sh /nix/store
sudo du -sh /var
sudo du -sh /home
sudo du -sh /tmp

# 2. Limpeza agressiva
sudo nix-collect-garbage -d
sudo nix-store --gc
sudo nix-store --optimise

# 3. Limpar Docker (se tiver)
docker system prune -a --volumes

# 4. Limpar logs
sudo journalctl --vacuum-time=7d
sudo rm -rf /var/log/*.old
sudo rm -rf /var/log/*.gz

# 5. Limpar cache do usuário
rm -rf ~/.cache/*
rm -rf ~/.local/share/Trash/*

# 6. Verificar resultado
df -h /
```

**Esperado**: Liberar 50-200GB

---

## 💡 Minha Recomendação

Dado que:
- Você tem 394GB usados (origem incerta)
- Apenas 1 geração do sistema (já está limpo de gerações)
- Está considerando formatar de qualquer forma
- Desktop disponível para offload

**Recomendo: Reinstalação Limpa (Opção B)**

Vantagens:
1. Sistema fresco e otimizado
2. Offload desde o início
3. ~400GB livres imediatamente
4. Sem mistérios sobre uso de disco
5. Configuração moderna e limpa

---

## 📋 Checklist de Decisão

### Antes de Decidir, Teste:

```bash
# 1. Ver o que está ocupando espaço
sudo du -h --max-depth=1 / 2>/dev/null | sort -h | tail -20

# 2. Se /nix/store é >300GB:
sudo du -sh /nix/store

# 3. Tentar limpeza agressiva (Opção C)
sudo nix-collect-garbage -d && sudo nix-store --gc

# 4. Ver quanto liberou
df -h /
```

Se após Opção C ainda tiver <100GB livres → **Reinstalar (Opção B)**  
Se liberou >150GB → **Continuar e configurar offload**

---

## 🚀 Próximos Passos

**Escolha seu caminho:**

### Path A: Reinstalar Limpo
1. Seguir Fase 1 (Backup no desktop)
2. Seguir Fase 2 (Preparar desktop)
3. Seguir Fase 3 (Reinstalar laptop)
4. Sistema limpo com 400GB+ livres ✅

### Path B: Limpar Agressivo
1. Executar Opção C (comandos de limpeza)
2. Se funcionar: configurar offload via [`EXECUTAR-AGORA.md`](EXECUTAR-AGORA.md)
3. Se não funcionar: voltar ao Path A

---

**Qual caminho prefere? Posso ajudar com qualquer um deles.**