#!/usr/bin/env bash

# Cores para output militar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCORE=0
TOTAL_CHECKS=0

log_pass() {
  echo -e "[ ${GREEN}PASS${NC} ] $1"
  ((SCORE++))
  ((TOTAL_CHECKS++))
}

log_fail() {
  echo -e "[ ${RED}FAIL${NC} ] $1"
  echo -e "          -> Ação: $2"
  ((TOTAL_CHECKS++))
}

log_warn() {
  echo -e "[ ${YELLOW}WARN${NC} ] $1"
  ((TOTAL_CHECKS++))
}

echo -e "${BLUE}=== INICIANDO PROTOCOLO DE AUDITORIA (ANDURIL BASELINE) ===${NC}"
echo "Data: $(date)"
echo "Projeto: Algorand Stealth Lab"
echo "-----------------------------------------------------------"

# ==============================================================================
# FASE 1: SUPPLY CHAIN & NIX INTEGRITY
# ==============================================================================
echo -e "\n${BLUE}>>> FASE 1: SUPPLY CHAIN${NC}"

# Check 1: Flake Lock existe?
if [ -f "flake.lock" ]; then
  log_pass "flake.lock está presente (Determinismo garantido)"
else
  log_fail "flake.lock NÃO encontrado" "Execute 'nix flake update' para gerar o lockfile."
fi

# Check 2: Uso de Unstable (Proibido em High Assurance)
if grep -q "nixos-unstable" flake.nix; then
  log_warn "Uso de canal 'unstable' detectado."
  echo "          -> Risco: Updates não auditados podem quebrar o sistema ou introduzir malwares."
  echo "          -> Recomendação: Pinar para 'nixos-23.11' ou commit específico."
else
  log_pass "Canal Stable ou Pinado detectado."
fi

# Check 3: Verificação de Binários Sujos (Pip/Npm locais)
if [ -d "venv" ] || [ -d "node_modules" ]; then
  log_fail "Diretórios de gerenciadores imperativos detectados (venv/node_modules)" "Remova-os e use apenas o Nix Store."
else
  log_pass "Ambiente limpo de gerenciadores externos."
fi

# ==============================================================================
# FASE 2: HIGIENE DE SEGREDOS (DLP - Data Loss Prevention)
# ==============================================================================
echo -e "\n${BLUE}>>> FASE 2: CONTROLE DE DADOS SENSÍVEIS${NC}"

# Check 4: Varredura de Mnemônicos Algorand
# Procura padrões de 25 palavras ou strings suspeitas
SUSPICIOUS_FILES=$(grep -rE "([a-z]{3,}\s){24}[a-z]{3,}" . --exclude=bunker_audit.sh --exclude-dir=.git 2>/dev/null)

if [ -z "$SUSPICIOUS_FILES" ]; then
  log_pass "Nenhum mnemônico óbvio encontrado no código."
else
  log_fail "POSSÍVEL VAZAMENTO DE SEED PHRASE DETECTADO!" "Revise imediatamente os arquivos listados pelo grep."
fi

# Check 5: Arquivos .env comitados
if git ls-files | grep -q ".env"; then
  log_fail "Arquivo .env está rastreado pelo GIT!" "Execute: git rm --cached .env && echo .env >> .gitignore"
else
  log_pass "Nenhum arquivo .env rastreado no controle de versão."
fi

# ==============================================================================
# FASE 3: HARDENING DE RUNTIME (Se estiver rodando em Linux)
# ==============================================================================
echo -e "\n${BLUE}>>> FASE 3: KERNEL & REDE (Aplicável apenas em Linux Nativo)${NC}"

OS_NAME=$(uname)
if [ "$OS_NAME" == "Linux" ]; then
  # Check 6: Ptrace Scope (Impede que processos leiam memória de outros - Anti-Debugger)
  PTRACE=$(sysctl kernel.yama.ptrace_scope 2>/dev/null | awk '{print $3}')
  if [ "$PTRACE" == "1" ] || [ "$PTRACE" == "2" ] || [ "$PTRACE" == "3" ]; then
    log_pass "Kernel Hardening: Ptrace restrito (Valor: $PTRACE)"
  else
    log_fail "Kernel Hardening: Ptrace permissivo (Valor: $PTRACE)" "Adicione 'kernel.yama.ptrace_scope = 1' ao sysctl."
  fi

  # Check 7: IP Forwarding (Seu PC não deve ser um roteador)
  IP_FWD=$(sysctl net.ipv4.ip_forward 2>/dev/null | awk '{print $3}')
  if [ "$IP_FWD" == "0" ]; then
    log_pass "Rede: IP Forwarding desabilitado."
  else
    log_fail "Rede: IP Forwarding HABILITADO!" "Desative para evitar roteamento de tráfego malicioso."
  fi
else
  log_warn "Hardening de Kernel pulado (Sistema não é Linux Nativo ou permissão negada)."
fi

# ==============================================================================
# FASE 4: VULNERABILIDADES CONHECIDAS (CVEs)
# ==============================================================================
echo -e "\n${BLUE}>>> FASE 4: CVE SCANNING${NC}"

if command -v vulnix &>/dev/null; then
  echo "Executando Vulnix..."
  # Roda vulnix apenas no flake atual
  VULNS=$(vulnix ../flake.nix 2>&1 | grep -c "CVE")
  if [ "$VULNS" -eq "0" ]; then
    log_pass "Nenhuma vulnerabilidade conhecida (CVE) encontrada."
  else
    log_fail "$VULNS Vulnerabilidades encontradas pelo Vulnix!" "Rode 'vulnix ./flake.nix' para detalhes."
  fi
else
  log_warn "Ferramenta 'vulnix' não instalada."
  echo "          -> Instale adicionando ao flake.nix para pontuar nesta fase."
fi

# ==============================================================================
# RELATÓRIO FINAL
# ==============================================================================
echo -e "\n-----------------------------------------------------------"
PERCENT=$((SCORE * 100 / TOTAL_CHECKS))

if [ $PERCENT -ge 90 ]; then
  COLOR=$GREEN
elif [ $PERCENT -ge 70 ]; then
  COLOR=$YELLOW
else
  COLOR=$RED
fi

echo -e "SCORE DE CONFORMIDADE: ${COLOR}${PERCENT}%${NC} ($SCORE/$TOTAL_CHECKS)"

if [ $PERCENT -lt 100 ]; then
  echo -e "${RED}O AMBIENTE NÃO ESTÁ PRONTO PARA DEPLOY EM PRODUÇÃO.${NC}"
else
  echo -e "${GREEN}AMBIENTE BLINDADO. PRONTO PARA OPERAÇÃO.${NC}"
fi
