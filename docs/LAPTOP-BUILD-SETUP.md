# Laptop Build Setup - Offload de Builds para Desktop

**Data Atualização**: 2025-11-02
**Status**: 🔄 Em configuração - Desktop IP atualizado para 192.168.15.6

Este guia mostra como configurar o laptop para usar o desktop (192.168.15.6) como servidor de build remoto.

## 📋 Pré-requisitos

### No Desktop (192.168.15.6):
- ⚠️ Módulo `offload-server` precisa ser ativado
- ⚠️ Chaves de cache precisam ser configuradas
- ⚠️ Usuário `nix-builder` precisa ter chave SSH do laptop
- ⚠️ `nix-serve` rodando na porta 5000
- ✅ SSH habilitado

### No Laptop (192.168.15.8):
- SSH client instalado
- Acesso à rede local (192.168.15.0/24)
- NixOS instalado

---

## 🚀 Setup Rápido (3 passos)

### Passo 1: Gerar Chaves no Desktop

**No desktop**, execute:

```bash
# Gerar chaves de assinatura do cache
sudo offload-generate-cache-keys

# Verificar status do servidor
offload-server-status
```

**Importante**: Anote a chave pública que aparece! Você vai precisar dela no laptop.

Exemplo de saída:
```
📋 Public key (add to laptop's trusted-public-keys):
   cache.local:XYZ123ABC456...
```

---

### Passo 2: Copiar Chaves para o Laptop

**No laptop**, execute:

```bash
# Copiar chave SSH do builder
sudo scp kernelcore@192.168.15.6:/etc/nix/builder_key /etc/nix/

# Ajustar permissões
sudo chmod 600 /etc/nix/builder_key

# OPCIONAL: Verificar a chave
cat /etc/nix/builder_key
```

---

### Passo 3: Configurar e Rebuild no Laptop

**No laptop**, adicione ao `/etc/nixos/configuration.nix`:

```nix
{
  # ... suas outras configurações ...

  # Habilitar offload client
  services.laptop-builder-client = {
    enable = true;
    desktopIP = "192.168.15.6";  # IP do desktop
    builderKeyPath = "/etc/nix/builder_key";
    maxJobs = 0;  # 0 = força uso do desktop para todos os builds
  };

  # Configurar cache do desktop
  nix.settings = {
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.local:XYZ123ABC456..."  # ⚠️ SUBSTITUIR pela chave do Passo 1!
    ];
  };
}
```

**Rebuild**:

```bash
sudo nixos-rebuild switch
```

---

## 🧪 Testes

### Testar Conectividade

```bash
# Verificar status do offload
offload-status

# Testar build remoto
offload-test-build
```

**Saída esperada**:
```
🖥️  Laptop Offload Client Status
===============================

📡 Desktop Connection:
✅ Desktop reachable

🔑 SSH Builder Access:
✅ SSH builder access working

🗄️  Cache Access:
✅ Desktop cache accessible
```

### Testar Build Remoto Manual

```bash
# Forçar build remoto
nix-build '<nixpkgs>' -A hello \
  --option builders "ssh://nix-builder@192.168.15.6 x86_64-linux /etc/nix/builder_key 2 1" \
  --option substitute false \
  --no-out-link
```

Se funcionar, você verá logs do build acontecendo no desktop!

---

## 📊 Configuração Detalhada (Opcional)

### Opção A: Usar Módulo `laptop-builder-client` (Recomendado)

```nix
# /etc/nixos/configuration.nix (laptop)
{
  imports = [
    # ... outros imports ...
  ];

  services.laptop-builder-client = {
    enable = true;
    desktopIP = "192.168.15.6";
    builderKeyPath = "/etc/nix/builder_key";
    maxJobs = 0;  # Forçar offload para tudo
  };

  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cache.local:SUA_CHAVE_AQUI"  # Do Passo 1
  ];
}
```

### Opção B: Configuração Manual

```nix
# /etc/nixos/configuration.nix (laptop)
{
  nix.settings = {
    # Builders remotos
    builders = [
      "ssh://nix-builder@192.168.15.6 x86_64-linux /etc/nix/builder_key 2 1 nixos-test,benchmark,big-parallel"
    ];

    builders-use-substitutes = true;
    max-jobs = 0;  # Forçar offload
    fallback = true;  # Permitir build local se remoto falhar

    # Cache do desktop (maior prioridade)
    substituters = [
      "http://192.168.15.6:5000"  # Desktop cache
      "https://cache.nixos.org"   # Cache oficial
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.local:SUA_CHAVE_AQUI"
    ];

    connect-timeout = 5;
    stalled-download-timeout = 30;
  };

  # SSH config
  programs.ssh.extraConfig = ''
    Host 192.168.15.6
      HostName 192.168.15.6
      User nix-builder
      Port 22
      IdentityFile /etc/nix/builder_key
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
      Compression yes
      ServerAliveInterval 60
      ServerAliveCountMax 3
      ControlMaster auto
      ControlPath ~/.ssh/nix-builder-%h-%p-%r
      ControlPersist 600
  '';
}
```

---

## 🔧 Troubleshooting

### Erro: "SSH connection failed"

```bash
# Testar SSH manualmente
ssh -i /etc/nix/builder_key nix-builder@192.168.15.6

# Verificar chave
ls -la /etc/nix/builder_key
# Deve ser: -rw------- (600)

# Corrigir permissões se necessário
sudo chmod 600 /etc/nix/builder_key
```

### Erro: "Cache not accessible"

```bash
# Testar cache manualmente
curl http://192.168.15.6:5000/nix-cache-info

# No desktop, verificar se nix-serve está rodando
systemctl status nix-serve
```

### Erro: "Untrusted public key"

Você esqueceu de adicionar a chave pública do desktop ao `trusted-public-keys` do laptop!

```bash
# No desktop, obter a chave
cat /var/cache-pub-key.pem

# No laptop, adicionar ao configuration.nix
nix.settings.trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "cache.local:CHAVE_DO_DESKTOP_AQUI"
];
```

### Build ainda acontece localmente

```bash
# Verificar configuração
nix show-config | grep builders

# Deve mostrar:
# builders = ssh://nix-builder@192.168.15.6 ...

# Forçar offload
nix.settings.max-jobs = 0;  # No configuration.nix
```

---

## 📈 Monitoramento

### No Laptop

```bash
# Status do offload
offload-status

# Monitorar builds em tempo real
watch -n 2 'ps aux | grep nix-build'
```

### No Desktop

```bash
# Status do servidor
offload-server-status

# Logs do nix-serve
journalctl -u nix-serve -f

# Logs de SSH (builds remotos)
journalctl -u sshd -f | grep nix-builder

# Monitorar cache requests
ss -tn state established '( dport = :5000 )'
```

---

## 🎯 Benefícios Esperados

Após configuração completa:

- ✅ **Builds 2-5x mais rápidos** (desktop tem mais recursos)
- ✅ **Menos uso de CPU/memória no laptop** (builds no desktop)
- ✅ **Cache local no desktop** (90%+ cache hits antes de internet)
- ✅ **Fallback automático** (se desktop offline, builda localmente)

---

## 📚 Referências

- Módulo desktop: `/etc/nixos/modules/services/offload-server.nix`
- Módulo laptop: `/etc/nixos/modules/services/laptop-builder-client.nix`
- Template cliente: `/etc/nixos/modules/services/laptop-offload-client.nix`
- Manual Nix: https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html

---

## ⚙️ Configurações Avançadas

### Habilitar NFS para compartilhar /nix/store

**No desktop**, editar `/etc/nixos/hosts/kernelcore/configuration.nix`:

```nix
services.offload-server = {
  enable = true;
  enableNFS = true;  # ← Adicionar isto
};
```

**No laptop**, adicionar mount NFS:

```nix
fileSystems."/nix/store-remote" = {
  device = "192.168.15.6:/nix/store";
  fsType = "nfs";
  options = [ "ro" "hard" "intr" "_netdev" ];
};
```

### Ajustar Número de Jobs

```nix
services.laptop-builder-client = {
  enable = true;
  maxJobs = 1;  # Permite 1 build local, resto vai pro desktop
  # maxJobs = 0;  # Força 100% offload
};
```

---

**Última atualização**: 2025-11-02
**Autor**: kernelcore
**Versão**: 1.0
