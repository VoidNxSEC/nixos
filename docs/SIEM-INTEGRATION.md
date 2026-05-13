# Integração SIEM - Lynis Security Audit Pipeline

## Visão Geral

Este documento descreve como integrar os relatórios do Lynis com ferramentas SIEM (Security Information and Event Management) como **Wazuh**, **OSSEC**, **ELK Stack** e outras.

---

## Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────────┐
│                     NixOS Hardened System                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐ │
│  │   Lynis      │─────>│ Parser/      │─────>│ Log Forward  │ │
│  │   Audit      │      │ Normalizer   │      │ (syslog/json)│ │
│  └──────────────┘      └──────────────┘      └──────────────┘ │
│                                                       │         │
└───────────────────────────────────────────────────────┼─────────┘
                                                        │
                                                        v
                     ┌──────────────────────────────────────┐
                     │        SIEM Platform                 │
                     ├──────────────────────────────────────┤
                     │  • Wazuh Manager                     │
                     │  • OSSEC Server                      │
                     │  • ELK Stack (Elasticsearch/Logstash)│
                     │  • Splunk                            │
                     │  • Graylog                           │
                     └──────────────────────────────────────┘
                                    │
                                    v
                     ┌──────────────────────────────────────┐
                     │   Alertas e Dashboards               │
                     ├──────────────────────────────────────┤
                     │  • Email/Slack/PagerDuty             │
                     │  • Grafana Dashboards                │
                     │  • Kibana Visualizations             │
                     └──────────────────────────────────────┘
```

---

## Opção 1: Integração com Wazuh

### Por que Wazuh?
- **Open Source** e gratuito
- **Baseado em OSSEC** (battle-tested)
- **File Integrity Monitoring (FIM)**
- **Rootkit Detection**
- **Compliance Management** (PCI-DSS, GDPR, HIPAA)
- **Integration com ELK Stack**

### Configuração do Wazuh Agent

#### 1. Adicionar Wazuh ao NixOS

Crie o módulo `/etc/nixos/modules/security/wazuh-agent.nix`:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.wazuh-agent;
in
{
  options.services.wazuh-agent = {
    enable = mkEnableOption "Wazuh Security Agent";

    serverAddress = mkOption {
      type = types.str;
      example = "192.168.1.100";
      description = "Wazuh manager server address";
    };

    serverPort = mkOption {
      type = types.port;
      default = 1514;
      description = "Wazuh manager port";
    };

    agentName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Agent name (defaults to hostname)";
    };
  };

  config = mkIf cfg.enable {
    # Instalar Wazuh agent via tar-packages ou nixpkgs
    environment.systemPackages = [ pkgs.wazuh-agent ];

    # Configuração do agente
    environment.etc."ossec/ossec.conf".text = ''
      <ossec_config>
        <client>
          <server>
            <address>${cfg.serverAddress}</address>
            <port>${toString cfg.serverPort}</port>
            <protocol>tcp</protocol>
          </server>
        </client>

        <!-- Lynis Integration -->
        <localfile>
          <log_format>syslog</log_format>
          <location>/tmp/lynis-audit/lynis.log</location>
        </localfile>

        <localfile>
          <log_format>json</log_format>
          <location>/tmp/lynis-audit/report.json</location>
        </localfile>

        <!-- System logs -->
        <localfile>
          <log_format>syslog</log_format>
          <location>/var/log/auth.log</location>
        </localfile>

        <localfile>
          <log_format>syslog</log_format>
          <location>/var/log/secure</location>
        </localfile>

        <!-- Rootkit detection -->
        <rootcheck>
          <disabled>no</disabled>
          <check_files>yes</check_files>
          <check_trojans>yes</check_trojans>
          <check_dev>yes</check_dev>
          <check_sys>yes</check_sys>
          <check_pids>yes</check_pids>
          <check_ports>yes</check_ports>
          <check_if>yes</check_if>
        </rootcheck>

        <!-- File Integrity Monitoring -->
        <syscheck>
          <disabled>no</disabled>
          <frequency>43200</frequency> <!-- 12 hours -->
          <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
          <directories check_all="yes">/bin,/sbin</directories>
          <ignore>/etc/mtab</ignore>
          <ignore>/etc/hosts.deny</ignore>
          <ignore>/etc/mail/statistics</ignore>
        </syscheck>
      </ossec_config>
    '';

    # Systemd service
    systemd.services.wazuh-agent = {
      description = "Wazuh Security Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.wazuh-agent}/bin/wazuh-control start";
        ExecStop = "${pkgs.wazuh-agent}/bin/wazuh-control stop";
        PIDFile = "/var/ossec/var/run/wazuh-agentd.pid";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
```

#### 2. Habilitar no configuration.nix

```nix
services.wazuh-agent = {
  enable = true;
  serverAddress = "192.168.1.100";  # IP do Wazuh Manager
  agentName = "nixos-hardened";
};
```

---

## Opção 2: Integração com ELK Stack

### Logstash Pipeline para Lynis

Crie `/etc/logstash/conf.d/lynis.conf`:

```ruby
input {
  file {
    path => "/tmp/lynis-audit/report.dat"
    start_position => "beginning"
    sincedb_path => "/dev/null"
    tags => ["lynis", "security_audit"]
  }
}

filter {
  # Parse Lynis report.dat format
  if "lynis" in [tags] {
    kv {
      field_split => "="
      value_split => ","
    }

    # Categorize by type
    if [message] =~ /^warning\[\]=/ {
      mutate {
        add_field => { "severity" => "warning" }
        add_field => { "category" => "security" }
      }
    }

    if [message] =~ /^suggestion\[\]=/ {
      mutate {
        add_field => { "severity" => "suggestion" }
        add_field => { "category" => "optimization" }
      }
    }

    # Extract hardening index
    if [message] =~ /^hardening_index=(\d+)/ {
      mutate {
        add_field => { "hardening_score" => "%{[1]}" }
      }
    }

    # Add timestamp
    date {
      match => [ "timestamp", "UNIX" ]
      target => "@timestamp"
    }
  }
}

output {
  if "lynis" in [tags] {
    elasticsearch {
      hosts => ["localhost:9200"]
      index => "lynis-audit-%{+YYYY.MM.dd}"
    }

    # Also send to stdout for debugging
    stdout {
      codec => rubydebug
    }
  }
}
```

### Filebeat Configuration

Alternativa mais leve que Logstash:

```yaml
# /etc/filebeat/filebeat.yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /tmp/lynis-audit/lynis.log
    fields:
      type: lynis
      environment: production
    fields_under_root: true

output.elasticsearch:
  hosts: ["localhost:9200"]
  index: "lynis-audit-%{+yyyy.MM.dd}"

setup.kibana:
  host: "localhost:5601"

setup.dashboards.enabled: true
```

---

## Opção 3: Script de Conversão para JSON

Para facilitar a integração, vamos criar um conversor **Lynis DAT → JSON**:

```python
#!/usr/bin/env python3
"""
Converte report.dat do Lynis para JSON estruturado
Útil para integração com SIEM/APIs
"""

import json
import sys
from datetime import datetime
from pathlib import Path

def parse_lynis_to_json(report_path):
    """Converte report.dat para JSON estruturado"""

    data = {
        "timestamp": datetime.now().isoformat(),
        "warnings": [],
        "suggestions": [],
        "tests": {},
        "metadata": {}
    }

    with open(report_path, 'r') as f:
        for line in f:
            line = line.strip()

            if '=' not in line:
                continue

            key, value = line.split('=', 1)

            # Arrays
            if '[]' in key:
                field = key.replace('[]', '')
                if field not in data:
                    data[field] = []
                data[field].append(value)

            # Tests (key-value pairs)
            elif key.startswith('test_'):
                data['tests'][key] = value

            # Metadata
            else:
                data['metadata'][key] = value

    return data

def main():
    report_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/lynis-audit/report.dat'
    output_path = report_path.replace('.dat', '.json')

    data = parse_lynis_to_json(report_path)

    with open(output_path, 'w') as f:
        json.dump(data, f, indent=2)

    print(f"✅ JSON gerado: {output_path}")
    print(f"📊 Warnings: {len(data.get('warning', []))}")
    print(f"💡 Suggestions: {len(data.get('suggestion', []))}")

if __name__ == '__main__':
    main()
```

Salve como `/etc/nixos/scripts/lynis-to-json.py` e execute:

```bash
python3 /etc/nixos/scripts/lynis-to-json.py /tmp/lynis-audit/report.dat
```

---

## Opção 4: Integração via Syslog

Enviar logs do Lynis via syslog para um servidor SIEM remoto:

### Configuração rsyslog

```bash
# /etc/rsyslog.d/50-lynis.conf

# Forward Lynis logs to remote SIEM
module(load="imfile")

input(type="imfile"
      File="/tmp/lynis-audit/lynis.log"
      Tag="lynis"
      Severity="info"
      Facility="local7")

# Forward to SIEM server
*.* @@siem-server.example.com:514
```

Reinicie o rsyslog:
```bash
systemctl restart rsyslog
```

---

## Automação: Auditoria Agendada

### Criar Systemd Timer

```nix
# Em configuration.nix ou módulo dedicado

systemd.timers.lynis-audit = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
    Unit = "lynis-audit.service";
  };
};

systemd.services.lynis-audit = {
  description = "Lynis Security Audit";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/run-lynis-audits.sh";
    User = "root";
  };
};
```

Isso executará a auditoria **diariamente** e enviará os logs para o SIEM automaticamente.

---

## Dashboard Grafana

### Datasource: Elasticsearch

Crie queries Grafana para visualizar:

1. **Security Score Over Time**
   ```
   Metric: hardening_index
   Visualization: Line Chart
   ```

2. **Warnings by Category**
   ```
   Metric: count(warning)
   Group by: category
   Visualization: Pie Chart
   ```

3. **Critical Alerts**
   ```
   Filter: severity == "critical"
   Visualization: Table
   ```

---

## Alertas

### Configuração de Alertas no Wazuh

```xml
<!-- /var/ossec/etc/rules/local_rules.xml -->

<group name="lynis,security,">
  <!-- Alert on critical warnings -->
  <rule id="100001" level="12">
    <if_sid>530</if_sid>
    <match>warning.*critical</match>
    <description>Lynis detected critical security warning</description>
    <group>lynis,critical,</group>
  </rule>

  <!-- Alert on hardening score drop -->
  <rule id="100002" level="10">
    <if_sid>530</if_sid>
    <match>hardening_index</match>
    <description>System hardening index changed</description>
    <group>lynis,hardening,</group>
  </rule>
</group>
```

### Integração com Slack/Email

```bash
# /var/ossec/etc/ossec.conf

<integration>
  <name>slack</name>
  <hook_url>https://hooks.slack.com/services/YOUR/WEBHOOK/URL</hook_url>
  <level>10</level>
  <alert_format>json</alert_format>
</integration>

<global>
  <email_notification>yes</email_notification>
  <email_to>security@example.com</email_to>
  <smtp_server>smtp.gmail.com</smtp_server>
  <email_from>wazuh@example.com</email_from>
</global>
```

---

## Roadmap Futuro

### Extensões Planejadas

1. **Custom Lynis Plugins**
   - Plugin para auditar configurações NixOS específicas
   - Verificação de flake.lock integrity
   - Auditoria de secrets SOPS

2. **ML-based Anomaly Detection**
   - Treinar modelo para detectar padrões anormais
   - Baseline behavior establishment
   - Alertas inteligentes

3. **Automated Remediation**
   - Auto-aplicar sugestões de baixo risco
   - Pull request automation para fixes
   - Rollback automático em falhas

4. **Integration com Nix Binary Cache**
   - Auditoria de packages do cache
   - CVE scanning de derivações
   - Supply chain security

---

## Exemplo: Pipeline Completo

```bash
#!/usr/bin/env bash
# Pipeline completo de auditoria → SIEM

# 1. Executar auditoria
sudo audit-system audit system --forensics

# 2. Converter para JSON
python3 /etc/nixos/scripts/lynis-to-json.py /tmp/lynis-audit/report.dat

# 3. Enviar para SIEM
curl -X POST https://siem.example.com/api/events \
  -H "Content-Type: application/json" \
  -d @/tmp/lynis-audit/report.json

# 4. Gerar relatório HTML
lynis-report

# 5. Notificar via Slack
SCORE=$(grep hardening_index /tmp/lynis-audit/report.dat | cut -d= -f2)
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"🛡️ Security Audit Complete! Score: $SCORE/100\"}"
```

---

## Recursos Adicionais

- **Wazuh Documentation**: https://documentation.wazuh.com/
- **OSSEC Rules**: https://www.ossec.net/docs/
- **Lynis Enterprise**: https://cisofy.com/lynis/
- **ELK Stack**: https://www.elastic.co/elk-stack
- **Grafana Dashboards**: https://grafana.com/grafana/dashboards/

---

## Contribuindo

Para adicionar novas integrações ou melhorias:

1. Crie um módulo em `/etc/nixos/modules/security/siem/`
2. Documente no README
3. Adicione testes de integração
4. Submeta um PR

---

**Última Atualização**: 2025-12-08
**Mantido por**: kernelcore
**Licença**: MIT
