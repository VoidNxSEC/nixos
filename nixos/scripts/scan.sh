# epic_card_analyzer.sh
INPUT=${1:-cartas.jsonl}
OUTPUT=${2:-analise_epica.md}

echo "# ANÁLISE DE CARTAS ÉPICAS" >"$OUTPUT"
echo "Gerado em: $(date)" >>"$OUTPUT"
echo "" >>"$OUTPUT"

cat "$INPUT" | jq -c . | while read -r line; do
  name=$(echo "$line" | jq -r '.name')
  epic_score=$(echo "$line" | jq -r '[.description, .personality, .scenario] | join(" ") | [scan("épic[ao]|epic|batalha|guerra|lend[áa]ri[ao]")] | length')

  if [ "$epic_score" -gt 2 ]; then
    echo "## ⚡ CARTA ÉPICA DETECTADA: $name" >>"$OUTPUT"
    echo "**Nível de Épico:** $epic_score/10" >>"$OUTPUT"

    echo "$line" | jq -r '
      "### Resumo Tático:",
      "**Foco:** " + (.tags | join(", ")),
      "",
      "**Padrões de Fala Identificados:**",
      (.first_mes | match("([A-Z][^.!?]*[.!?])"; "g") | .captures[0].string),
      "",
      "**Estrutura de Análise:**",
      (.mes_example // "" | scan("TIER [0-9]:|\\*\\*[A-Z].*\\*\\*:|// [A-Z].*:") | "  - " + .),
      ""
    ' >>"$OUTPUT"
  fi
done

echo "### 📊 RESUMO ESTATÍSTICO:" >>"$OUTPUT"
cat "$INPUT" | jq -s '
  [
    group_by(.creator)[] |
    {creator: .[0].creator, count: length, epic_cards: map(select(.description | test("épic|epic|battle"; "i"))) | length}
  ] echo "  " + .[] | "**\(.creator):** \(.count) cartas total (\(.epic_cards) épicas)"' >>"$OUTPUT"
