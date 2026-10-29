# Runes Agent Onboarding Hub

This file is the primary entrypoint for coding and design AI agents in this repository.

## Purpose / Proposito

PT-BR:
- Centralizar o onboarding de agentes.
- Reduzir ambiguidade entre documentacao ativa e historica.
- Direcionar cada tipo de tarefa para o agente correto.

EN:
- Centralize agent onboarding.
- Reduce ambiguity between active and historical documentation.
- Route each task type to the correct agent.

## Quick Start / Inicio Rapido

1. Escolha o agente certo em [.github/agents](.github/agents) / Choose the right agent in [.github/agents](.github/agents).
2. Leia a arquitetura atual em [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) / Read current architecture in [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md).
3. Use comandos operacionais de [.github/COMMANDS.md](.github/COMMANDS.md) / Use operational commands from [.github/COMMANDS.md](.github/COMMANDS.md).
4. Valide acesso ao Obsidian (source of truth) via MCP / Validate Obsidian access via MCP.
5. Trate arquivos em [docs/historical](docs/historical) e [tools/legacy](tools/legacy) como referencia historica / Treat files in [docs/historical](docs/historical) and [tools/legacy](tools/legacy) as historical reference.

## Agent Directory / Diretorio de Agentes

| Agent | File | Use When | Hard Boundaries |
|---|---|---|---|
| Implementer | [.github/agents/implementer.agent.md](.github/agents/implementer.agent.md) | Implementar features, bugfix, refactor, integracao de sistemas, conteudo tecnico | Nao pular spec no Obsidian; evitar acoplamento direto entre managers |
| Game Designer | [.github/agents/game_designer.agent.md](.github/agents/game_designer.agent.md) | Discussao de design, balanceamento, UX, trade-offs de mecanicas | Nao escrever codigo; sempre apresentar opcoes com trade-offs |

## Routing Guide / Guia de Roteamento

| Intent | Primary Agent | First Docs To Read |
|---|---|---|
| Criar efeito, runa, slot, painel, reliquia | Implementer | [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md), [.github/COMMANDS.md](.github/COMMANDS.md) |
| Debater balanceamento ou experiencia do jogador | Game Designer | Obsidian specs + [.github/agents/game_designer.agent.md](.github/agents/game_designer.agent.md) |
| Diagnosticar comportamento estranho no pipeline de efeitos | Implementer | [docs/rune_effects_debug.md](docs/rune_effects_debug.md), [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) |

## Source of Truth Policy / Politica de Fonte da Verdade

PT-BR:
- Obrigatorio consultar Obsidian primeiro para intencao de design/sistema.
- O repositorio e referencia de implementacao atual.
- Arquivos historicos nao devem guiar novas decisoes sem validacao.

EN:
- Obsidian must be consulted first for design/system intent.
- The repository is the implementation reference.
- Historical files must not drive new decisions without validation.

## Padrão obrigatório de testes

- Toda mudança de comportamento deve incluir ou atualizar testes automatizados pertinentes. Correções de bugs exigem um teste de regressão que reproduza a falha antes da correção e passe depois; registre quando não for possível reproduzir automaticamente.
- Antes de implementar, identifique as mecânicas afetadas e seus pontos de interação. Cubra o caminho válido, rejeição/cancelamento e preservação de estado; inclua efeitos colaterais em sistemas relacionados.
- Em UI, exercite entradas reais do Godot na cena de produção e confirme o resultado nos controles visuais. Validar somente métodos, parâmetros ou movimentação do nó não comprova hover, highlights, tooltips, prioridade de input ou limpeza após drag/drop. Mudanças visuais também precisam de inspeção de captura renderizada.
- Não altere expectativas só para fazer testes passarem. Expectativas vêm das specs e do comportamento autorizado. Preserve um caso que falhe com o código anterior quando corrigir regressões.
- Execute `python tools/run_tests.py --godot <executável>` antes de concluir uma mudança de comportamento. Use `--suite` para iterações focais; execute todas as suítes ao finalizar. O runner usa cópia isolada e perfis temporários, sem acessar saves do jogador.
- Entregue comando, resultado e limites da cobertura. Quantidade de assertions não equivale a cobertura completa; não declare mecânicas validadas sem casos correspondentes. Se um teste não puder rodar, registre a razão e a pendência.
- Correções somente de texto/formatação não exigem testes artificiais; use revisão adequada. Mecânicas novas ou alteradas exigem ampliar a matriz em `docs/testing.md`.
- Guia, casos e lacunas: [docs/testing.md](docs/testing.md). Esse padrão se aplica a todo desenvolvimento futuro, inclusive agentes e alterações de arte que afetem interação.

## Active References / Referencias Ativas

- Arquitetura tecnica: [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md)
- Comandos e operacao: [.github/COMMANDS.md](.github/COMMANDS.md)
- Debug de efeitos: [docs/rune_effects_debug.md](docs/rune_effects_debug.md)

## Historical References / Referencias Historicas

- Documentos legados: [docs/historical](docs/historical)
- Scripts legados: [tools/legacy](tools/legacy)

## MCP and Obsidian Troubleshooting / Solucao de Problemas MCP

1. Verifique configuracao em [.vscode/mcp.json](.vscode/mcp.json).
2. Rode o script de status:
   - `pwsh -ExecutionPolicy Bypass -File .github/skills/obsidian-mcp/scripts/check_mcp_status.ps1`
3. Se as ferramentas MCP nao estiverem ativas no chat, habilite o servidor Obsidian manualmente.

## Collaboration Contract / Contrato de Colaboracao

PT-BR:
- Design-first: Designer define direcao e trade-offs.
- Build-second: Implementer traduz em mudancas tecnicas.
- Sempre registrar decisoes de alto impacto na documentacao apropriada.

EN:
- Design-first: Designer defines direction and trade-offs.
- Build-second: Implementer translates into technical changes.
- Record high-impact decisions in the appropriate documentation.

## Fluxo de arte e integração visual

A arte editável e o fluxo reproduzível ficam no repositório local `C:/Users/55119/Pictures/Runes[ART]` (consulte seu `AGENTS.md`, `README.md` e `config/local.json`). Use especialistas separados: `$runes-aseprite` para pixels/camadas/frames e `$runes-godot-art-integration` para composição, interação e reprodução no Godot. Se objetivo, escopo ou critério de pronto estiverem ambíguos, converse com o usuário antes de executar essa parte. Trabalhe em revisões e previews isolados; a promoção da arte e cena oficiais depende da aprovação visual da revisão concreta. Animações são desenhadas no Aseprite sob direção do usuário. Preserve trabalho preexistente e nunca promova a configuração/fixtures de um preview para o projeto oficial.
