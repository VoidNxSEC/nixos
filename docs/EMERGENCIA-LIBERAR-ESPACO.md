# 🚨 EMERGÊNCIA: DISCO 99% CHEIO - AÇÃO IMEDIATA NECESSÁRIA

**Status Atual**: 430GB usado / 458.7GB total = **99% CHEIO** ⚠️  
**Espaço Livre**: Apenas **5.3GB** (CRÍTICO!)

---

## ⚡ AÇÃO IMEDIATA (FAZER AGORA!)

### Passo 1: Liberar Espaço com Garbage Collection (SEGURO)

```bash
# 1. Verificar gerações antigas do sistema
nix-env --list-generations --profile /nix/var/nix/profiles/system

# 2. Deletar gerações antigas (MANTÉM apenas a atual e últimas 2)
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system

# 3. Garbage collection agressiva
sudo nix-collect-garbage -d

# 4. Otimizar store (deduplica arquivos)
sudo nix-store --optimise

# 5. Verificar espaço liberado
df -h /
```

**Tempo**: 10-30 minutos  
**Espaço Esperado Liberado**: 50-150GB ✅

---

### Passo 2: Limpeza Adicional (Se Necessário)

```bash
# Limpar cache de logs antigos
sudo journalctl --vacuum-time=7d

# Limpar cache do Docker (se usar)
docker system prune -a

# Limpar cache do Nix
sudo rm -rf /nix/var/nix/temproots/*
sudo rm -rf /tmp/nix-*
```

**Espaço Adicional**: 5-20GB

---

## 📊 Por Que o Disco Está Tão Cheio?

Provável causa: `/nix/store` acumulou:
- Dezenas ou centenas de gerações antigas do sistema
- Builds antigos não removidos
- Dependências duplicadas
- Cache de compilação

**Estimativa**: `/nix/store` pode estar com 300-400GB!

---

## ⏱️ DEPOIS DA LIMPEZA: Configurar Offload

**Só depois de liberar espaço**, siga os passos em [`EXECUTAR-AGORA.md`](EXECUTAR-AGORA.md)

O offload vai PREVENIR que o problema aconteça novamente porque:
- Builds vão para o desktop (não acumulam no laptop)
- Cache vem do desktop (menos download/compilação local)
- Menos lixo acumulado

---

## 🎯 Resultado Esperado

### Antes da Limpeza:
```
Disco: 430GB / 458.7GB (99% cheio)
Livre: 5.3GB ❌
```

### Após Garbage Collection:
```
Disco: 250-300GB / 458.7GB (60-70%)
Livre: 150-200GB ✅
```

### Com Offload Ativo (Futuro):
```
Disco: 150-200GB / 458.7GB (40-50%)
Livre: 250-300GB ✅✅
Permanece estável!
```

---

## ⚠️ AVISO IMPORTANTE

**NÃO tente configurar o offload com apenas 5.3GB livres!**

O `nixos-rebuild` precisa de ~10-20GB temporários. Com 5.3GB, pode:
- Falhar no meio do rebuild
- Deixar o sistema em estado inconsistente
- Preencher o disco 100% e travar o sistema

**PRIMEIRO limpe espaço, DEPOIS configure o offload.**

---

## 🔍 Diagnóstico Detalhado (Após Limpeza)

```bash
# Ver tamanho de diretórios grandes
sudo du -sh /* | sort -h | tail -20

# Ver tamanho do /nix
sudo du -sh /nix/*

# Ver gerações antigas
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Ver roots (o que está protegendo pacotes de ser deletado)
nix-store --gc --print-roots | grep -v '/proc/'
```

---

## 📋 Checklist de Emergência

- [ ] **PASSO 1**: `sudo nix-collect-garbage -d` (FAZER AGORA!)
- [ ] **PASSO 2**: `sudo nix-store --optimise` (Otimizar)
- [ ] **PASSO 3**: `df -h /` (Verificar se liberou >50GB)
- [ ] **PASSO 4**: Se ainda crítico, limpar Docker/logs
- [ ] **PASSO 5**: Só depois disso, seguir `EXECUTAR-AGORA.md`

---

## 💡 Por Que Offload Ajuda a Longo Prazo

Com offload ativo:
- ✅ Builds no desktop = menos acúmulo local
- ✅ Cache LAN = menos download/compilação
- ✅ Apenas binários essenciais no laptop
- ✅ Desktop gerencia o "lixo" pesado
- ✅ Laptop permanece limpo e rápido

**Offload não é só performance, é também PREVENÇÃO de disco cheio!**

---

## 🆘 Se Garbage Collection Falhar

```bash
# Forçar limpeza mais agressiva
sudo nix-store --gc

# Deletar TODAS as gerações antigas (exceto atual)
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
sudo nix-collect-garbage -d

# Última opção: deletar gerações específicas
sudo nix-env --delete-generations 1 2 3 4 5 --profile /nix/var/nix/profiles/system
```

---

**COMECE AGORA COM O PASSO 1!**  
**Depois que liberar espaço, volte para EXECUTAR-AGORA.md**