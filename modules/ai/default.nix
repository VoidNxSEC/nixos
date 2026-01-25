# AI Modules Aggregator
#
# Importa todos os módulos relacionados a IA:
# - Agent Hub (infra + capabilities)
# - Future: LLM integrations, RAG systems, etc.
#
{ ... }:
{
  imports = [
    ./agent-hub/infra
    ./agent-hub/capabilities
  ];
}
