# Package Update Guide

> **Purpose**: Processo padronizado para atualizar packages mantidos individualmente, sem depender de nixpkgs oficial.
>
> **Created**: 2025-12-10
> **Maintained by**: kernelcore

---

## Overview

Nixpkgs oficial demora ~2 meses para atualizar packages. Este guia documenta o processo para manter packages individualmente.

---

## 1. NPM Packages (Node.js)

### Exemplo: gemini-cli

**Localização**: `modules/packages/js-packages/`

**Processo:**

```bash
# 1. Baixar nova versão
cd /etc/nixos/modules/packages/js-packages/storage/
wget https://github.com/google-gemini/gemini-cli/archive/refs/tags/v0.XX.0-nightly.YYYYMMDD.HASH.tar.gz

# 2. Calcular SHA256
nix-hash --type sha256 --flat v0.XX.0-nightly.YYYYMMDD.HASH.tar.gz

# 3. Atualizar gemini-cli.nix
vim ../gemini-cli.nix
# Atualizar:
# - version
# - src.url (path do arquivo)
# - sha256

# 4. Primeiro build (vai FALHAR com hash correto do npm)
cd /etc/nixos
nix build .#nixosConfigurations.kernelcore.config.environment.systemPackages --show-trace

# 5. Copiar npmDepsHash do erro
# Exemplo: "got: sha256-XXXXX..."

# 6. Atualizar npmDepsHash no gemini-cli.nix
vim modules/packages/js-packages/gemini-cli.nix
# npmDepsHash = "sha256-XXXXX...";

# 7. Rebuild final
sudo nixos-rebuild switch --flake .#kernelcore --max-jobs 8 --cores 8
```

**Template de atualização:**

```nix
# modules/packages/js-packages/gemini-cli.nix
pkgs.buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.XX.0-nightly.YYYYMMDD.HASH";  # ← ATUALIZAR

  src = pkgs.fetchurl {
    url = "file://${./storage/gemini-cli-${version}.tar.gz}";  # ← ATUALIZAR
    sha256 = "NOVO_SHA256_AQUI";  # ← ATUALIZAR (passo 2)
  };

  npmDepsHash = "SHA256_DO_ERRO_AQUI";  # ← ATUALIZAR (passo 5)

  # ... resto inalterado
}
```

---

## 2. Rust Packages (Cargo)

### Exemplo: codex

**Localização**: `modules/packages/tar-packages/packages/codex.nix`

**Processo:**

```bash
# 1. Baixar nova release do GitHub
cd /etc/nixos/modules/packages/tar-packages/storage/
wget https://github.com/openai/codex/releases/download/rust-vX.XX.X/codex-x86_64-unknown-linux-musl.tar.gz

# 2. Calcular SHA256
nix-hash --type sha256 --flat codex-x86_64-unknown-linux-musl.tar.gz

# 3. Atualizar codex.nix
vim ../packages/codex.nix
# Atualizar:
# - source.path (novo arquivo)
# - source.sha256

# 4. Rebuild
sudo nixos-rebuild switch --flake .#kernelcore --max-jobs 8 --cores 8
```

**Template de atualização:**

```nix
# modules/packages/tar-packages/packages/codex.nix
{
  codex = {
    enable = true;
    method = "native";

    source = {
      path = ../storage/codex-x86_64-unknown-linux-musl.tar.gz;  # ← ATUALIZAR se nome mudou
      sha256 = "NOVO_SHA256_AQUI";  # ← ATUALIZAR
    };

    # ... resto inalterado
  };
}
```

**Nota**: Rust musl binaries são estaticamente linkados → method = "native"

---

## 3. Tar Packages Genéricos

### Exemplo: AppFlowy, Antigravity

**Localização**: `modules/packages/tar-packages/packages/`

**Processo:**

```bash
# 1. Baixar nova versão
cd /etc/nixos/modules/packages/tar-packages/storage/
wget https://github.com/AppFlowy-IO/AppFlowy/releases/download/0.XX.X/AppFlowy-0.XX.X-linux-x86_64.tar.gz

# 2. Calcular SHA256
nix-hash --type sha256 --flat AppFlowy-0.XX.X-linux-x86_64.tar.gz

# 3. Inspecionar estrutura do tar (importante!)
tar -tzf AppFlowy-0.XX.X-linux-x86_64.tar.gz | head -20
# Verificar:
# - Onde está o executável?
# - Mudou a estrutura de diretórios?

# 4. Atualizar appflowy.nix
vim ../packages/appflowy.nix
# Atualizar:
# - source.path
# - source.sha256
# - wrapper.executable (se estrutura mudou)

# 5. Rebuild
sudo nixos-rebuild switch --flake .#kernelcore --max-jobs 8 --cores 8
```

**Template de atualização:**

```nix
# modules/packages/tar-packages/packages/appflowy.nix
{
  appflowy = {
    enable = true;
    method = "fhs";  # Electron apps = FHS

    source = {
      path = ../storage/AppFlowy-0.XX.X-linux-x86_64.tar.gz;  # ← ATUALIZAR
      sha256 = "NOVO_SHA256_AQUI";  # ← ATUALIZAR
    };

    wrapper = {
      executable = "AppFlowy";  # ← VERIFICAR se mudou no tar
      environmentVariables = {
        "APPFLOWY_DATA_DIR" = "$HOME/.appflowy";
      };
    };

    # ... resto inalterado
  };
}
```

---

## 4. Scripts de Automação

### Script: update-npm-package.sh

```bash
#!/usr/bin/env bash
# Usage: ./scripts/update-npm-package.sh gemini-cli v0.21.0-nightly.20251210.abc123

set -e

PACKAGE=$1
VERSION=$2
STORAGE_DIR="/etc/nixos/modules/packages/js-packages/storage"
PACKAGE_FILE="${PACKAGE}-${VERSION}.tar.gz"

if [[ -z "$PACKAGE" || -z "$VERSION" ]]; then
  echo "Usage: $0 <package> <version>"
  exit 1
fi

cd "$STORAGE_DIR"

# Download
echo "Downloading $PACKAGE $VERSION..."
wget "https://github.com/google-gemini/${PACKAGE}/archive/refs/tags/${VERSION}.tar.gz" -O "$PACKAGE_FILE"

# Calculate hash
echo "Calculating SHA256..."
SHA256=$(nix-hash --type sha256 --flat "$PACKAGE_FILE")
echo "SHA256: $SHA256"

# Update nix file (manual step reminder)
echo ""
echo "✅ Downloaded: $STORAGE_DIR/$PACKAGE_FILE"
echo "✅ SHA256: $SHA256"
echo ""
echo "Next steps:"
echo "1. Update modules/packages/js-packages/${PACKAGE}.nix:"
echo "   - version = \"$VERSION\";"
echo "   - sha256 = \"$SHA256\";"
echo "2. Build to get npmDepsHash"
echo "3. Update npmDepsHash"
echo "4. Rebuild system"
```

### Script: update-rust-package.sh

```bash
#!/usr/bin/env bash
# Usage: ./scripts/update-rust-package.sh codex rust-v0.57.0

set -e

PACKAGE=$1
TAG=$2
STORAGE_DIR="/etc/nixos/modules/packages/tar-packages/storage"

if [[ -z "$PACKAGE" || -z "$TAG" ]]; then
  echo "Usage: $0 <package> <release-tag>"
  exit 1
fi

cd "$STORAGE_DIR"

# Download (adjust URL pattern as needed)
echo "Downloading $PACKAGE $TAG..."
wget "https://github.com/openai/${PACKAGE}/releases/download/${TAG}/${PACKAGE}-x86_64-unknown-linux-musl.tar.gz"

# Calculate hash
FILE="${PACKAGE}-x86_64-unknown-linux-musl.tar.gz"
SHA256=$(nix-hash --type sha256 --flat "$FILE")

echo ""
echo "✅ Downloaded: $STORAGE_DIR/$FILE"
echo "✅ SHA256: $SHA256"
echo ""
echo "Update modules/packages/tar-packages/packages/${PACKAGE}.nix with:"
echo "  sha256 = \"$SHA256\";"
```

---

## 5. Checklist de Atualização

### Pré-atualização:
- [ ] Verificar release notes do upstream
- [ ] Backup da versão anterior (mover, não deletar)
- [ ] Anotar versão atual

### Durante:
- [ ] Download correto
- [ ] SHA256 calculado
- [ ] Estrutura do package verificada (tar -tzf)
- [ ] Nix file atualizado

### Pós-atualização:
- [ ] Build passou
- [ ] Package funciona (`which <package>`)
- [ ] Testar funcionalidade básica
- [ ] Commit com mensagem clara

### Template de commit:
```
chore(packages): update <package> to <version>

- Updated from <old-version> to <new-version>
- SHA256: <hash>
- npmDepsHash: <hash> (if npm)
- Tested: <basic test command>
```

---

## 6. Troubleshooting

### Problema: "hash mismatch"
```
error: hash mismatch in fixed-output derivation
  specified: sha256-XXXXX
       got: sha256-YYYYY
```

**Solução**: Use o hash `got:` no nix file.

---

### Problema: npmDepsHash incorreto
```
error: hash mismatch in npm dependencies
  specified: sha256-XXXXX
       got: sha256-YYYYY
```

**Solução**:
1. Copie o hash `got:`
2. Cole em `npmDepsHash = "sha256-YYYYY";`
3. Rebuild

---

### Problema: Executável não encontrado no tar
```
error: cannot find executable 'AppFlowy' in extracted tarball
```

**Solução**:
```bash
# Inspecionar tar
tar -tzf AppFlowy.tar.gz | grep -i appflowy

# Ajustar wrapper.executable no .nix
wrapper.executable = "path/correto/dentro/do/tar";
```

---

### Problema: FHS vs Native method
- **FHS**: Electron, apps complexos, muitas libs dinâmicas
- **Native**: Binários estáticos (Rust musl), scripts shell

**Dica**: Checar linkage:
```bash
file extracted/bin/myapp
# dynamically linked → FHS
# statically linked → Native
```

---

## 7. Packages Atuais

| Package | Tipo | Versão Atual | Última Atualização | Próxima Verificação |
|---------|------|--------------|-------------------|---------------------|
| gemini-cli | NPM | 0.21.0-nightly.20251210 | 2025-12-10 | Semanal |
| codex | Rust | 0.56.0 | 2025-11-XX | Mensal |
| lynis | Tar/Shell | 3.1.6 | 2025-11-XX | Trimestral |
| AppFlowy | Tar/Electron | 0.10.6 | 2025-12-10 | Mensal |
| antigravity | Tar/Electron | 1.11.5 | 2025-11-XX | **MISSING FILE** |

---

## 8. Automação Futura

**Ideias**:
- Script que checa releases do GitHub automaticamente
- Notificação quando há nova versão
- Update automático de desenvolvimento/staging
- CI/CD para testar updates antes de merge

---

**Manutenção**: Atualizar esta doc quando adicionar novos packages ou descobrir novos patterns.
