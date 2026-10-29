# Testes e regressões do Runes

Padrão estabelecido em 2026-10-23: mudanças de comportamento precisam de testes automatizados; bugs precisam de um caso que falhe antes da correção. A regra está no `AGENTS.md` e vale também para ajustes visuais que alterem interação.

## Executar

Requisitos: Python 3 e Godot 4.5.1 (versão usada pelo projeto). Sem bibliotecas Python externas ou plugin de testes.

```powershell
python tools/run_tests.py --godot 'C:/caminho/para/godot.exe'
python tools/run_tests.py --godot 'C:/caminho/para/godot.exe' --suite ui --suite highlights
python tools/run_tests.py --godot 'C:/caminho/para/godot.exe' --suite ui --render
```

`GODOT_BIN` pode substituir `--godot`. Os resultados ficam em uma pasta temporária cujo caminho é impresso no fim. Para guardar evidências em um local específico, use `--output <pasta-vazia-fora-do-checkout>`. Os logs e `results.json` registram cada suíte; a suíte de UI também grava casos individuais em `project/tests/ui-results.json`. `--render` gera capturas da cena real em `project/tests/` e requer acesso gráfico.

O runner copia somente os diretórios de runtime e os testes necessários, desativa MCP/editor plugins e telemetria na cópia, importa o projeto e executa cada suíte em um processo separado. Cada processo usa um perfil temporário próprio. Configuração, saves, arquivos `.godot` e fontes oficiais permanecem intactos; hashes verificam a origem ao final. O teste de vitória continua exigindo um perfil `runes-victory-tests`.

Erros de script, timeout, retorno diferente de zero, assertion falha ou falta do marcador de conclusão reprovam a execução. Logs não devem ser ignorados porque um processo terminou com código zero.

## Cobertura inicial

| Suíte | O que verifica | Limites |
|---|---|---|
| `ui` | Hover de efeitos na cena real; efeito chega ao overlay; arraste da própria runa; bordas de destino aceito/rejeitado; slot bloqueado/ocupado; limpeza ao sair/cancelar/soltar; hover após soltura; tooltip sobreposto; petrificação e fases bloqueadas | Casos determinísticos de runas. Não equivale a validar todas as peças, relíquias ou combinações de tela |
| `highlights` | Alvos ortogonais/diagonais, condições verdadeiras/falsas, múltiplos efeitos, condição e fonte de valor independentes, limpeza, preview sem mutação do jogo | Contratos do highlighter com componentes reais; não todas as runas do catálogo |
| `conditions` | Condições de execução, composição AND/OR, refrator, resíduos, efeitos aninhados e contagem sem efeitos colaterais do preview | Reutiliza `tools/test_gameplay_conditions.gd`; não todas as condições existentes |
| `victory` | Resolução real, vitória/derrota, economia/histórico, reinício e Readers de múltiplos painéis | Reutiliza `tools/test_run_victory.gd`; não a campanha inteira |

A validação da oficina em `Runes[ART]/tools/godot-active-validation` continua sendo complementar. Sua quantidade de checks não comprova cobertura do tabuleiro ou de todas as mecânicas. Não é dependência do runner deste repositório.

## Regra para novas mudanças

1. Consulte a spec e enumere os comportamentos afetados, inclusive sistemas vizinhos.
2. Escreva o caso que expõe o problema; execute-o no código anterior e guarde a falha.
3. Faça a correção e verifique o mesmo caso sem relaxar a expectativa.
4. Cubra caminho válido, inválido/cancelamento e preservação dos dados. Em UI, use eventos reais e confira os controles desenhados; para visuais, revise uma captura.
5. Execute a suíte focal durante a iteração e todas as suítes antes de entregar. Atualize esta matriz e a documentação do Obsidian se o contrato mudar.
6. Informe resultados e lacunas. Um teste que só repete a implementação ou chama diretamente o handler não substitui o fluxo integrado.

## Fila de expansão de cobertura

Estas são pendências, não testes já concluídos:

- Pontuação: casos A/B/C de buffs e multiplicadores do checklist no Obsidian, ordem das operações e arredondamento.
- Slots, modifiers e resíduos: um caminho válido e um caso de borda para cada tipo; prioridades e interação entre efeitos.
- Relíquias e peças: equipar/remover/vender, validade geométrica, sobreposição, rotação, inventário cheio e custo cobrado uma única vez.
- Reader: ordem, ativações simultâneas/aninhadas, limites de loops, destruição/criação e fim de rodada.
- Loja: compras, reroll, mana insuficiente, upgrade e venda usando a cena atual.
- Painéis: troca/desbloqueio durante planejamento, vinculação correta de highlights e preservação do estado.
- Persistência e conteúdo: salvar/carregar, compatibilidade de dados e validação dos resources do catálogo.
- UI: múltiplas escalas de janela, teclado, tooltip longo, sequências rápidas, troca de tela durante interação e renderização dos indicadores.

Fonte de intenção: `Runes/spec/systems/ui_ux.md` e `Runes/impl/testing_checklists.md` no Obsidian. Checklists manuais permanecem úteis, mas não contam como testes automatizados implementados.

## Arte animada das relíquias aprovadas

A suíte UI aplica os mesmos casos aos ícones aprovados Alquimista L1, Escudeiro S1, Destruidor N3 Abissal, Criador C3, Engenheiro E1, Anômalo A1, Rochedo AtlasEyes, Baluarte ShieldLines, Criança Child, Inferno, Oceano, Céu, Éter Cross, Nada Chalices, Retorno Ouroboros, Colecionador, Condutor e Palhaço (32×32, 12 frames de200ms), ausência de fundo opaco, compra real com/sem mana, custo único, arraste real do inventário ao painel, preservação da instância, limpeza após compra/remover/substituir e fallback de relíquias sem arte usando uma cópia local de dados com icon=null. Com `--render`, captura loja/inventário/equipado e amostra um ciclo completo de frames. A remoção usa a ação existente para validar limpeza visual; não demonstra o gesto de clique no slot equipado (o ItemUI preexistente captura esse clique).

## Apresentação e vínculos de relíquias na loja

`test_rune_interactions.gd` também verifica o controlador visual composto na cena de produção. Todas as 18 ofertas mantêm uma única cópia nativa, sem placa sólida; compra, tooltip e hitbox continuam no SlotUI original. O ponteiro real confirma outline e nome/preço no tooltip. A base visual fica 4 pixels acima do centro original, com glow branco; hover e compra são exercitados também no centro elevado, mantendo a hitbox fixa. Amostras de posições demonstram flutuação livre, imobilidade selada e retomada após liberar, sem pausar o AnimatedTexture compartilhado. O render também amostra os dois níveis das correntes e compara a intensidade desenhada com a luminância/alpha atual do círculo, sem relógio independente; a geometria selada continua fixa. Os três extremos dos vínculos são conferidos contra pixels opacos da máscara do círculo existente; a leitura das linhas e do glow exige também revisão das capturas 1×/nearest, incluindo efeitos isolados.

Entradas reais cobrem selar/liberar por 1 mana, rejeição sem mana, compra selada por 10 mana e reroll pelo pedestal neutro mantendo a oferta selada. O refresh de rodada verifica permanência da oferta ou do altar selado vazio/vermelho; liberar o altar vazio não repõe uma oferta antes da rodada seguinte. Trocas repetidas no mesmo frame, Atlas/cálices/ouroboros/Palhaço, esconder/reabrir livre e selado, desabilitar o controlador, fallback sem ícone e ausência de oferta cobrem limpeza e restauração. As ações de refresh preparam/exercitam o modelo de rodada; não simulam uma partida completa até a próxima rodada.

Para a coleção e esses cenários renderizados, use `python tools/run_tests.py --godot <executável> --render --timeout 240`. Esse limite acomoda a amostragem dos 18 loops; não altera os tempos de jogo.

### Approved slot modifier presentation (batch01)

`slot_presentation` exercises the approved Accumulator A1, Conector C1.1 and
Stabilizer S1 in the production scene. Borders use native 50px transparent
layers above 40px bases at the unchanged 40px panel pitch. The suite covers
mixed adjacent empty/occupied cells, exact rendered external pixels (with
`--render`), inventory hover, modifier drag cancellation, locked rejection,
application/replacement and consumption, removal/context/locked cleanup,
shop insufficient-mana rejection and purchase, legacy fallback and empty offers.
The two overclock offers separate only their artwork by 7px each; both purchase
hitboxes remain 23x19, and either remaining solo offer recenters after purchase.

The existing `ui` suite starts with authored borders on its source/destination
cells, so its real rune hover, highlighting, drag/drop, invalid destination,
cancellation and state-conservation cases also run with border overflow enabled.
Run all suites with `python tools/run_tests.py --godot <path> --render`; screenshots
are emitted by the isolated `slot_presentation` and `ui` test copies. Static
art integration adds no modifier mechanics; gameplay suites retain their prior
expectations. Neighbor decorations may naturally overlap at a 40px grid pitch;
opaque neighbor bases must never erase their external border pixels.

Batch02 extends the same suite with r07 Charger CH5 (including its complementary
terminal), Condenser CD1 and Resonator R5. The mixed board includes all six
installed types; batch01 assertions and interaction coverage are retained.
Each new modifier exercises native inventory art, real hover, cancelled drag,
locked rejection, application/consumption and held-rune conservation, dual shop
offers, name/price tooltip, insufficient mana, purchase at the original hitbox,
solo recentering and complete offer cleanup. Render captures include empty and
occupied mixed grids plus all three new shop pairings. Runtime UI is unchanged.

Batch03 updates only Accumulator to AC10-A and Charger to CH10-A from approved
r10. Those two now use native40x40 overlays at origin0,0; Conector, Stabilizer,
Condenser and Resonator remain at their previously installed50x50 dimensions.
The existing presentation suite checks dimensions per type and physical alpha
bounds inside40 for the two updated types. The rendered overflow regression
samples Conector beside the new40px art, preserving coverage of the other four.
Empty/occupied mixed-grid captures show the approved rock rune over both revised
frames. Its opaque pixels do not intersect either approved overlay; r10 may use
44/42 pixels of the inner32 margin respectively, as recorded in source QA.
Real Accumulator application now explicitly preserves an occupied rune instance;
the existing occupied Charger test, inventory, drag/cancel/rejection, shop dual
and solo offers, purchase and tooltip routes remain in the same suite.


Batch04 updates only Condenser to approved CD12.3 from r12, native40x40 at
origin0,0. The same suite now verifies three40px types (Accumulator, Charger,
Condenser) beside three preserved50px types (Conector, Stabilizer, Resonator).
The occupied-grid capture uses the approved rock proof rune on Condenser too;
its opaque pixels do not intersect the new overlay. Source QA records62 new
pixels in the inner32 margin and zero central24 coverage. Existing real
Condenser hover, inventory, drag/cancel, locked rejection, occupied-rune
conservation, shop dual/solo purchase and cleanup cases remain active.
Runtime UI, all six SlotData resources and the other five modifiers are unchanged.


Batch05 installs the approved softened r08 Conector C1.1, Stabilizer S1 and
Resonator R5. All six authored modifiers now use native40x40 at origin0,0;
AC10-A, CH10-A and CD12.3 remain byte-identical. The presentation suite checks
each physical alpha bound inside its40px cell, captures all six empty and
occupied, and compares the real rendered opaque border pixels against the
approved overlays beside occupied neighbors. The former50px overflow probe
is replaced by this authorized40px geometry and rendered-pixel assertion.
The existing inventory/tooltip/cancel/locked-drop/conservation/shop dual/solo
matrix now iterates all six types, with actual occupied targets. Legacy
Enhancer fallback, context cleanup and both purchase directions remain tested.
UI, resources, mechanics and hitboxes are unchanged.


Modifier bundles integration gives the six authored modifiers their approved32px
kit icons in shop, inventory and real drag previews. Panel SlotData frames remain
byte-identical. The presentation suite exercises every kit through inventory
hover, actual preview/cancel, locked rejection, occupied-panel application, both
shop purchase positions, solo offers, rune reroll persistence, fountain sale and
clear. Shop pixels are compared at native integer centers, including their one
pixel of visual overflow outside the unchanged23x19 hitbox. Inventory cells stay
40x40. No-icon authored modifiers retain mounted fallback, Enhancer retains its
placeholder, and reuse/context transitions restore base visibility and clipping.
No mounting animation, mechanics, saves or scene geometry are changed.


The approved Igniter IG3, Pressurizer PR1.3 and Refractor RF1 extend the same
presentation matrix to nine modifiers. All nine have native40x40 mounted
frames and native32x32 inventory/shop/drag kits. The mixed board now captures
every type empty and with the approved rock proof rune, and compares every
opaque frame pixel with the rendered result. The three new kits additionally
run the existing real hover, cancel, locked rejection, occupied-rune
conservation, both purchase positions, insufficient mana, reroll, fountain sale
and cleanup cases. Resources and art only; runtime UI and mechanics unchanged.


Catalyzer CA1, Dispenser DS5.2 and Enhancer EN1 extend inventory/shop/drag
coverage to twelve authored modifiers. A dedicated first-row empty/occupied
render checks the three mounted compositions exactly before restoring the
previous nine-type board. DS5.2 intentionally occupies the center with an
opaque depth cavity: it remains visible when empty, and the native rock rune
draws above it when occupied. Its approved intersection is recorded, not a
zero-overlap requirement. Each pixel of both rendered states is checked, and
the overlay resource remains unchanged across occupancy. The real-input
matrix retains cancel, locked rejection, occupied-rune conservation, both
purchase positions, insufficient mana, reroll, sale and cleanup. Purifier now
provides the still-unillustrated legacy fallback because Enhancer has art.
RuneUI now draws its32px texture centered in the unchanged40px input region,
above equipment (z2) and below targeting feedback (z3). The focal regression
first failed all three occupied pixel compositions with the old scaled, z0
rune; it now checks native geometry, pixel-exact composition, highlight order
and restoration of z2 after a real cancelled rune drag. Hitboxes and all
modifier mechanics remain unchanged.

The existing residue shaders remain above runes on the same z2 plane, with
child order preserved, and highlights remain z3. A rendered comparison of
mana residue and mana anomaly against the no-effect occupied Dispenser
requires visible pixel changes over opaque rune pixels; clearing either
effect must restore the exact approved composition. Shader animation time
is unrestricted: this check uses the always-visible central opaque region.


Purifier PU1.1 and Transmuter TR4 complete all fourteen modifier presentations.
The real-input matrix now covers every approved kit while retaining the
previous nine-type board, Catalyzer/Dispenser/Enhancer compositions, native32
runes, residue/anomaly layering and cleanup. The final pair also has exact
empty/occupied composition captures. All five TR-kit elemental glyphs have
source ROI equality checks and individual exact rendered-shop ROI assertions.
Inventory and real drag captures retain the same native kit resource.
Since every modifier now has art, legacy placeholder coverage uses a local
copy without icon/base/overlay textures and verifies the official Purifier
resource remains illustrated. No runtime, mechanics, hitbox or config changes.
