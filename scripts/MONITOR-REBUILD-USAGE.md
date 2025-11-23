# Monitor Rebuild - Guia de Uso

Script avançado de monitoramento para diagnosticar problemas durante `nixos-rebuild`.

## Características Principais

### Monitoramento Abrangente
- **Memória**: Uso, swap, análise de capacidade de fork
- **CPU**: Utilização, load average
- **Temperatura**: CPU, GPU (NVIDIA), NVMe
- **Disco**: Uso de /, /nix, /tmp, crescimento do nix-store
- **Processos**: Nix-daemon, compiladores, limites do sistema
- **Rede**: Download de caches binários
- **File Descriptors**: Detecção de vazamentos
- **Fork Analysis**: **CRÍTICO** - Detecta condições que causam "unable to fork"

### Recursos Avançados
- Envio automático de logs para desktop via SSH
- Relatório HTML interativo
- Execução integrada do rebuild
- Detecção de OOM killer
- Análise de journal em tempo real
- Sugestões automáticas de configuração

## Uso Básico

### 1. Monitorar um rebuild manual
```bash
# Terminal 1: Iniciar monitoramento
cd /etc/nixos/scripts
sudo ./monitor-rebuild.sh

# Terminal 2: Executar rebuild
sudo nixos-rebuild switch
```

### 2. Monitorar e executar rebuild automaticamente
```bash
sudo ./monitor-rebuild.sh -r
```

### 3. Monitorar e enviar logs para desktop
```bash
# Envio automático para 192.168.15.7 (padrão)
sudo ./monitor-rebuild.sh -r

# Especificar desktop diferente
sudo ./monitor-rebuild.sh -r -d 192.168.15.10 -u myuser
```

### 4. Monitoramento local apenas (sem envio SSH)
```bash
sudo ./monitor-rebuild.sh -r -n
```

## Opções Disponíveis

```
-i INTERVAL    Intervalo de coleta em segundos (padrão: 2s)
-r             Executar rebuild automaticamente
-d DESKTOP     IP do desktop para envio de logs (padrão: 192.168.15.7)
-u USER        Usuário SSH no desktop (padrão: kernelcore)
-p PATH        Caminho remoto para logs (padrão: ~/rebuild-diagnostics)
-n             Não enviar logs para desktop
-v             Modo verbose
-h             Mostrar ajuda
```

## Exemplos de Uso

### Diagnóstico de "unable to fork"
```bash
# Monitorar com intervalo de 1s para capturar problemas rápidos
sudo ./monitor-rebuild.sh -i 1 -r

# O script irá alertar quando:
# - Memória disponível < 512MB (CRITICAL)
# - Memória disponível < 1GB (WARNING)
# - Detectar falhas de fork no kernel log
# - Sugerir configuração de max-jobs adequada
```

### Análise de temperatura durante rebuild
```bash
# Monitorar temperaturas a cada 2 segundos
sudo ./monitor-rebuild.sh -r

# Alertas:
# - CPU > 85°C: CRITICAL
# - CPU > 75°C: WARNING
# - GPU > 80°C: WARNING
```

### Monitoramento contínuo em background
```bash
# Iniciar monitoramento em background
sudo ./monitor-rebuild.sh -r > /tmp/rebuild-monitor.out 2>&1 &

# Ver progresso em tempo real
tail -f /tmp/rebuild-monitor.out

# Parar monitoramento
sudo pkill -f monitor-rebuild.sh
```

## Saída Gerada

O script cria um diretório em `/tmp/rebuild-monitor-YYYYMMDD-HHMMSS/` com:

### Arquivos CSV (análise detalhada)
- `memory.csv` - Histórico de uso de memória
- `cpu.csv` - Histórico de CPU e load
- `temperature.csv` - Histórico de temperaturas
- `disk.csv` - Uso de disco por partição
- `nix-store.csv` - Crescimento do nix-store
- `network.csv` - Tráfego de rede
- `file-descriptors.csv` - FDs abertos
- `process-limits.csv` - Limites de processos/threads
- `fork-analysis.csv` - **IMPORTANTE** - Análise de capacidade de fork
- `processes.csv` - Processos de compilação ativos

### Logs
- `monitor.log` - Log principal com eventos e alertas
- `journal.log` - Logs do nix-daemon service
- `top-consumers.log` - Processos que mais consomem recursos
- `rebuild.log` - Output completo do rebuild (se `-r` usado)

### Relatórios
- `report.txt` - Relatório texto com resumo
- `report.html` - Relatório HTML interativo
- `rebuild-status.txt` - Código de saída do rebuild

## Envio para Desktop

### Configuração SSH

Certifique-se de ter chaves SSH configuradas:

```bash
# No laptop (onde executa o script)
ssh-keygen -t ed25519 -C "rebuild-monitor"
ssh-copy-id kernelcore@192.168.15.7

# Testar conectividade
ssh kernelcore@192.168.15.7 "mkdir -p ~/rebuild-diagnostics"
```

### Arquivos Enviados

1. **Archive completo**: `rebuild-monitor-YYYYMMDD-HHMMSS.tar.gz`
   - Todos os CSVs, logs e relatórios compactados

2. **Relatório HTML**: `latest-report.html`
   - Último relatório para visualização rápida

### Visualizar Relatórios no Desktop

```bash
# No desktop (192.168.15.7)
cd ~/rebuild-diagnostics

# Listar relatórios
ls -lht

# Abrir último relatório HTML no navegador
firefox latest-report.html

# Extrair archive para análise detalhada
tar -xzf rebuild-monitor-YYYYMMDD-HHMMSS.tar.gz
cd rebuild-monitor-YYYYMMDD-HHMMSS

# Analisar CSVs com ferramentas de sua preferência
# Ex: csvkit, pandas, R, gnuplot, etc.
```

## Análise de Dados

### Usando csvkit (recomendado)

```bash
# Instalar csvkit
nix-shell -p python3Packages.csvkit

# Estatísticas de memória
csvstat memory.csv

# Encontrar picos de memória
csvsort -r -c used_mb memory.csv | head -10

# Correlacionar temperatura com CPU
csvjoin -c timestamp temperature.csv cpu.csv
```

### Usando awk/grep

```bash
# Encontrar momentos críticos de memória
awk -F',' '$3 > 14000 {print $0}' memory.csv

# Listar todos os alertas críticos
grep "CRITICAL" monitor.log

# Contar falhas de fork
grep -c "unable to fork" monitor.log
```

## Diagnóstico de Problemas Comuns

### "unable to fork" durante rebuild

O script detecta e reporta:

1. **Memória disponível insuficiente** (< 512MB)
   - **Solução**: Aumentar swap ou reduzir max-jobs

2. **Muitos processos simultâneos**
   - **Solução**: Reduzir `nix.settings.max-jobs`

3. **Limite de threads atingido**
   - **Solução**: Aumentar `kernel.threads-max`

4. **Overcommit desabilitado**
   - **Solução**: Configurar `vm.overcommit_memory`

### OOM Killer ativado

```bash
# Verificar no relatório
grep "OOM" monitor.log

# Analisar processos mortos
grep "Out of memory" journal.log
```

### Temperaturas elevadas

```bash
# Ver picos de temperatura
csvsort -r -c cpu_temp temperature.csv | head -5

# Verificar throttling
grep "temperatura" monitor.log
```

## Recomendações de Configuração

Baseado na análise, o script pode sugerir:

### Para problemas de memória
```nix
# /etc/nixos/modules/system/nix.nix
nix.settings = {
  max-jobs = 2;  # Reduzir de 4 para 2
  cores = 2;     # Limitar cores por job
};

boot.kernel.sysctl = {
  "vm.overcommit_memory" = 1;  # Permitir overcommit
  "vm.swappiness" = 60;         # Usar swap mais cedo
};
```

### Para problemas de disco
```nix
# Habilitar garbage collection automático
nix.gc = {
  automatic = true;
  dates = "daily";
  options = "--delete-older-than 7d";
};

# Otimizar nix-store
nix.optimise.automatic = true;
```

## Troubleshooting

### Script não consegue conectar ao desktop

```bash
# Testar SSH manualmente
ssh -v kernelcore@192.168.15.7

# Verificar firewall
sudo ufw status

# Usar modo local
sudo ./monitor-rebuild.sh -n
```

### Permissões negadas

```bash
# Script precisa de sudo para:
# - Acessar logs do sistema
# - Monitorar todos os processos
# - Ler temperaturas de hardware
# - Executar nixos-rebuild

sudo ./monitor-rebuild.sh
```

### Dados de temperatura não disponíveis

```bash
# Instalar lm-sensors
nix-shell -p lm_sensors

# Detectar sensores
sudo sensors-detect

# Verificar sensores disponíveis
sensors
```

## Performance

O script foi otimizado para impacto mínimo:

- **CPU**: < 1% de overhead
- **Memória**: ~20MB
- **Disco**: ~5-50MB de logs (dependendo da duração)
- **Rede**: Apenas no final (envio de logs)

## Integração com CI/CD

```bash
# GitLab CI example
rebuild_job:
  script:
    - sudo /etc/nixos/scripts/monitor-rebuild.sh -r -d ci-server.local
  artifacts:
    paths:
      - /tmp/rebuild-monitor-*/report.html
    expire_in: 1 week
```

## Contato e Suporte

Para problemas ou sugestões:
- Abrir issue no repositório
- Consultar logs em `~/rebuild-diagnostics/`
- Executar com `-v` para debug verbose
