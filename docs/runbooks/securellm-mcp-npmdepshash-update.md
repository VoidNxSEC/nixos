# Runbook: Atualizar `npmDepsHash` do `securellm-mcp`

> **Quando usar**: depois de mexer em `package.json` / `package-lock.json` no
> repositório `~/master/securellm-mcp` (adicionar, remover ou bumpar dependências
> npm) e o `sudo nixos-rebuild switch` falhar com:
>
> ```
> ERROR: npmDepsHash is out of date
> ```

---

## Contexto

O pacote `securellm-mcp` é construído via `pkgs.buildNpmPackage` em dois locais:

| Local | Caminho | Função |
|---|---|---|
| Repo do MCP | `~/master/securellm-mcp/flake.nix` | flake próprio do projeto (`nix build .#`) |
| Repo NixOS | `/etc/nixos/pkgs/securellm-mcp.nix` | derivação usada no rebuild do sistema |

Ambos contêm um campo `npmDepsHash` que **precisa bater com o conteúdo do
`package-lock.json` em uso**. Mudou o lockfile → hash quebrou → build falha.

O input do flake do NixOS aponta para `github:VoidNxSEC/securellm-mcp`, então o
ciclo é: **commitar no repo do MCP → push para o `github` remote → `nix flake
update securellm-mcp` no `/etc/nixos` → atualizar o hash em `pkgs/securellm-mcp.nix`**.

---

## Procedimento

### 1. Calcular o novo hash

A partir do `package-lock.json` atualizado no repo do MCP:

```bash
cd ~/master/securellm-mcp
nix run nixpkgs#prefetch-npm-deps -- package-lock.json
```

Saída esperada (exemplo):

```
sha256-c1zCWwkZXDmu8immSzfrB2Kpo/Z5dQcoHuwQjTvqdwc=
```

Copia esse valor — vai ser reutilizado nos dois arquivos.

> **Alternativa (sem prefetch)**: trocar o hash por `lib.fakeHash`, rodar
> `nix build`, copiar o `got: sha256-...` do erro. Funciona, mas dá dois ciclos
> de build. Prefira o `prefetch-npm-deps`.

### 2. Atualizar o `flake.nix` do MCP

```bash
cd ~/master/securellm-mcp
# editar flake.nix → campo npmDepsHash do mcpServer
```

Trecho:

```nix
npmDepsHash = "sha256-<NOVO_HASH>";
```

### 3. Commit + push para o remote `github`

O input do `/etc/nixos/flake.nix` usa `github:VoidNxSEC/securellm-mcp`, então o
push **precisa ir para o remote `github`** (não `forgejo` nem `gitlab`):

```bash
cd ~/master/securellm-mcp
git add flake.nix package.json package-lock.json   # o que tiver mudado
git commit -m "fix(flake): update npmDepsHash for <motivo>"
git push github main
```

### 4. Atualizar o lock do `/etc/nixos`

```bash
cd /etc/nixos
nix flake update securellm-mcp
```

Confirma na saída que o `securellm-mcp` foi avançado para o commit que acabaste
de empurrar.

### 5. Sincronizar o hash em `pkgs/securellm-mcp.nix`

Este passo é **obrigatório** — não basta atualizar o flake do MCP. A derivação
usada no rebuild vive em `/etc/nixos/pkgs/securellm-mcp.nix` e tem o seu próprio
`npmDepsHash`:

```nix
# /etc/nixos/pkgs/securellm-mcp.nix
npmDepsHash = "sha256-<NOVO_HASH>";   # o mesmo valor do passo 1
```

### 6. Validar e fazer rebuild

```bash
cd /etc/nixos
nix flake check          # opcional, mais rápido para validar sintaxe
sudo nixos-rebuild switch
```

Se o `prefetch-npm-deps` retornou o hash correto, o build passa direto.

---

## Por que existem dois `npmDepsHash`?

- O flake do MCP (`~/master/securellm-mcp/flake.nix`) é útil para
  `nix build .#` standalone e para o devShell — vive junto com o código.
- O `/etc/nixos/pkgs/securellm-mcp.nix` é a versão que o sistema empacota durante
  o rebuild, com filtros adicionais de source (exclui `.env`, `.git`,
  `node_modules`, etc.). Por usar uma `src` filtrada, **a derivação não delega
  para o flake do MCP** — define seu próprio hash.

Manter os dois iguais é deliberado: o standalone e o do sistema constroem o
mesmo conjunto de deps.

---

## Pegadinha recorrente: `ENOTCACHED` no `buildPhase`

Se o erro **não** for de hash mas sim:

```
> npm error code ENOTCACHED
> npm error request to https://registry.npmjs.org/<pacote> failed:
>   cache mode is 'only-if-cached' but no cached response is available.
```

A causa quase sempre é: o `package.json` usa `npx <pacote>` num script do `npm
run`, mas o `<pacote>` **não está declarado em `dependencies`/`devDependencies`**.
O `npm ci` que o `buildNpmPackage` roda não o instala, e o sandbox bloqueia o
fetch on-the-fly do `npx`.

**Caso histórico**: `npm run build` chama `npx tsx scripts/curate-tools.ts` e
`tsx` não estava no lockfile.

**Fix**:

```bash
cd ~/master/securellm-mcp
npm install --save-dev <pacote>       # ex: tsx
```

Depois segue o procedimento normal a partir do passo 1 (recalcular o hash,
commit, push, `nix flake update`, sincronizar hash em `pkgs/securellm-mcp.nix`,
rebuild).

> **Regra geral**: qualquer `npx <X>` em script `npm` consumido pelo build do
> Nix exige que `<X>` esteja declarado no `package.json`. Não confiar no
> resolve on-the-fly do `npx`.

---

## Sinais de que este runbook se aplica

```
> ERROR: npmDepsHash is out of date
>
> The package-lock.json in src is not the same as the in /nix/store/...-securellm-mcp-...-npm-deps.
```

Seguido de cascata de "Build failed due to failed dependency" nos paths que
dependem do `mcp-server` (etc-skel, mcp-config.json, system-path, unit do
serviço, etc-system, tmpfiles, user-units, nixos-system-…).

Todas estas falhas são **um único root cause** — basta corrigir o hash.

---

## Checklist rápido

- [ ] `nix run nixpkgs#prefetch-npm-deps -- package-lock.json` (no repo do MCP)
- [ ] Atualizar `npmDepsHash` em `~/master/securellm-mcp/flake.nix`
- [ ] `git add && git commit && git push github main`
- [ ] `nix flake update securellm-mcp` no `/etc/nixos`
- [ ] Atualizar `npmDepsHash` em `/etc/nixos/pkgs/securellm-mcp.nix` com o mesmo hash
- [ ] `sudo nixos-rebuild switch`
