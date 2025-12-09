#!/usr/bin/env python3
"""
Lynis Report Generator - HTML Interactive Dashboard
Gera relatórios HTML bonitos e interativos a partir dos logs do Lynis
"""

import sys
import os
import re
from datetime import datetime
from pathlib import Path
from collections import defaultdict

def parse_lynis_report(report_path):
    """Parse o arquivo report.dat do Lynis"""
    data = {
        'warnings': [],
        'suggestions': [],
        'tests': [],
        'hardening_index': 0,
        'tests_performed': 0,
        'plugins_enabled': 0,
        'hostname': 'unknown',
        'os': 'unknown',
        'kernel': 'unknown',
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }

    if not Path(report_path).exists():
        return data

    with open(report_path, 'r') as f:
        for line in f:
            line = line.strip()

            # Warnings
            if line.startswith('warning[]='):
                warning = line.split('=', 1)[1]
                data['warnings'].append(warning)

            # Suggestions
            elif line.startswith('suggestion[]='):
                suggestion = line.split('=', 1)[1]
                data['suggestions'].append(suggestion)

            # Tests
            elif line.startswith('test[]='):
                test = line.split('=', 1)[1]
                data['tests'].append(test)

            # Hardening index
            elif line.startswith('hardening_index='):
                data['hardening_index'] = int(line.split('=')[1])

            # Hostname
            elif line.startswith('hostname='):
                data['hostname'] = line.split('=', 1)[1]

            # OS
            elif line.startswith('os='):
                data['os'] = line.split('=', 1)[1]

            # Kernel
            elif line.startswith('linux_version='):
                data['kernel'] = line.split('=', 1)[1]

            # Tests performed
            elif line.startswith('tests_performed='):
                data['tests_performed'] = int(line.split('=')[1])

            # Plugins
            elif line.startswith('plugins_enabled='):
                data['plugins_enabled'] = int(line.split('=')[1])

    return data

def categorize_warnings(warnings):
    """Categoriza warnings por severidade e tipo"""
    categories = defaultdict(list)

    for warning in warnings:
        # Detecção simples de categoria baseada em keywords
        warning_lower = warning.lower()

        if any(kw in warning_lower for kw in ['password', 'auth', 'permission', 'root']):
            categories['critical'].append(warning)
        elif any(kw in warning_lower for kw in ['firewall', 'port', 'service', 'daemon']):
            categories['high'].append(warning)
        elif any(kw in warning_lower for kw in ['update', 'package', 'version']):
            categories['medium'].append(warning)
        else:
            categories['low'].append(warning)

    return categories

def generate_html_report(data, output_path):
    """Gera relatório HTML interativo"""

    warnings_by_category = categorize_warnings(data['warnings'])

    # Calcula score de segurança
    security_score = data['hardening_index']
    score_color = 'red' if security_score < 50 else 'orange' if security_score < 75 else 'green'

    html_content = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lynis Security Audit - {data['hostname']}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}

        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            padding: 20px;
            line-height: 1.6;
        }}

        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }}

        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }}

        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }}

        .header .subtitle {{
            font-size: 1.2em;
            opacity: 0.9;
        }}

        .stats {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 30px;
            background: #f8f9fa;
        }}

        .stat-card {{
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }}

        .stat-card:hover {{
            transform: translateY(-5px);
            box-shadow: 0 8px 12px rgba(0,0,0,0.15);
        }}

        .stat-card h3 {{
            color: #667eea;
            font-size: 1em;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}

        .stat-card .value {{
            font-size: 2.5em;
            font-weight: bold;
            color: #333;
        }}

        .security-score {{
            text-align: center;
            padding: 40px;
            background: white;
        }}

        .score-circle {{
            width: 200px;
            height: 200px;
            border-radius: 50%;
            background: conic-gradient({score_color} {security_score}%, #e0e0e0 0);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            position: relative;
        }}

        .score-circle::before {{
            content: '';
            width: 160px;
            height: 160px;
            background: white;
            border-radius: 50%;
            position: absolute;
        }}

        .score-circle .score {{
            font-size: 3em;
            font-weight: bold;
            color: {score_color};
            z-index: 1;
        }}

        .section {{
            padding: 30px;
        }}

        .section h2 {{
            color: #667eea;
            margin-bottom: 20px;
            font-size: 2em;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }}

        .warning-card {{
            background: #fff3cd;
            border-left: 5px solid #ffc107;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
            transition: all 0.3s ease;
        }}

        .warning-card:hover {{
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            transform: translateX(5px);
        }}

        .warning-card.critical {{
            background: #f8d7da;
            border-left-color: #dc3545;
        }}

        .warning-card.high {{
            background: #fff3cd;
            border-left-color: #ffc107;
        }}

        .warning-card.medium {{
            background: #d1ecf1;
            border-left-color: #17a2b8;
        }}

        .warning-card.low {{
            background: #d4edda;
            border-left-color: #28a745;
        }}

        .suggestion-card {{
            background: #d1ecf1;
            border-left: 5px solid #17a2b8;
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
            transition: all 0.3s ease;
        }}

        .suggestion-card:hover {{
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            transform: translateX(5px);
        }}

        .badge {{
            display: inline-block;
            padding: 5px 10px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            margin-right: 10px;
        }}

        .badge.critical {{ background: #dc3545; color: white; }}
        .badge.high {{ background: #ffc107; color: #333; }}
        .badge.medium {{ background: #17a2b8; color: white; }}
        .badge.low {{ background: #28a745; color: white; }}

        .footer {{
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }}

        .timestamp {{
            color: #999;
            font-style: italic;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Lynis Security Audit</h1>
            <div class="subtitle">{data['hostname']} - {data['os']}</div>
            <div class="timestamp">Gerado em: {data['timestamp']}</div>
        </div>

        <div class="stats">
            <div class="stat-card">
                <h3>Testes Realizados</h3>
                <div class="value">{data['tests_performed']}</div>
            </div>
            <div class="stat-card">
                <h3>Warnings</h3>
                <div class="value" style="color: #ffc107;">{len(data['warnings'])}</div>
            </div>
            <div class="stat-card">
                <h3>Sugestões</h3>
                <div class="value" style="color: #17a2b8;">{len(data['suggestions'])}</div>
            </div>
            <div class="stat-card">
                <h3>Plugins Ativos</h3>
                <div class="value" style="color: #28a745;">{data['plugins_enabled']}</div>
            </div>
        </div>

        <div class="security-score">
            <h2 style="color: #667eea; margin-bottom: 20px;">Security Score</h2>
            <div class="score-circle">
                <div class="score">{security_score}</div>
            </div>
            <p style="color: #666; font-size: 1.1em;">Índice de Hardening do Sistema</p>
        </div>

        <div class="section">
            <h2>⚠️ Warnings Detectados ({len(data['warnings'])})</h2>
"""

    # Adiciona warnings categorizados
    for severity in ['critical', 'high', 'medium', 'low']:
        if warnings_by_category[severity]:
            html_content += f"<h3 style='margin-top: 20px; color: #666;'>{severity.upper()} ({len(warnings_by_category[severity])})</h3>\n"
            for warning in warnings_by_category[severity]:
                html_content += f"""
            <div class="warning-card {severity}">
                <span class="badge {severity}">{severity.upper()}</span>
                {warning}
            </div>
"""

    if not data['warnings']:
        html_content += '<p style="color: #28a745; font-size: 1.2em;">✅ Nenhum warning detectado!</p>'

    html_content += """
        </div>

        <div class="section">
            <h2>💡 Sugestões de Melhoria ({len(data['suggestions'])})</h2>
"""

    for suggestion in data['suggestions'][:20]:  # Limita a 20 sugestões
        html_content += f"""
            <div class="suggestion-card">
                {suggestion}
            </div>
"""

    if len(data['suggestions']) > 20:
        html_content += f'<p style="color: #666; font-style: italic;">... e mais {len(data["suggestions"]) - 20} sugestões.</p>'

    if not data['suggestions']:
        html_content += '<p style="color: #28a745; font-size: 1.2em;">✅ Sistema otimizado - sem sugestões!</p>'

    html_content += f"""
        </div>

        <div class="footer">
            <p><strong>NixOS Hardened Security Audit</strong></p>
            <p>Gerado por Lynis Security Suite - {data['timestamp']}</p>
            <p>Kernel: {data['kernel']} | OS: {data['os']}</p>
        </div>
    </div>
</body>
</html>
"""

    with open(output_path, 'w') as f:
        f.write(html_content)

    print(f"✅ Relatório HTML gerado: {output_path}")

def main():
    report_path = sys.argv[1] if len(sys.argv) > 1 else '/tmp/lynis-audit/report.dat'
    output_path = sys.argv[2] if len(sys.argv) > 2 else '/tmp/lynis-audit/report.html'

    print(f"📊 Gerando relatório HTML...")
    print(f"   Fonte: {report_path}")
    print(f"   Saída: {output_path}")

    data = parse_lynis_report(report_path)
    generate_html_report(data, output_path)

    print(f"")
    print(f"🌐 Abra o relatório com:")
    print(f"   firefox {output_path}")
    print(f"   ou")
    print(f"   chromium {output_path}")

if __name__ == '__main__':
    main()
