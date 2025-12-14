#!/bin/bash
echo "═══════════════════════════════════════════════════════════════════"
echo "  VRAM Calculator - Exemplos Práticos"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

cd /home/kernelcore/dev/Projects/phantom

echo "🎮 Cenário 1: RTX 4090 (24GB) com Qwen3-30B Q4_K_M"
python vram_calculator.py -m 30 -q Q4_K_M -c 4096 -g 24
echo ""

echo "🎮 Cenário 2: RTX 3060 (12GB) com Qwen3-30B Q2_K"
python vram_calculator.py -m 30 -q Q2_K -c 4096 -g 12
echo ""

echo "🎮 Cenário 3: RTX 3060 (12GB) com Llama3-8B Q4_K_M"
python vram_calculator.py -m 7 -q Q4_K_M -c 4096 -g 12
echo ""

echo "🎮 Cenário 4: A6000 (48GB) com Qwen3-30B Q6_K + Context 8k"
python vram_calculator.py -m 30 -q Q6_K -c 8192 -g 48
echo ""

echo "🎮 Cenário 5: RTX 4090 (24GB) - LIMITE com Q5_K_M"
python vram_calculator.py -m 30 -q Q5_K_M -c 4096 -g 24
echo ""
