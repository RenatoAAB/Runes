# Runas — Dashboard de Balanceamento

Dashboard local para consolidar as estatísticas enviadas pelos beta testers
(veja `docs/telemetry/schema.sql` e `scripts/autoloads/telemetry_manager.gd`).

## Como usar

1. Abra `index.html` no navegador (duplo clique funciona).
   - Se algo for bloqueado pelo navegador, sirva a pasta:
     `python -m http.server` e abra `http://localhost:8000`.
2. Só quer ver como fica? Clique em **▶ Exemplo** — carrega ~64 runs fictícias
   (com sprites reais) sem precisar de conexão nenhuma.
3. Para dados de verdade: clique em **⚙** e cole a URL do projeto Supabase e a
   **anon / publishable key** (Dashboard do Supabase → Settings → API).
   - Use a anon key, **não** a service_role/secret — o navegador bloqueia keys
     secretas (`401 Forbidden use of secret API key in browser`). A leitura depende
     das policies `anon_select_*` do `schema.sql` estarem aplicadas.
   - A key fica apenas no `localStorage` deste navegador.
4. Clique em **Atualizar** para baixar os dados.

## Abas

- **Itens** — cards com sprite e raridade de cada runa/relíquia/peça/modificador:
  taxa de escolha, pontos por run, conversão oferta→compra e "taxa de run
  profunda" (% das runs com o item que chegam ao nível N — o limiar é
  configurável no filtro, já que o jogo ainda não tem condição de vitória).
  Pódio no topo: mais escolhida 🏆, melhor desempenho 🔥, mais ignorada 🥷.
- **Pontuações** — recordes, histograma (faixas que dobram, pois a pontuação
  cresce exponencialmente), curva média vs pontuação alvo, Hall da Fama com o
  loadout final de cada run.
- **Funil** — % de runs que alcançam cada nível, separado por versão do jogo,
  com o "nível mais mortal" 💀.
- **Economia** — mana ganha/gasta e para onde vai (por categoria de compra).

Todos os gráficos têm um botão **tabela** com os mesmos números.

## Snapshots

**⇩ Snapshot** baixa os dados atuais como JSON; **⇧ Carregar** abre um snapshot
salvo — útil para trabalhar offline ou arquivar o estado de cada versão.

## Sprites e nomes dos itens

Vêm de `assets/manifest.js` + `assets/*/*.png`, gerados a partir dos resources
do jogo. Para regenerar depois de adicionar itens ou trocar arte:

```
godot --headless --path . -s tools/export_dashboard_assets.gd
```

Itens sem arte aparecem com um glifo de placeholder (◈ ♦ ▦ ✦) — também serve
de lembrete de qual item ainda não tem sprite.
