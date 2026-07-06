# brave-hardened — usage & reference

## Importar no flake

```nix
# flake.nix
nixosConfigurations.voidnx = nixpkgs.lib.nixosSystem {
  modules = [
    ./configuration.nix
    ./modules/brave-hardened.nix      # ← adiciona o módulo
  ];
};
```

## Configuração mínima (AMD + Quad9 + firejail)

```nix
voidnxlabs.brave-hardened = {
  enable      = true;
  vaapiDriver = "radeonsi";      # AMD Mesa
  wayland     = true;
  dns.provider = "quad9";
  networkConfinement = {
    enable     = true;
    useFirejail = true;
    allowQUIC  = true;
  };
};
```

## Configuração Intel

```nix
voidnxlabs.brave-hardened = {
  enable      = true;
  vaapiDriver = "iHD";           # Intel Gen8+; use i965 para Gen7 e mais antigos
  wayland     = true;
  dns.provider = "nextdns";
  dns.nextdnsId = "abc123";
};
```

## NextDNS com perfil customizado

```nix
dns = {
  provider  = "nextdns";
  nextdnsId = "SEU_ID_AQUI";    # vai em https://my.nextdns.io
};
```

## DNS totalmente customizado (AdGuard, Pi-Hole, etc.)

```nix
dns = {
  provider      = "custom";
  customServers = [ "94.140.14.14" "94.140.15.15" ];
  customDoH     = "https://dns.adguard-dns.com/dns-query";
};
```

## Sem QUIC (só TCP, máximo controle de tráfego)

```nix
networkConfinement.allowQUIC = false;
```

## Verificar VAAPI depois do nixos-rebuild

```bash
vainfo
# Deve listar VAEntrypoint* para o driver configurado

# Inspecionar sandbox ativa
firejail --list
# Deve aparecer: brave-hardened
```

## O que cada camada faz

| Camada | Mecanismo | Efeito |
|---|---|---|
| Enterprise Policies | `/etc/brave/policies/managed/hardened.json` | Usuário não pode fazer override via `brave://settings` |
| CLI flags | `--enable-features=StrictOriginIsolation`, `--site-per-process`, etc. | Isolamento de processo, desativa telemetria na inicialização |
| VAAPI + GPU | `VaapiVideoDecodeLinuxGL`, `zero-copy`, ozone | Decode de vídeo em hardware; rasterização GPU |
| firejail | `--profile=brave-hardened.fjprofile` | Namespace isolado, /tmp privado, caps.drop |
| netfilter (iptables) | `netfilter brave-netfilter.iptables` | Whitelist DNS, bloqueia RFC1918, só TCP/443 + 80 |
| DNS whitelist | Regra `-p udp/tcp --dport 53` | Qualquer DNS fora do provider configurado é DROPado |

## Diagnosticar bloqueios de rede

```bash
# Ver regras ativas dentro do sandbox firejail
firejail --join=brave-hardened
iptables -L OUTPUT -n -v

# Testar DNS leak
# Dentro de um terminal normal:
dig @8.8.8.8 example.com
# → deve FALHAR se o Brave tentar usar qualquer DNS além dos configurados
```

## Notas

- `SafeBrowsingEnabled = false` remove a dependência dos servidores Google. Use o **Brave Shields** (shields.up) como substituto — ele é local e não envia URLs.
- `PasswordManagerEnabled = false` assume que você usa Bitwarden/KeePass externamente. Reverta se quiser o manager built-in.
- `DefaultMediaStreamSetting = 2` bloqueia câmera/mic por padrão. Sites específicos (Jitsi, etc.) podem receber permissão via `brave://settings/content`.
- `nosound` está comentado no perfil firejail — descomente se não precisar de áudio no browser para reduzir superfície de ataque.
- Em sistemas com `networking.nftables.enable = true` (sem iptables-legacy), adicione `pkgs.iptables` ao `environment.systemPackages` manualmente se o nixpkgs não resolver automaticamente.
