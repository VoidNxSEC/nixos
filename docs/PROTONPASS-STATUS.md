# Proton Pass Packaging - Status

## ✅ O que foi feito:

1. **Criado [`protonpass.nix`](file:///etc/nixos/modules/packages/deb-packages/packages/protonpass.nix)**
   - Versão: 1.33.0
   - Hash SHA256: `10b03e615f9a6e341685bd447067b839fd3a770e9bb1110ca04d0418d6beaca8`
   - Método: FHS (Electron app)
   - Sand box ativado
   - Audit logging ativado

2. **Corrigido bug no [`builder.nix`](file:///etc/nixos/modules/packages/deb-packages/builder.nix#L48)**
   - Mudado `wrapper` para `wrapper_raw` (linha 48)
   - O buildFHS espera `wrapper_raw` como argumento

3. **Adicionado ProtonPass.deb ao Git**
   - Arquivo agora está tracked
   - Git LFS configurado para `.deb` files

## ❌ Problema atual:

```
error: A definition for option `environment.systemPackages."[definition 14-entry 1]"' is not of type `package'
```

**Diagnóstico:**
- O módulo `deb-packages` está exportando algo para `environment.systemPackages` que não é um package válido
- O erro acontece em `default.nix` linha 281: `environment.systemPackages = attrValues builtPackages;`
- O `builder.buildDebPackage` pode estar retornando um tipo incorreto

## 🔍 Próximos passos de debugging:

1. Verificar se `builder.buildDebPackage` retorna um derivation válido
2. Testar o build isolado de um único package
3. Verificar se o problema está no `audit.nix` wrapper
4. Considerar usar exemplo funcional (ProtonVPN) como referência

## Configuração atual:

Temporariamente **DESABILITADO** (`enable = false`) em:
- [`configuration.nix`](file:///etc/nixos/hosts/kernelcore/configuration.nix#L116)

Para reativar após correção:
```nix
packages.deb.enable = true;
```

## Arquivos modificados:

- ✅ `/etc/nixos/modules/packages/deb-packages/packages/protonpass.nix`
- ✅ `/etc/nixos/modules/packages/deb-packages/builder.nix` 
- ✅ `/etc/nixos/hosts/kernelcore/configuration.nix`
- ✅ `/etc/nixos/modules/packages/deb-packages/storage/ProtonPass.deb` (tracked)
