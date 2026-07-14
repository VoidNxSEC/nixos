# Playbook: NixOS Specialisations

## O que são

Especializações NixOS são variantes do sistema que coexistem na mesma geração.
Cada uma sobrescreve partes da config base para um ambiente específico,
sem precisar de rebuild ou reboot — a troca é instantânea via `switch-to-configuration`.

A config base é mínima e estável. Tudo que é específico de um contexto
(k8s, pentest, dev) fica isolado na especialização correspondente.

## Especializações disponíveis

| Alias          | Nome                | Quando usar                                          |
|----------------|---------------------|------------------------------------------------------|
| `nx-spec-dev`  | `development`       | Desenvolvimento: Rust, Go, Python, Node, Docker, portas 3000-9999 abertas |
| `nx-spec-k8s`  | `k8s-lab`           | Kubernetes local: kind, kubectl, helm, k9s, sysctl de pods |
| `nx-spec-sec`  | `cybersecurity`     | Pentest / análise: nmap, burpsuite, wireshark, metasploit, ghidra |
| `nx-spec-priv` | `privacy-paranoia`  | Máximo anonimato: Tor, kernel hardening agressivo, anti-fingerprint |
| `nx-spec-emer` | `emergency`         | Boot de diagnóstico: Trezor auth, ferramentas de recuperação |
| `nx-spec-base` | *(base)*            | Retorna para a config base padrão                    |

## Comandos

```bash
# Ver o que está ativo agora
nx-spec-status

# Listar especializações buildadas
nx-spec-list

# Ativar uma especialização (sem reboot)
nx-spec-dev
nx-spec-k8s
nx-spec-sec
nx-spec-priv
nx-spec-emer

# Voltar para a base
nx-spec-base
```

## Como funciona por baixo

```bash
# O que o alias faz internamente:
sudo /run/current-system/specialisation/<nome>/bin/switch-to-configuration switch

# Para voltar para a base:
sudo /run/current-system/bin/switch-to-configuration switch
```

A troca é não-destrutiva: o sistema base continua buildado.
Reboot sempre retorna para o sistema base (ou você seleciona no bootloader).

## Adicionando uma nova especialização

1. Crie `hosts/kernelcore/specialisations/minha-spec.nix`:

```nix
{ lib, pkgs, ... }:
{
  specialisation.minha-spec.configuration = {
    system.nixos.tags = [ "MinhaSpec" ];

    # Sobrescreva apenas o que for diferente da base
    # Use lib.mkForce para garantir prioridade sobre mkDefault da base
  };
}
```

2. Importe em `hosts/kernelcore/specialisations/default.nix`:

```nix
imports = [
  ./minha-spec.nix
  # ...
];
```

3. Adicione o alias em `modules/shell/aliases/nix/specialisations.nix`:

```nix
"nx-spec-minha" = "sudo /run/current-system/specialisation/minha-spec/bin/switch-to-configuration switch";
```

4. Rebuild:

```bash
nx-rebuild
```

## Regras de design

- **Base**: só o que todo ambiente precisa (boot, rede, usuário, hardware)
- **Especialização**: tudo que é exclusivo de um contexto vai aqui, não na base
- Use `lib.mkForce` para sobrescrever `mkDefault` da base
- Firewall: cada especialização define suas próprias regras — não abra portas na base
- Secrets/SOPS: gerenciados na base; especializações só habilitam serviços que os consomem

## Localização dos arquivos

```
hosts/kernelcore/specialisations/
├── default.nix          # Agrega todas as especializações
├── development.nix
├── k8s-lab.nix
├── cybersecurity.nix
├── privacy-paranoia.nix
├── emergency.nix
└── stable.nix

modules/shell/aliases/nix/specialisations.nix  # Aliases de ativação
```
