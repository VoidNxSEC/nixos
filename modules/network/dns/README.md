# DNS Proxy com Cache

Um proxy DNS rápido e seguro escrito em Golang com cache inteligente para melhorar a resolução de DNS.

## Características

- **Cache LRU**: Armazena até 10.000 respostas DNS em cache por padrão
- **Múltiplos Upstreams**: Suporta vários servidores DNS com fallback automático
- **Alta Performance**: Implementado em Go para máxima velocidade
- **Seguro**: Executa com DynamicUser e hardening completo do systemd
- **Estatísticas**: Logging de métricas (queries, cache hits/misses, latência)
- **Configurável**: Totalmente configurável via módulo NixOS

## Uso

### Habilitação Básica

Para habilitar o proxy DNS com configurações padrão, adicione ao seu `configuration.nix`:

```nix
{
  kernelcore.network.dns-proxy.enable = true;
}
```

Isso irá:
- Iniciar o proxy DNS na porta 53 (127.0.0.1:53)
- Configurar o sistema para usar o proxy como resolver
- Usar Cloudflare, Google e Quad9 como upstreams
- Cachear respostas por 5 minutos

### Configuração Personalizada

```nix
{
  kernelcore.network.dns-proxy = {
    enable = true;

    # Endereço de escuta
    listenAddress = "127.0.0.1:53";

    # Servidores DNS upstream (com fallback)
    upstreams = [
      "1.1.1.1:53"        # Cloudflare Primary
      "1.0.0.1:53"        # Cloudflare Secondary
      "8.8.8.8:53"        # Google Primary
      "9.9.9.9:53"        # Quad9
    ];

    # Tamanho do cache (número de entradas)
    cacheSize = 10000;

    # TTL do cache em segundos
    cacheTTL = 300;  # 5 minutos

    # Timeout para queries upstream
    timeout = 5;

    # Habilitar estatísticas periódicas
    enableStats = true;

    # Usar como resolver do sistema
    setAsSystemResolver = true;
  };
}
```

### Não Usar como Resolver do Sistema

Se você quiser apenas executar o proxy sem configurá-lo como resolver do sistema:

```nix
{
  kernelcore.network.dns-proxy = {
    enable = true;
    setAsSystemResolver = false;
  };
}
```

Depois, configure manualmente seus aplicativos para usar `127.0.0.1:53`.

## Aplicação das Mudanças

Após adicionar a configuração:

```bash
# Validar configuração
nix flake check

# Aplicar mudanças
sudo nixos-rebuild switch
```

## Monitoramento

### Ver Logs do Serviço

```bash
# Logs em tempo real
journalctl -fu dns-proxy.service

# Últimas 100 linhas
journalctl -u dns-proxy.service -n 100
```

### Status do Serviço

```bash
systemctl status dns-proxy.service
```

### Estatísticas

O proxy DNS imprime estatísticas a cada 30 segundos quando `enableStats = true`:

```
Stats: Queries: 1234 | Cache Hits: 890 (72.12%) | Misses: 344 | Errors: 0 | Avg Time: 12.5ms
```

### Testar Resolução DNS

```bash
# Usando dig
dig @127.0.0.1 google.com

# Usando nslookup
nslookup google.com 127.0.0.1

# Verificar resolver do sistema
cat /etc/resolv.conf
```

## Performance

O proxy DNS oferece melhorias significativas de performance:

- **Cache Hit**: ~0.1ms de latência
- **Cache Miss**: ~15-50ms (dependendo do upstream)
- **Taxa de Cache Hit**: Tipicamente 60-80% em uso normal

## Segurança

O serviço é executado com máximo hardening:

- **DynamicUser**: Executa com usuário dinâmico (sem privilégios permanentes)
- **Capabilities Mínimas**: Apenas `CAP_NET_BIND_SERVICE` para bind na porta 53
- **Filesystem Isolado**: Proteção de sistema de arquivos e home
- **Namespaces Restritos**: Sem acesso a recursos desnecessários
- **No New Privileges**: Previne escalação de privilégios
- **Memory Protection**: MemoryDenyWriteExecute habilitado

## Arquitetura

```
Aplicação
    ↓
127.0.0.1:53 (DNS Proxy)
    ↓
[Cache Check]
    ↓ (miss)
Upstreams (com fallback)
    - 1.1.1.1:53
    - 1.0.0.1:53
    - 8.8.8.8:53
    - 9.9.9.9:53
```

## Troubleshooting

### Porta 53 Já em Uso

Se você receber erro de porta já em uso, verifique se systemd-resolved está rodando:

```bash
systemctl status systemd-resolved

# Desabilitar systemd-resolved (opcional)
# Descomente no default.nix:
# services.resolved.enable = false;
```

### Cache Não Está Funcionando

Verifique os logs para confirmar que as respostas estão sendo cacheadas:

```bash
journalctl -fu dns-proxy.service | grep -i cache
```

### Alto Número de Erros

Se você ver muitos erros nas estatísticas, pode ser problema com os upstreams:

1. Teste conectividade com os upstreams manualmente
2. Considere mudar a ordem ou remover upstreams problemáticos
3. Aumente o timeout se sua conexão for lenta

## Integração com Outros Serviços

### VPN

O proxy DNS funciona bem com VPNs. Configure sua VPN para **não** sobrescrever /etc/resolv.conf:

```nix
{
  kernelcore.network.vpn.nordvpn = {
    enable = true;
    overrideDNS = false;  # Mantém o proxy DNS
  };
}
```

### Docker

Containers Docker automaticamente herdarão o resolver do sistema:

```bash
docker run --rm alpine nslookup google.com
# Usará 127.0.0.1:53 automaticamente
```

### systemd-resolved

Por padrão, o módulo configura o proxy para iniciar **antes** do systemd-resolved, garantindo que o proxy esteja disponível quando outros serviços precisarem de DNS.

## Desenvolvimento

### Estrutura de Arquivos

```
modules/network/dns/
├── default.nix              # Módulo NixOS
├── main.go                  # Código do proxy DNS
├── go.mod                   # Dependências Go
├── go.sum                   # Checksums das dependências
├── config.example.json      # Exemplo de configuração
└── README.md               # Esta documentação
```

### Modificar o Código

Para modificar o código Go:

1. Edite `main.go`
2. Atualize o hash do vendor se necessário
3. Execute `nix flake check` para validar
4. Execute `sudo nixos-rebuild switch` para aplicar

### Atualizar Dependências

```bash
cd modules/network/dns
go get -u github.com/miekg/dns
go mod tidy
# Atualize vendorHash no default.nix se necessário
```

## Referências

- **miekg/dns**: Biblioteca DNS Go usada - https://github.com/miekg/dns
- **RFC 1035**: DNS Specification - https://www.rfc-editor.org/rfc/rfc1035

## Licença

MIT

## Autor

kernelcore @ VoidNxLabs
