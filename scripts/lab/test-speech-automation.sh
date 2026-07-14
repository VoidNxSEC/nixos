#!/usr/bin/env bash
#
# Test Script: Agent Hub Speech Automation
#
# Valida que todos os componentes de speech estão funcionando:
# 1. Redpanda (Kafka) está rodando
# 2. Topics de speech existem
# 3. Speech gateways (TTS/STT) estão rodando
# 4. F5-TTS está acessível
# 5. Whisper está acessível
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Agent Hub Speech Automation - Test Suite"
echo "==========================================="
echo ""

# Test 1: Redpanda is running
echo -n "1. Checking Redpanda (Kafka)... "
if systemctl is-active --quiet redpanda 2>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    echo "   Start with: systemctl start redpanda"
    exit 1
fi

# Test 2: Kafka is accepting connections
echo -n "2. Testing Kafka connectivity... "
if timeout 5 bash -c 'echo "" | nc localhost 9092' 2>/dev/null; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Cannot connect${NC}"
    exit 1
fi

# Test 3: Speech topics exist
echo -n "3. Checking Kafka topics... "
TOPICS=$(kafkacat -L -b localhost:9092 2>/dev/null | grep -c "agent\\..*\\.requests" || true)
if [ "$TOPICS" -gt 0 ]; then
    echo -e "${GREEN}✓ Topics exist${NC}"
else
    echo -e "${YELLOW}⚠ Topics not found${NC}"
    echo "   Topics will be created on first use"
fi

# Test 4: Speech Gateway TTS service
echo -n "4. Checking Speech Gateway TTS... "
if systemctl is-active --quiet speech-gateway-tts 2>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}⚠ Not running${NC}"
    echo "   Start with: systemctl start speech-gateway-tts"
fi

# Test 5: Speech Gateway STT service
echo -n "5. Checking Speech Gateway STT... "
if systemctl is-active --quiet speech-gateway-stt 2>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${YELLOW}⚠ Not running${NC}"
    echo "   Start with: systemctl start speech-gateway-stt"
fi

# Test 6: F5-TTS is accessible
echo -n "6. Testing F5-TTS availability... "
if command -v python3 &> /dev/null; then
    if python3 -c "import f5_tts" 2>/dev/null; then
        echo -e "${GREEN}✓ Available${NC}"
    else
        echo -e "${RED}✗ Not installed${NC}"
        echo "   Enable with: kernelcore.packages.f5-tts.enable = true;"
        exit 1
    fi
else
    echo -e "${RED}✗ Python not found${NC}"
    exit 1
fi

# Test 7: Whisper is accessible
echo -n "7. Testing Whisper availability... "
if command -v whisper &> /dev/null; then
    echo -e "${GREEN}✓ Available${NC}"
else
    echo -e "${YELLOW}⚠ Not installed${NC}"
    echo "   Enable with: kernelcore.ai.agent-hub.capabilities.speech.enableSTT = true;"
fi

# Test 8: Send test TTS request
echo ""
echo "8. Sending test TTS request to Kafka..."
TEST_REQUEST='{"agent_id":"test-suite","request_id":"test-001","text":"Teste de automatização de voz funcionando","language":"pt"}'
echo "$TEST_REQUEST" | kafkacat -P -b localhost:9092 -t agent.tts.requests 2>/dev/null
echo -e "${GREEN}   ✓ Request sent${NC}"
echo "   Check logs: journalctl -fu speech-gateway-tts"

echo ""
echo "==========================================="
echo -e "${GREEN}✓ Speech Automation Test Suite Complete${NC}"
echo ""
echo "Next Steps:"
echo "  1. Monitor TTS processing: journalctl -fu speech-gateway-tts"
echo "  2. View Kafka messages: kafkacat -C -b localhost:9092 -t agent.tts.completed"
echo "  3. Run example agent: python3 /etc/nixos/modules/ai/agent-hub/examples/voice-assistant-agent.py"
echo ""
