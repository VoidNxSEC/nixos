#!/usr/bin/env bash

set -e # Exit immediately if a command exits with a non-zero status

AUDIT_DIR="/tmp/lynis-audit"

echo "========================================="
echo "  Iniciando a sequência de auditoria Lynis"
echo "========================================="

echo ""
echo ">>> 1. Limpando diretório de relatórios antigos: ${AUDIT_DIR}"
sudo rm -rf "${AUDIT_DIR}"
sudo mkdir -p "${AUDIT_DIR}"
echo "    Diretório criado/limpo com sucesso."

echo ""
echo ">>> 2. Reconstruindo o sistema NixOS com as últimas alterações..."
# Adiciona /etc/nixos como diretório seguro para o Git quando rodado como root
# Isso resolve o problema "repository path '/etc/nixos' is not owned by current user"
sudo git config --global --add safe.directory /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#kernelcore --max-jobs 8 --cores 8
echo "    Reconstrução do NixOS concluída."

echo ""
echo ">>> 3. Executando auditoria Lynis em modo FORENSICS..."
sudo audit-system audit system \
  --forensics \
  --verbose \
  --auditor kernelcore \
  --report-file "${AUDIT_DIR}/report-forensics.dat" \
  --log-file "${AUDIT_DIR}/lynis-forensics.log"
echo "    Auditoria FORENSICS concluída. Relatórios em: ${AUDIT_DIR}/report-forensics.dat"

echo ""
echo ">>> 4. Executando auditoria Lynis em modo PENTEST..."
sudo audit-system audit system \
  --pentest \
  --verbose \
  --auditor kernelcore \
  --report-file "${AUDIT_DIR}/report-pentest.dat" \
  --log-file "${AUDIT_DIR}/lynis-pentest.log"
echo "    Auditoria PENTEST concluída. Relatórios em: ${AUDIT_DIR}/report-pentest.dat"

echo ""
echo "========================================="
echo "  Sequência de auditoria Lynis FINALIZADA"
echo "  Verifique os relatórios em: ${AUDIT_DIR}"
echo "========================================="
