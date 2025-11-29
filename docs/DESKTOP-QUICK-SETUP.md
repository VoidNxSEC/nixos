# Desktop Setup - Comandos Rápidos
## Execução via SSH Tunnel no Desktop (cypher@192.168.15.7)

> **Objetivo:** Configurar o desktop como servidor de builds  
> **Executar:** Via SSH tunnel já estabelecido

---

## 🚀 Setup Rápido - Desktop

### Passo 1: Verificar Estado Atual

```bash
# Verificar se offload-server está instalado
ls -la /etc/nixos/modules/services/offload-server.nix

# Verificar hostname e configuração atual
hostname
cat /etc/nixos/hosts/$(hostname)/configuration.nix | grep -A 5 "offload-server"
```

### Passo 2: Habilitar offload-server

**Editar o configuration.nix do desktop:**

```bash
# Encontrar o arquivo de configuração
sudo nano /etc/nixos/hosts/$(hostname)/configuration.nix
# OU
sudo nano /etc/nixos/configuration.nix
```

**Adicionar ou modificar:**

```nix
{
  # ... configuração existente ...
  
  services.offload-server = {
    enable = true;              # ← MUDAR PARA true
    cachePort = 5000;
    builderUser = "nix-builder";
    cacheKeyPath = "/var/cache-priv-key.pem";
    enableNFS = true;           # ← MUDAR PARA true (para NFS)
  };
  
  # Opcional: sudo passwordless para cypher
  security.sudo.extraRules = [{
    users = [ "cypher" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
```

### Passo 3: Rebuild

```bash
# Verificar sintaxe primeiro
sudo nixos-rebuild dry-build --flake /etc/nixos#$(hostname)

# Se OK, aplicar
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)

# OU se não usar flake:
sudo nixos-rebuild switch
```

### Passo 4: Gerar Chaves de Cache

```bash
# Após rebuild bem-sucedido
offload-generate-cache-keys
```

**IMPORTANTE:** Copie a linha que começa com `cache.local:` - você vai precisar no laptop!

Exemplo:
```
cache.local:02WKFpKSXrblw9GTALpIE9qAMu5oGebPfpCizFCwHWE=
```

### Passo 5: Verificar Status

```bash
offload-server-status
```

Deve mostrar:
- ✅ nix-serve: Running
- ✅ sshd: Running
- ✅ NFS: Running (se habilitado)

### Passo 6: Preparar para Chave SSH do Laptop

```bash
# Criar diretório SSH do builder
sudo mkdir -p /var/lib/nix-builder/.ssh
sudo chmod 700 /var/lib/nix-builder/.ssh
sudo touch /var/lib/nix-builder/.ssh/authorized_keys
sudo chmod 600 /var/lib/nix-builder/.ssh/authorized_keys
sudo chown -R nix-builder:nix-builder /var/lib/nix-builder/.ssh
```

### Passo 7: Aguardar Chave Pública do Laptop

O laptop vai gerar uma chave SSH. Quando você receber (formato `ssh-ed25519 AAAA...`), adicione:

```bash
# Adicionar chave pública do laptop (AGUARDAR O LAPTOP FORNECER)
echo "ssh-ed25519 AAAA... nix-builder@laptop-to-desktop" | \
  sudo tee -a /var/lib/nix-builder/.ssh/authorized_keys
```

### Passo 8: Verificar Firewall

```bash
# Verificar portas abertas
sudo iptables -L -n | grep -E '22|5000|2049|111'

# Se necessário, adicionar ao configuration.nix:
# networking.firewall.allowedTCPPorts = [ 22 5000 2049 111 ];
# networking.firewall.allowedUDPPorts = [ 2049 111 ];
```

### Passo 9: Testes Finais

```bash
# Testar cache HTTP
curl -sf http://localhost:5000/nix-cache-info

# Testar NFS (se habilitado)
showmount -e localhost

# Verificar serviços
systemctl status nix-serve
systemctl status nfs-server
systemctl status sshd

# Ver logs em tempo real (opcional)
journalctl -u nix-serve -f
```

---

## 📋 Checklist Desktop

- [ ] offload-server.enable = true no configuration.nix
- [ ] enableNFS = true (se quiser NFS)
- [ ] sudo passwordless configurado (opcional)
- [ ] Rebuild executado (`sudo nixos-rebuild switch`)
- [ ] Chaves de cache geradas (`offload-generate-cache-keys`)
- [ ] Chave pública do cache anotada
- [ ] Diretório SSH do nix-builder criado
- [ ] Firewall verificado/configurado
- [ ] `offload-server-status` mostra tudo ✅
- [ ] Cache acessível: `curl http://localhost:5000/nix-cache-info`

---

## 🔴 Troubleshooting

### Rebuild Falha

```bash
# Ver erro completo
sudo nixos-rebuild switch --show-trace

# Verificar sintaxe
nix flake check /etc/nixos
```

### nix-serve não inicia

```bash
# Ver logs
journalctl -u nix-serve -n 50

# Verificar chaves
ls -la /var/cache-*.pem

# Reiniciar serviço
sudo systemctl restart nix-serve
```

### NFS não funciona

```bash
# Verificar serviço
systemctl status nfs-server

# Ver exports
sudo exportfs -v

# Reiniciar
sudo systemctl restart nfs-server
```

---

## 📤 Informações para o Laptop

Após completar o setup, você precisa passar estas informações para o laptop:

1. **Chave pública do cache** (formato: `cache.local:xxx...`)
2. **IP do desktop** (confirmar: `ip addr show`)
3. **Confirmação de que serviços estão rodando** (`offload-server-status`)

---

## 🔄 Próximo Passo

Depois de executar todos os comandos acima no desktop, volte para o laptop e execute os passos da seção **"Configuração do Laptop (Cliente)"** no arquivo `STACK-SERVER-CLIENT-COMPLETE-GUIDE.md`.

---

**Status:** ⏳ Aguardando execução no desktop