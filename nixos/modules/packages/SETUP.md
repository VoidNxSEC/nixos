# Package Setup Instructions

> **Como adicionar os pacotes .deb e .tar.gz baixados**

## Arquivos Necessários

### 1. ProtonVPN (deb-packages)

```bash
# Baixar
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb

# Mover para storage
mv protonvpn-stable-release_1.0.8_all.deb \
   /etc/nixos/modules/packages/deb-packages/storage/

# Verificar checksum
echo "0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180  protonvpn-stable-release_1.0.8_all.deb" \
  | sha256sum --check -
```

### 2. Lynis (tar-packages)

```bash
# Baixar
wget https://github.com/CISOfy/lynis/releases/download/3.1.6/lynis-3.1.6.tar.gz

# Mover para storage
mv lynis-3.1.6.tar.gz \
   /etc/nixos/modules/packages/tar-packages/storage/

# Calcular checksum
nix-hash --type sha256 --flat lynis-3.1.6.tar.gz

# Atualizar em: modules/packages/tar-packages/packages/lynis.nix
# source.sha256 = "RESULTADO_DO_HASH_ACIMA";
```

### 3. NordVPN GUI (tar-packages)

```bash
# Extrair binário do installer
bash <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh) -p nordvpn-gui

# Ou se já tiver o .deb:
# Extrair binário
dpkg-deb -x nordvpn*.deb nordvpn-extracted/

# Criar tarball do binário
cd nordvpn-extracted
tar -czf nordvpn-gui.tar.gz usr/bin/nordvpn*

# Mover para storage
mv nordvpn-gui.tar.gz \
   /etc/nixos/modules/packages/tar-packages/storage/

# Calcular checksum
nix-hash --type sha256 --flat nordvpn-gui.tar.gz
```

### 4. Cursor (deb-packages)

```bash
# Se você tiver o .deb do Cursor
mv cursor*.deb \
   /etc/nixos/modules/packages/deb-packages/storage/

# Calcular checksum
nix-hash --type sha256 --flat cursor*.deb
```

## Ativar Pacotes

### Editar configuration.nix

```nix
# /etc/nixos/hosts/kernelcore/configuration.nix

kernelcore = {
  # ... outras configs ...

  # deb packages
  packages.deb = {
    enable = true;
    packages = lib.mkMerge [
      (import ../../modules/packages/deb-packages/packages/protonvpn.nix)
      # (import ../../modules/packages/deb-packages/packages/cursor.nix)
    ];
  };

  # tar packages
  packages.tar = {
    enable = true;
    packages = lib.mkMerge [
      (import ../../modules/packages/tar-packages/packages/zellij.nix)
      (import ../../modules/packages/tar-packages/packages/lynis.nix)
      # (import ../../modules/packages/tar-packages/packages/nordvpn-gui.nix)
    ];
  };
};
```

### Rebuild

```bash
# Validar
nix flake check

# Aplicar
sudo nixos-rebuild switch

# Testar
protonvpn --version
lynis --version
zellij --version
```

## Remover Lynis do Nixpkgs

Se Lynis estava instalado via nixpkgs:

```nix
# Antes (REMOVER):
environment.systemPackages = with pkgs; [
  lynis  # ← REMOVER essa linha
];

# Depois: gerenciado por tar-packages (veja acima)
kernelcore.packages.tar.packages = import .../lynis.nix;
```

## Troubleshooting

### Checksum Mismatch

```bash
# Recalcular
nix-hash --type sha256 --flat ARQUIVO

# Atualizar no .nix
source.sha256 = "NOVO_HASH";
```

### Build Fails

```bash
# Ver logs
journalctl -u deb-package-protonvpn -n 50
journalctl -u tar-package-lynis -n 50

# Testar método diferente
method = "fhs";  # ou "native"
```

### Runtime Errors

```bash
# Desabilitar sandbox temporariamente
sandbox.enable = false;

# Ver audit logs
ausearch -k deb_exec_protonvpn
```

---

**Última atualização**: 2025-11-03
