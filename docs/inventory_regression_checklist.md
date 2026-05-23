# Checklist de Regressao - Inventario (Fase 4)

Data: 2026-05-22
Escopo: inventario compartilhado com 8 slots (2x4), sem compactacao, drop exige slot vazio, sem swap.

## Pre-condicoes
- Cena principal carregada com MainController ativo.
- Inventario visual com 8 slots.
- Pelo menos 2 runas no inventario e 1 runa no grid.
- Pelo menos 1 reliquia anexada em relic slot.
- Pelo menos 1 piece e 1 modifier no extra inventory.

## Casos obrigatorios

### T1 - mover runa inventario -> inventario para slot vazio
Passos:
1. Arrastar uma runa de um slot ocupado para outro slot vazio do inventario.
Esperado:
- Runa termina no slot alvo.
- Nenhum outro item muda de posicao.
- Nao ocorre swap.
Telemetria esperada:
- Uma linha com [InventoryLog] rune_move_inventory_to_inventory e result=ok.

### T2 - tentar drop em slot ocupado
Passos:
1. Arrastar uma runa para um slot de inventario ja ocupado (runa ou item extra).
Esperado:
- Operacao falha.
- Estado do inventario permanece igual.
Telemetria esperada:
- Uma linha com [InventoryLog] rune_drop_blocked_slot_occupied.

### T3 - mover runa grid -> inventario com alvo vazio
Passos:
1. Arrastar uma runa do grid para um slot vazio especifico do inventario.
Esperado:
- Runa entra no slot alvo do inventario.
- Slot do grid fica vazio apos sucesso.
Telemetria esperada:
- Uma linha com [InventoryLog] rune_move_grid_to_inventory e result=ok.

### T4 - retorno de reliquia para slot especifico vazio
Passos:
1. Arrastar reliquia de um relic slot para um slot vazio do inventario.
Esperado:
- Reliquia retorna para o inventario no slot visual alvo.
- Reliquia deixa de estar anexada ao painel.
Telemetria esperada:
- Uma linha com [InventoryLog] relic_return_to_inventory e result=ok.

### T5 - vender piece/modifier/relic/rune sem desync
Passos:
1. Vender 1 piece no SellArea.
2. Vender 1 modifier no SellArea.
3. Vender 1 relic no SellArea (anexada e nao anexada, quando possivel).
4. Vender 1 rune no SellArea.
Esperado:
- Item removido do manager correto.
- UI sincronizada apos cada venda (sem item fantasma).
- Mana atualizada apos cada transacao.
Telemetria esperada:
- Uma linha [SellLog] por venda com origin e result.
- Para rune: evento sell_rune.
- Para piece: evento sell_piece.
- Para modifier: evento sell_modifier.
- Para relic: evento sell_relic.

## Resultado da rodada de validacao
- Data:
- Responsavel:
- Build/commit:
- Status geral: PASSOU / FALHOU
- Observacoes:
