# ═══════════════════════════════════════════════════════════════
# GEMINI CLI - DIAGNOSTIC & FIX
# ═══════════════════════════════════════════════════════════════

## PROBLEMA DIAGNOSTICADO

Error:
  Cannot find module '/home/kernelcore/.local/share/gemini-cli/packages/cli/dist/index.js'
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                       Este é o path do FHS install!

Causa raiz:
  1. Você tem DUAS instalações de gemini:
     - FHS version (fhs.nix) → path ~/.local/share/gemini-cli
     - js-packages version (gemini-cli.nix) → path /nix/store/...
  
  2. O comando 'gemini' tá executando a ERRADA
     Provavelmente: shell alias, PATH priority, ou symlink quebrado

## DIAGNÓSTICO IMEDIATO

Execute para descobrir qual gemini tá sendo chamado:

```bash
# 1. Qual gemini o shell encontra?
which gemini
type gemini

# 2. Qual o conteúdo do script?
cat $(which gemini)

# 3. Existem múltiplos geminis?
find /nix/store -name "gemini" -type f 2>/dev/null | head -5

# 4. Check aliases
alias | grep gemini

# 5. PATH atual
echo $PATH | tr ':' '\n' | grep -E 'gemini|fhs'
```

## SOLUÇÕES (escolha UMA)

### ══════════════════════════════════════════════════════════════
### OPÇÃO 1: Use APENAS FHS (RECOMENDADO - já funciona!)
### ══════════════════════════════════════════════════════════════

Desabilite a versão js-packages:

```nix
# Em gemini-cli.nix ou onde tiver:
{
  kernelcore.packages.js = {
    enable = true;  # Mantém o sistema ativo
    
    packages.gemini-cli = {
      enable = false;  # ← DESABILITA js-packages version
      # ... resto da config
    };
  };
}

# Em fhs.nix (manter como está):
{
  kernelcore.packages.gemini-cli.enable = true;  # ← FHS version ativa
}
```

Rebuild:
```bash
sudo nixos-rebuild switch
hash -r  # Clear shell hash table
which gemini  # Deve mostrar o FHS wrapper
```

### ══════════════════════════════════════════════════════════════
### OPÇÃO 2: Fix js-packages version (SE quiser usar ela)
### ══════════════════════════════════════════════════════════════

O problema tá no executable path. Depois do build, o path correto
provavelmente é diferente. Vamos descobrir:

```bash
# Build e inspecione:
nix-build -E 'with import <nixpkgs> {}; (import ./gemini-cli.nix { inherit config lib pkgs; }).environment.systemPackages'

# Encontre o path correto:
ls -la result/lib/node_modules/@google/
ls -la result/lib/node_modules/@google/gemini-cli/

# Ajuste gemini-cli.nix com o path correto:
```

Possíveis paths corretos (teste cada um):
```nix
wrapper = {
  name = "gemini";
  
  # Try these in order:
  executable = "lib/node_modules/@google/gemini-cli/dist/index.js";
  # ou
  executable = "lib/node_modules/gemini-cli/dist/index.js";
  # ou
  executable = "bin/gemini";
  # ou
  executable = "packages/cli/dist/index.js";  # Sem lib/node_modules prefix
};
```

### ══════════════════════════════════════════════════════════════
### OPÇÃO 3: Hybrid approach (development)
### ══════════════════════════════════════════════════════════════

Use FHS pro dia-a-dia, js-packages como fallback:

```nix
# fhs.nix
kernelcore.packages.gemini-cli.enable = true;

# gemini-cli.nix  
kernelcore.packages.js.packages.gemini-cli = {
  enable = true;
  wrapper.name = "gemini-native";  # ← Nome diferente!
};
```

Agora você tem:
- `gemini` → FHS version (funciona)
- `gemini-native` → js-packages version (pra testar)

## RECOMENDAÇÃO FINAL

**Use FHS (Opção 1)**. Por quê?

✅ Já funciona
✅ Gemini CLI tem dependências complexas (bubblewrap interno)
✅ FHS environment é exatamente pra esse caso
✅ Menos overhead de manutenção

A versão js-packages é academicamente interessante (declarativo puro),
mas FHS é pragmaticamente superior pra packages com dependências
runtime complexas.

## CLEANUP PÓS-FIX

Depois de escolher, limpe instalações antigas:

```bash
# Se escolheu FHS, remova instalação js-packages:
rm -rf ~/.local/share/gemini-cli  # Se não for usar FHS
nix-collect-garbage -d            # Remove builds antigos

# Rebuild limpo
sudo nixos-rebuild switch
hash -r
```

═══════════════════════════════════════════════════════════════
