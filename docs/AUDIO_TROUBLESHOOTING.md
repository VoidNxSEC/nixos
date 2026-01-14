# Troubleshooting de Áudio no NixOS (PipeWire/WirePlumber)

Este documento detalha o processo de diagnóstico e resolução de problemas de áudio identificados em sistemas NixOS utilizando PipeWire, com foco específico em hardware Intel SOF (Sound Open Firmware) e NVIDIA HDA.

**Data:** 11 de Dezembro de 2025
**Sistema:** NixOS Linux
**Hardware de Áudio:** Intel Raptor Lake-P/U/H cAVS (SOF) & NVIDIA GA107

---

## 1. Diagnóstico Inicial

### 1.1 Identificação do Problema
O sistema não emitia som pelos alto-falantes internos e o microfone não capturava áudio, apesar dos drivers do kernel estarem carregados corretamente.

### 1.2 Verificação de Hardware e Drivers
O primeiro passo é confirmar se o hardware é reconhecido e se os módulos do kernel apropriados estão carregados.

**Comando:**
```bash
lspci -nnk | grep -A3 -i audio
```

**Saída Observada:**
```
00:1f.3 Class 0401: 8086:51ca sof-audio-pci-intel-tgl
        Kernel driver in use: sof-audio-pci-intel-tgl
        Kernel modules: snd_sof_pci_intel_tgl

01:00.1 Class 0403: 10de:2291
        Kernel driver in use: snd_hda_intel
        Kernel modules: snd_hda_intel
```

**Análise:**
*   **Intel SOF:** O driver `sof-audio-pci-intel-tgl` está ativo para o áudio integrado.
*   **NVIDIA:** O driver `snd_hda_intel` está ativo para áudio via HDMI/DP.
*   **Conclusão:** Não há falha de carregamento de drivers.

### 1.3 Estado do Servidor de Áudio (PipeWire)
Verificar o status do servidor de áudio, clientes conectados e estado dos dispositivos (sinks/sources).

**Comando:**
```bash
wpctl status
```

**Saída Observada (Trecho):**
```
Audio
 ├─ Devices:
 │      47. GA107 High Definition Audio Controller [alsa]
 │      48. Raptor Lake-P/U/H cAVS              [alsa]
 ├─ Sinks:
 │     165. Raptor Lake-P/U/H cAVS Speaker      [vol: 1.20 MUTED]
 │  *   62. GA107 High Definition Audio Controller Pro 9 [vol: 1.00]
 ├─ Sources:
 │  *  281. Raptor Lake-P/U/H cAVS Digital Microphone [vol: 1.00 MUTED]
```

**Análise:**
1.  **Alto-falantes Mutados:** O sink `165` (Speaker) estava com status `MUTED`.
2.  **Microfone Mutado:** A source `281` (Digital Microphone) estava com status `MUTED`.
3.  **Sink Padrão Incorreto:** O sink padrão (marcado com `*`) era o ID `62` (NVIDIA HDMI), não os alto-falantes internos.

---

## 2. Resolução

### 2.1 Desmutar Alto-falantes
Para restaurar a saída de áudio, é necessário desmutar o sink específico.

**Comando:**
```bash
# Sintaxe: wpctl set-mute <ID> <0=unmute|1=mute>
wpctl set-mute 165 0
```

### 2.2 Desmutar Microfone
Procedimento similar para a entrada de áudio.

**Comando:**
```bash
wpctl set-mute 281 0
```

### 2.3 Definir Dispositivo Padrão (Opcional)
Para garantir que o áudio saia pelos alto-falantes internos por padrão, em vez do HDMI.

**Comando:**
```bash
# Sintaxe: wpctl set-default <ID>
wpctl set-default 165
```

---

## 3. Comandos de Verificação e Monitoramento

Use estes comandos para validar a correção e monitorar o sistema de áudio.

| Ação | Comando | Resultado Esperado |
| :--- | :--- | :--- |
| **Listar Dispositivos** | `wpctl status` | Árvore de dispositivos sem a flag `MUTED` nos itens desejados. |
| **Testar Saída** | `speaker-test -c 2 -l 1` | Ruído rosa alternando entre canais esquerdo e direito. |
| **Monitorar Logs** | `journalctl --user -u pipewire -f` | Logs em tempo real do serviço PipeWire. |
| **Verificar Drivers** | `lsmod | grep snd` | Lista de módulos de som carregados (ex: `snd_sof`, `snd_hda_intel`). |

---

## 4. Notas Técnicas sobre SOF (Sound Open Firmware)

O hardware Intel mais recente (Tiger Lake, Alder Lake, Raptor Lake) utiliza a arquitetura SOF.

*   **Firmware:** Requer firmware binário assinado (`/lib/firmware/intel/sof*`).
*   **Dependência:** O pacote `alsa-firmware` ou `sof-firmware` deve estar presente no `configuration.nix`.
*   **Problemas Comuns:** Se o `dmesg` reportar "firmware load failed", verifique se `hardware.enableAllFirmware = true;` ou `hardware.firmware = [ pkgs.sof-firmware ];` está configurado.

## 5. Logs de Erro Relevantes (Ignorados)

Durante a investigação, logs de firewall (`refused packet`) foram observados no `dmesg`. Estes são **irrelevantes** para o subsistema de áudio e referem-se a tráfego de rede (mDNS/UDP 5353) bloqueado, não devendo confundir o diagnóstico de hardware.
