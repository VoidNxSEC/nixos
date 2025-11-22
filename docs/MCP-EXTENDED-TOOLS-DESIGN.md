 run test -- tests/tools/files/*.test.ts

echo "=== Testing Cleanup Tools ==="
npm run test -- tests/tools/cleanup/*.test.ts

echo "=== Testing Sensitive Data Tools ==="
npm run test -- tests/tools/sensitive/*.test.ts

echo "=== All tests passed! ==="
```

---

## 📝 Próximos Passos

### Para Implementação

1. **Setup Inicial**:
   ```bash
   cd /etc/nixos/modules/ml/unified-llm/mcp-server
   npm install ssh2 puppeteer systeminformation faker sharp exiftool-vendored
   ```

2. **Criar Estrutura de Diretórios**:
   ```bash
   mkdir -p src/tools/{ssh,browser,system,sensitive,files,cleanup}
   mkdir -p src/types src/utils/tool-specific
   ```

3. **Implementar Fase 1** (System Management):
   - Seguir roadmap semana 1-2
   - Criar testes unitários
   - Documentar cada ferramenta

4. **Switch para Code Mode**:
   ```bash
   # Após aprovação deste design
   # Usar switch_mode para começar implementação
   ```

### Para o Usuário

**Antes de começar a implementação, revisar**:

1. ✅ **Priorização está correta?**
   - Fase 1 (System Management) é o mais urgente?
   - Sensitive Data pode esperar para Fase 4?

2. ✅ **Segurança está adequada?**
   - Rate limits corretos?
   - Whitelists apropriadas?
   - Audit logging suficiente?

3. ✅ **Dependências são aceitáveis?**
   - Puppeteer/Chromium ~500MB
   - ssh2 biblioteca confiável?
   - Sistema tem recursos?

4. ✅ **Integração NixOS clara?**
   - Módulos systemd necessários?
   - Permissões de arquivos?
   - SOPS integration?

---

## 📚 Referências

### Documentação Existente

- [`docs/MCP-ARCHITECTURE-ACCESS.md`](MCP-ARCHITECTURE-ACCESS.md) - Arquitetura MCP atual
- [`docs/MCP-SECURE-ARCHITECTURE.md`](MCP-SECURE-ARCHITECTURE.md) - Segurança MCP
- [`docs/MCP-INTEGRATION-GUIDE.md`](MCP-INTEGRATION-GUIDE.md) - Guia de integração
- [`docs/MCP-TOOLS-USAGE-GUIDE.md`](MCP-TOOLS-USAGE-GUIDE.md) - Uso de ferramentas

### Bibliotecas e APIs

- [ssh2](https://github.com/mscdex/ssh2) - SSH client for Node.js
- [Puppeteer](https://pptr.dev/) - Headless browser automation
- [systeminformation](https://systeminformation.io/) - System info library
- [better-sqlite3](https://github.com/WiseLibs/better-sqlite3) - SQLite for knowledge DB
- [SOPS](https://github.com/mozilla/sops) - Secrets encryption

### NixOS Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [systemd services](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [SOPS-nix](https://github.com/Mic92/sops-nix)

---

## 🎯 Resumo Executivo

### O Que Foi Planejado

**28 novas ferramentas MCP** organizadas em 6 categorias:

1. **SSH & Remote** (4) - Acesso e manutenção remota
2. **Browser** (5) - Navegação e scraping avançado
3. **System** (6) - Gerenciamento completo do sistema
4. **Sensitive** (4) - Tratamento seguro de dados
5. **Files** (5) - Organização e catalogação
6. **Cleanup** (4) - Limpeza inteligente de dados

### Destaques Arquiteturais

✅ **Segurança em primeiro lugar**:
- Rate limiting em todas operações críticas
- Whitelists de hosts/comandos/URLs
- Audit logging completo
- SOPS integration para secrets
- Path traversal prevention
- Sandboxing de browser

✅ **Escalabilidade**:
- Connection pooling (SSH, browser)
- Queue management para operações longas
- Circuit breaker para falhas
- Resource guards

✅ **Manutenibilidade**:
- Código TypeScript tipado
- Estrutura modular clara
- Testes unitários e integração
- Documentação inline

### Cronograma

- **Fase 1** (2 semanas): System Management + File Organization básico
- **Fase 2** (3 semanas): SSH + Data Cleanup
- **Fase 3** (3 semanas): Browser + File Catalog avançado
- **Fase 4** (2 semanas): Sensitive Data Handling

**Total**: ~10 semanas para implementação completa

### Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Dependências pesadas (Chromium) | Alta | Médio | Opcional, feature flag |
| Segurança SSH | Média | Alto | Whitelist + validation + audit |
| Performance (file scan) | Média | Médio | Streaming + batching |
| Bugs em produção | Média | Alto | Testes extensivos + dry-run |

### Benefícios Esperados

🎯 **Operacionais**:
- Manutenção remota sem VPN
- Diagnóstico de sistema automatizado
- Limpeza inteligente de disco

🎯 **Segurança**:
- Scan de dados sensíveis
- Pseudonimização automática
- Audit trail completo

🎯 **Produtividade**:
- Organização automática de arquivos
- Busca avançada em catalog
- Web scraping para pesquisa

---

## ✅ Checklist de Aprovação

Antes de prosseguir para implementação, confirme:

- [ ] Design arquitetural revisado e aprovado
- [ ] Priorização de fases está correta
- [ ] Considerações de segurança são adequadas
- [ ] Dependências são aceitáveis
- [ ] Recursos do sistema são suficientes
- [ ] Integração NixOS está clara
- [ ] Cronograma é realista

**Próxima ação**: Switch para Code mode e começar Fase 1

---

**Documento criado por**: Roo (Architect Mode)  
**Data**: 2025-11-22  
**Status**: 🎯 Pronto para Aprovação e Implementação  
**Versão**: 1.0.0