# 🖥️ DESKTOP - Builder User Setup

**Localização:** Desktop (192.168.15.6)
**Objetivo:** Criar usuário nix-builder e autorizar laptop para builds remotos

## ✅ Tarefas

### 1. Verificar se usuário nix-builder existe

```bash
# Verificar
id nix-builder 2>/dev/null && echo "✅ Usuário existe" || echo "❌ Usuário não existe"

# Ver grupos Nix
getent group nixbld
```

### 2. Criar usuário nix-builder (se não existir)

```bash
# Criar usuário com home directory
sudo useradd -m -s /bin/bash -c "Nix Remote Builder" nix-builder

# Verificar criação
id nix-builder
ls -la /home/nix-builder/
```

### 3. Configurar SSH para o usuário

```bash
# Criar diretório SSH
sudo mkdir -p /home/nix-builder/.ssh
sudo chmod 700 /home/nix-builder/.ssh

# Criar arquivo authorized_keys
sudo touch /home/nix-builder/.ssh/authorized_keys
sudo chmod 600 /home/nix-builder/.ssh/authorized_keys

# Verificar
ls -la /home/nix-builder/.ssh/
```

### 4. Adicionar public key do LAPTOP

⚠️ **AGUARDAR LAPTOP GERAR A CHAVE PÚBLICA**

Quando o laptop fornecer a chave (formato: `ssh-ed25519 AAAA... nix-builder@laptop-to-desktop`):

```bash
# Adicionar a chave (SUBSTITUA pela chave real!)
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxx nix-builder@laptop-to-desktop" | sudo tee -a /home/nix-builder/.ssh/authorized_keys

# Ajustar dono dos arquivos
sudo chown -R nix-builder:nix-builder /home/nix-builder/.ssh

# Verificar
sudo cat /home/nix-builder/.ssh/authorized_keys
```

### 5. Adicionar aos grupos necessários

```bash
# Adicionar ao grupo nixbld (se existir)
sudo usermod -aG nixbld nix-builder 2>/dev/null || echo "Grupo nixbld não existe (normal em alguns setups)"

# Adicionar ao grupo wheel (opcional, para sudo se necessário)
# sudo usermod -aG wheel nix-builder

# Verificar grupos
id nix-builder
```

### 6. Configurar trusted-users no Nix (IMPORTANTE!)

```bash
# Verificar configuração atual
grep trusted-users /etc/nix/nix.conf 2>/dev/null || echo "Não configurado ainda"

# Se nix-builder não estiver listado, adicionar:
# Isso deve estar em /etc/nixos/configuration.nix ou módulo equivalente
```

**Para NixOS:** Adicione no seu `configuration.nix`:
```nix
nix.settings.trusted-users = [ "root" "@wheel" "nix-builder" ];
```

Depois rode:
```bash
sudo nixos-rebuild switch
```

### 7. Testar acesso SSH (depois que laptop criar chave)

```bash
# No DESKTOP, aguardar tentativa de conexão do laptop
# Monitorar logs SSH:
sudo journalctl -f -u sshd

# Deve aparecer algo como:
# Accepted publickey for nix-builder from 192.168.15.XXX port XXXXX
```

### 8. Verificar serviços necessários

```bash
# Verificar se SSH está rodando
systemctl status sshd

# Verificar se Nix daemon está rodando
systemctl status nix-daemon

# Verificar se cache HTTP está servindo
curl -I http://localhost:5000/nix-cache-info

# Verificar se NFS está exportando (se aplicável)
showmount -e localhost 2>/dev/null || echo "NFS não configurado"
```

## 🎯 Resultado Esperado

Quando laptop conectar:
```bash
# No laptop deve funcionar:
# ssh -i /etc/nix/builder_key nix-builder@192.168.15.6 'echo test'
```

Logs no desktop devem mostrar:
```
Accepted publickey for nix-builder from 192.168.15.XXX
```

---

## 🔍 Debugging

Se falhar:

```bash
# Ver logs SSH em tempo real
sudo journalctl -f -u sshd

# Ver tentativas de autenticação
sudo tail -f /var/log/auth.log   # ou
sudo journalctl -u sshd | tail -20

# Testar configuração SSH
sudo sshd -T | grep -i permit

# Verificar firewall
sudo iptables -L -n -v | grep 22
```

---

**Status:** ⏳ Aguardando public key do laptop
