# Vitória da run por pontuação

Implementado em 2026-10-23, conforme a direção de design no Obsidian
`Runes/design/corrida_ate_um_milhao`.

- `GameManager.run_victory_score` configura a meta (padrão: 1.000.000).
- A meta é comparada ao resultado final de uma batalha completa, incluindo a
  combinação multiplicativa dos painéis e seus multiplicadores. Não se soma a
  pontuação de rodadas anteriores para alcançar a meta.
- A avaliação ocorre ao concluir todos os painéis. Atingir ou superar a meta
  vence a run, independentemente do número da rodada. Essa vitória tem prioridade
  se a curva também estiver acima da pontuação obtida.
- Abaixo da meta, mantém-se a regra existente: pontuação maior ou igual à curva
  passa a rodada; pontuação inferior perde. A curva e as recompensas não mudam.
- A tela diferencia `ROUND CLEARED` de `VICTORY!`. Na vitória final, `New Run`
  confirma o resultado, registra `Stats.end_run(true)`, emite `run_ended(true)`
  e `game_won`, e reinicia na rodada 1. Não concede recompensa de próxima rodada.
  Cliques no fundo não descartam a vitória; confirmações duplicadas são ignoradas.
- `PanelManager` inicia/finaliza a batalha uma vez. Readers de painéis resolvem
  seus efeitos de fim de rodada sem reiniciar estatísticas nem finalizar a batalha
  individualmente. `EventBus.battle_ended` recebe a pontuação combinada e o mesmo
  resultado usado por GameManager. Readers independentes mantêm o fluxo próprio.

## Verificação

`tools/test_run_victory.gd` cobre limites, prioridade da meta, progressão,
derrota, histórico, reinício, múltiplos painéis e Readers reais (39 verificações).
O teste requer um perfil temporário cujo caminho contenha `runes-victory-tests`,
pois exercita gravações reais de histórico. Ele desconecta a telemetria.

Exemplo em uma sessão PowerShell dedicada, a partir da raiz do projeto:

```powershell
$env:APPDATA = Join-Path $env:TEMP 'runes-victory-tests'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
godot --headless --path . --script tools/test_run_victory.gd
```
