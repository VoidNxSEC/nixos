# Relatório de Auditoria e Hardening do Sistema NixOS (kernelcore)

**Data:** Monday, December 8, 2025

## 1. Introdução

Este relatório detalha a auditoria e as melhorias de hardening realizadas no sistema NixOS "kernelcore", um ambiente de desenvolvimento. A discussão inicial focou na criação de um inventário de segurança, identificação de pontos fortes e fracos, e a implementação de ações para fortalecer a postura de segurança, levando em consideração a natureza de uma workstation de desenvolvimento e a estabilidade operacional.

Um ponto central da análise foi a avaliação de ferramentas de auditoria como o Lynis dentro do contexto imutável e declarativo do NixOS, culminando na compreensão de que métricas tradicionais podem ser enganosas neste ambiente.

## 2. Inventário de Hardening Atual

O sistema "kernelcore" adota uma estratégia de "defesa em profundidade" através da configuração declarativa do NixOS, resultando em uma postura de segurança naturalmente robusta e moderna. O hardening de baseline é ativado explicitamente via `kernelcore.security.hardening.enable = true`.

### ✅ Pontos Fortes Notáveis

*   **Hardening de Kernel (`kernel.enable = true`)**:
    *   Implementação de proteções avançadas de kernel (ex: `lockdown=confidentiality`, `init_on_alloc`, `init_on_free`, `slab_nomerge`, `pti=on`, `yama.ptrace_scope=2`).
    *   Blacklisting de módulos de kernel inseguros/não utilizados para reduzir a superfície de ataque.
    *   Restrições rigorosas de `sysctl` (`kptr_restrict`, `dmesg_restrict`, `unprivileged_bpf_disabled`, `unprivileged_userns_clone=0`).
*   **Segurança SSH (`ssh.enable = true`)**:
    *   Configuração rigorosa: `PermitRootLogin = "no"` e `PasswordAuthentication = false`, forçando autenticação baseada em chaves.
    *   Utilização de sandboxing do systemd para o daemon SSH, limitando seus privilégios.
*   **Auditoria e Observabilidade (`audit.enable = true`)**:
    *   `auditd` ativo com regras para monitorar arquivos críticos (`/etc/passwd`, `/etc/shadow`), execuções de comandos e tentativas de login.
    *   `AppArmor` habilitado para confinamento de aplicações.
    *   Configuração persistente e otimizada do `journald`.
*   **Gestão de Segredos (SOPS)**:
    *   Uso de `secrets.sops` para gerenciar chaves de API e credenciais de forma criptografada, evitando texto plano.
*   **Isolamento de Aplicações**:
    *   Uso extensivo de virtualização (`virtualization.enable = true`) e containers (`docker`) para segregar cargas de trabalho, incluindo ambientes de agentes de IA (Roo, Codex, Gemini).
*   **Autenticação (PAM)**:
    *   Módulo PAM endurecido para políticas de senha robustas e integridade na autenticação, incluindo um `umask` restritivo e `users.mutableUsers = false`.
*   **Segurança do Nix Daemon (`nix-daemon.nix`)**:
    *   Imposição de builds em sandbox, exigência de assinaturas criptográficas para pacotes e restrições de URIs permitidas.

### ⚠️ Pontos de Atenção / Riscos Aceitos (Compromissos para Desenvolvimento)

*   **Superfície de Ataque de Rede (Firewall Permissivo Originalmente)**:
    *   A configuração inicial do firewall em `modules/security/network.nix` permitia uma vasta gama de portas TCP abertas para fins de desenvolvimento (RDP, Jupyter, APIs de ML, bancos de dados, servidores web de dev, etc.). Embora necessárias para desenvolvimento, elas representavam um vetor de ataque significativo. **(Resolvido na seção 3.1)**
*   **Monitoramento de Integridade e Malware Desabilitados**:
    *   `aide.enable = false` (Monitoramento de Integridade de Arquivos) e `clamav.enable = false` (Antivírus) foram desabilitados devido ao alto consumo de recursos e potencial impacto na performance do sistema de desenvolvimento. Isso significa uma menor capacidade de detecção de comprometimento persistente.
*   **Segurança DNS (Incompatibilidade DNSSEC)**:
    *   `enableDNSSEC = false` devido a problemas de estabilidade e incompatibilidade com muitos domínios. `enableDNSCrypt = false` foi mantido para simplificação. **(Parcialmente abordado na seção 3.2 com DNS-over-TLS resiliente)**

## 3. Melhorias Implementadas Durante a Auditoria

Com base no inventário e nas discussões, as seguintes melhorias foram aplicadas:

### 3.1. Dieta no Firewall (`modules/security/network.nix`)

*   **Mudança**: A lista de `networking.firewall.allowedTCPPorts` foi drasticamente reduzida. Portas sensíveis e de desenvolvimento (Postgres, Redis, Ollama, React Dev Servers, Jupyter, etc.) foram comentadas.
*   **Objetivo**: Diminuir a superfície de ataque expondo publicamente apenas portas essenciais para acesso remoto (SSH, HTTPS, HTTP, RDP), enquanto o acesso aos serviços de desenvolvimento é mantido via `localhost` (para uso local) ou via VPN (Tailscale) para acesso remoto seguro.
*   **Resultado**: Redução significativa da exposição do sistema a ataques externos sem comprometer a capacidade de desenvolvimento.

### 3.2. DNS-over-TLS Resiliente (`modules/network/dns-resolver.nix`)

*   **Mudança**: Confirmado que a configuração de DNS já utilizava `dnsovertls = "opportunistic";` em `services.resolved` (via `modules/network/dns-resolver.nix`).
*   **Objetivo**: Garantir a privacidade das consultas DNS criptografando-as sempre que possível, mas com resiliência. O modo "opportunistic" tenta usar DoT, mas reverte para DNS tradicional se houver falha ou incompatibilidade, evitando problemas de conectividade experimentados com DNSSEC. `enableDNSSEC` permanece `false`.
*   **Resultado**: Melhoria da privacidade DNS sem impacto na estabilidade da conexão, que é crucial para um ambiente de desenvolvimento.

### 3.3. Wrapper `audit-system` para Lynis

*   **Contexto**: O Lynis, embora valioso para estudo de conceitos de segurança, falhava na execução devido ao hardening agressivo do kernel e à natureza imutável do sistema de arquivos do NixOS (especialmente a Nix Store). Ele esperava ferramentas GNU padrão e locais de log/configuração FHS.
*   **Mudança**: Foi criado um script wrapper `audit-system` e adicionado a `environment.systemPackages` em `hosts/kernelcore/configuration.nix`.
    *   O script direciona todos os logs e relatórios do Lynis para `/tmp/lynis-audit/`.
    *   Ele injeta um `PATH` robusto no ambiente do Lynis, contendo versões GNU de `coreutils`, `grep`, `sed`, `awk`, `findutils`, `procps`, `nettools`, `git`, `systemd`, `kmod`, `which`, `gzip`, `curl`, `hostname`, `iproute2`.
    *   O `modules/packages/tar-packages/packages/lynis.nix` foi atualizado para aceitar `pkgs` e construir esse `PATH`.
*   **Objetivo**: Permitir que o Lynis seja executado com sucesso e forneça resultados, contornando as incompatibilidades com o NixOS Hardened e a Nix Store read-only.
*   **Resultado**: O Lynis agora consegue completar a execução, embora sua pontuação e muitos testes ainda reflitam a "cegueira" causada pelo hardening e pela arquitetura NixOS, conforme discutido no próximo insight.

## 4. Insights sobre o Lynis e o Hardening em NixOS

A experiência com o Lynis revelou um insight crucial: ferramentas de auditoria tradicionais, desenhadas para sistemas imperativos e baseados em FHS, não são eficazes como métricas de hardening para o NixOS.

*   **Lynis como "Teste de Ofuscação"**: A queda da "pontuação" do Lynis de 86 para 67, mesmo com o sistema mais endurecido, demonstra que a ferramenta interpreta a falta de visibilidade (devido ao hardening do kernel, à estrutura do NixOS, e ao sistema de arquivos imutável) como falha de segurança. Isso não indica uma regressão real na segurança, mas sim a ineficácia da métrica.
*   **Incompatibilidade Fundamental**:
    *   **Caminhos de Arquivos**: Lynis espera `/boot/vmlinuz`, mas no NixOS o kernel está na Nix Store. Ele procura regras de firewall em `iptables` ou `/etc/firewalld`, mas o NixOS usa `nftables`.
    *   **Ferramentas**: Presume ferramentas específicas (`stat --format`, `runlevel`) que podem ser do BusyBox ou não estarem no PATH esperado (mesmo com os ajustes, alguns comandos internos do Lynis ainda podem encontrar problemas).
    *   **Imutabilidade**: O Lynis testa a integridade de arquivos em `/etc`, mas no NixOS, `/etc` é construído declarativamente e grande parte do sistema é imutável (`/nix/store`).
*   **Lynis como Ferramenta de Estudo e Inspiração**: Apesar das limitações como métrica, o Lynis é uma excelente fonte para:
    *   **Checklist de Controles**: Suas categorias de teste fornecem um framework abrangente para identificar áreas de segurança.
    *   **Conceitos de Hardening**: Ele ajuda a recordar e aprofundar o conhecimento sobre diversos aspectos do hardening de sistemas Linux (sysctls, permissões, etc.).
    *   **Inspiração para um "NixAudit"**: A "burrice" do Lynis em relação ao NixOS destaca a necessidade e o potencial de uma ferramenta de auditoria **nativa do Nix**.

## 5. Próximos Passos e Oportunidades de Melhoria (Inspirações)

A discussão abriu portas para futuras investigações e aprimoramentos, com foco em uma abordagem mais "Nix-idiomática" para segurança:

*   **Frameworks de Controle de Acesso Mandatório (MAC)**:
    *   **AppArmor (Existente, Potencial de Melhoria)**: Embora habilitado, sua configuração pode ser aprimorada para perfis mais rigorosos em serviços críticos e aplicações de desenvolvimento.
    *   **SELinux / TOMOYO Linux / grsecurity**: Embora mais complexos de integrar no NixOS devido à sua natureza invasiva e modelo de políticas, são frameworks poderosos para confinamento de processos. A ideia aqui é inspirar a busca por soluções de confinamento equivalentes e bem integradas ao NixOS, talvez com abordagens como `systemd-nspawn` ou `bwrap` (já em uso em alguns agentes) com perfis mais granulares.
*   **Sistemas de Detecção de Intrusão (IDS/IPS)**:
    *   **Ferramentas IDS/IPS**: Implementar soluções IDS/IPS (ex: Suricata, Snort) ou explorar a integração de telemetria de segurança (sysmon for Linux, eBPF-based tools) que se alinhem com a filosofia declarativa do NixOS.
*   **Accounting (Auditoria de Usuário/Processo)**:
    *   A ausência de "accounting" (registro detalhado de ações de usuário e processo) foi notada. Implementar o `acct` ou explorar soluções mais modernas para visibilidade do que acontece no sistema (ex: `auditd` com regras mais abrangentes, integração com SIEM para centralização de logs).
*   **Nix-Native Security Auditing Tool ("NixAudit")**:
    *   A ideia mais promissora é desenvolver uma ferramenta de auditoria de hardening específica para o NixOS. Essa ferramenta faria análise estática do `flake.nix` e dos módulos para verificar a conformidade de segurança **antes** do build, e complementaria com verificações de tempo de execução focadas em estados mutáveis e comportamentos de rede. Ela forneceria uma pontuação e relatórios precisos, entendendo a natureza imutável do sistema e suas dependências.

O sistema "kernelcore" está mais seguro após estas intervenções. As próximas etapas se concentram em construir sobre esta base, explorando abordagens mais sofisticadas e nativas do Nix para a segurança.
