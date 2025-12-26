# GAME DESIGN DOCUMENT: RUNES
**Versão:** 1.1
**Autor:** Big Lurker
**Engine:** Godot 4.x
**Arte:** Aseprite (Pixel Art)
**Status:** Em Desenvolvimento

## 1. Visão Geral (High Concept)
*   **Título Provisório:** Runas / Project Runa-Laser
*   **Gênero:** Roguelike Deckbuilder / Engine Builder / Puzzle.
*   **Elevator Pitch:** "Balatro encontra a Engenharia Espacial". Construa e otimize uma máquina de runas em grids modulares para processar energia e disparar lasers.
*   **Core Hook:** A satisfação matemática e visual de ver um número pequeno se transformar em um laser gigante através de sinergias complexas.
*   **Plataformas:** PC (Steam, Itch.io) e Mobile (Google Play).

## 2. Regra de Ouro: A Matemática do Jogo
Para manter o código e o design balanceados, a lógica de cálculo segue estritamente esta hierarquia:
1.  **Runas (O "O Que"):** Valor Base (Aditivo).
2.  **Slots (O "Onde"):** Multiplicadores Locais.
3.  **Painéis (O "Contexto"):** Multiplicadores Globais.

**Fórmula Simplificada:**
$$ \text{Dano Final} = \sum (\text{Base Runa} + \text{Bônus}) \times \text{Mult Slot} \times \text{Mult Painel} $$

*Nota: Valores podem ser negativos. Um multiplicador pode começar alto (x5.0) e decair com o tempo, ou uma runa pode subtrair pontos em troca de mana.*

## 3. Mecânicas e Arquitetura de Sistemas

### 3.1. O Reader (O Processador)
*   **Conceito:** Um pulso de energia visual que percorre o grid.
*   **Comportamento:** Segue um caminho fixo (ex: Esquerda -> Direita, Cima -> Baixo) ou definido por setas no grid.
*   **Trigger:** Ao passar por uma runa, executa a função `_on_activate()` daquela runa.

### 3.2. Runas (Base Aditiva & Lógica)
Peças fundamentais colocadas sobre os slots.
**Visual:** Ícones rúnicos distintos em Pixel Art.

#### Tipos de Efeitos (Payloads)
*   **Pontuação (Scoring):**
    *   Imediato: Adicione ou perca X pontos.
    *   Temporário (Buff): Ganhe ou perca X pontos nesta rodada (reseta no fim).
    *   Permanente (Scaling): Ganhe ou perca X pontos permanentemente (persiste na run).
*   **Economia:**
    *   Gere ou perca $ Dinheiro ao ser ativada.
*   **Utilidade/Manipulação:**
    *   **Reader:** Pule o próximo slot, inverta a direção, teleporte o reader.
    *   **Ativações:** Adicione +X ativações à esta runa (multicast).
    *   **Destruição:** Destrua X runas (alvo) para ganhar bônus massivo.
*   **Maldições (Negative Effects):**
    *   Runas que subtraem pontuação mas dão dinheiro.
    *   Runas que "apodrecem" (perdem valor permanente a cada uso).

#### Alvos (Targets)
*   **Próprio (Self):** A runa que ativou.
*   **Adjacentes:** As 4 ou 8 casas ao redor.
*   **Por Elemento:** Todas as runas de Fogo/Água no grid.
*   **Arbitrário/Aleatório:** Uma runa aleatória, ou uma runa em coordenada específica.

#### Condicionais de Ativação (Conditions)
A runa só executa seu efeito SE:
*   **Vizinhança:**
    *   Está preenchida / vazia.
    *   Contém elemento específico (ex: "Se vizinho for Fogo").
*   **Posição no Slot (Topologia):**
    *   Está no Centro, Borda, Canto ou "Ilha" (sem vizinhos).
*   **Histórico da Rodada:**
    *   Já foram ativadas X runas (Total ou de Elemento Y).
    *   Uma runa específica X foi ativada na posição Y.
    *   É a Xª ativação desta mesma runa no turno (para loops).
*   **Histórico da Run (Meta):**
    *   A runa foi usada em X rodadas (consecutivas ou totais).
*   **Recursos:**
    *   Jogador tem mais/menos que X dinheiro.

### 3.3. Slots (Multiplicadores Locais & Modificadores)
O "chão" onde a runa senta. Podem ter efeitos passivos ou reativos.

#### Efeitos de Slot
*   **Multiplicadores:**
    *   Multiplique a pontuação da runa por X nesta rodada.
    *   Multiplique a pontuação da runa por X **permanentemente** (Slot evolutivo).
*   **Trigger Duplo (Repeater):** Ative a runa X vezes.
*   **Economia:** Gere $1 se houver uma runa aqui.
*   **Preservação:**
    *   Não consome carga da runa (Infinite use).
    *   Runas frágeis (Glass) não quebram neste slot.
*   **Slot Vazio:**
    *   Padrão: x1.0 mult.
    *   Pode ter efeitos negativos (ex: Slot Quebrado x0.5).

### 3.4. Painéis (Multiplicadores Globais & Contexto)
Grids modulares que contêm os slots. O Score final de um painel alimenta o próximo.

#### Regras de Sinergia (Passivas de Painel)
*   **Geometria:**
    *   Para cada linha/coluna completa: x1.5 Score Global.
    *   Para cada espaço "vazio" (sem slot físico): Bônus X.
    *   Para cada slot vazio (com slot, sem runa): Bônus Y.
*   **Conteúdo:**
    *   Para cada runa de Elemento/Tier/Raridade X: +Score ou xMult.
    *   Para cada Slot com Upgrade (Nível 2+): Bônus.
*   **Cadeia (Chaining):**
    *   Se o painel **anterior** cumpriu condição X (ex: fez > 100 pontos).
    *   Baseado no número de painéis anteriores.
    *   Baseado no total de ativações de runas na cadeia inteira.

## 4. Game Loop (Fluxo da Sessão)
1.  **Seleção de Rodada:** Visualizar Target Score.
2.  **Loja (Shop):** Comprar Runas, Modificadores de Slot, Painéis.
3.  **Organização (Build):** Posicionar slots, runas e ordenar painéis.
4.  **Execução (Play):** O Reader passa. Feedback visual.
5.  **Resultado:** Vitória ($$ + Dificuldade sobe) ou Derrota (Game Over).

## 5. Arte e Estética
*   **Estilo:** Pixel Art (Aseprite).
*   **Tema:** Místico-Tecnológico / "Cyber-Rune".
*   **Juice:** Shake, Partículas, Pitch de som ascendente no combo.

## 6. Interface (UI/UX)
*   **Destaque Matemático:** Tooltip mostra a equação: `Soma[(Base_i + Buff_i) x Slot_i] x Painel + outros_paineis = Total`.
*   **Visualização:** Barra de progresso vertical para o Target Score.

## 7. Desenvolvimento Técnico (Godot)

A arquitetura segue o padrão **Data-Driven** com forte desacoplamento entre lógica e visualização.

**7.1. Estrutura de Dados (Resources & Instances)**
*   **`RuneData` (Resource):** Define a identidade estática da runa. Contém:
    *   Metadados: Nome, Tier, Raridade, Elemento.
    *   Visual: Texturas para diferentes tiers.
    *   Comportamento: Array de `RuneEffect`.
*   **`RuneInstance` (RefCounted):** O objeto "vivo" durante o jogo.
    *   Envolve o `RuneData`.
    *   Gerencia estado mutável: Ativações atuais, buffs temporários (rodada) e permanentes (run).
    *   Calcula modificadores de status em tempo real.
*   **Sistema Modular de Efeitos (`RuneEffect`):**
    Cada efeito é um Resource composto por três sub-módulos (Strategy Pattern):
    1.  **Condition:** Valida a execução (ex: `Always`, `PreviousEffectSucceeded`, `NeighborhoodCondition`).
    2.  **Target:** Seleciona os alvos (ex: `Self`, `Adjacent`, `ByElement`).
    3.  **Payload:** A ação executada (ex: `AddScore`, `DestroyRune`, `MultiplySelf`).

**7.2. Grid & Lógica Espacial (`GridManager`)**
*   **Estrutura:** Array 1D de tamanho fixo (25 slots para 5x5) mapeado para coordenadas 2D (`Vector2i`). Isso simplifica a iteração do Reader.
*   **`GridSlot`:** Objeto lógico que ocupa uma posição no array e segura a referência para uma `RuneInstance`.
*   **Vizinhança:** Funções utilitárias (`get_neighbors`) calculam adjacências ortogonais e diagonais para efeitos de área.

**7.3. O Loop de Batalha (`Reader` & `BattleContext`)**
*   **`Reader`:** Responsável apenas pela iteração sequencial (índice 0 ao 24) e controle de tempo (steps). Não contém lógica de jogo, apenas dispara o processo.
*   **`BattleContext`:** Objeto efêmero criado no início de cada sequência (`start_sequence`).
    *   Atua como mediador ("Sandbox") onde as runas executam seus efeitos.
    *   Acumula o Score e gerencia eventos de fluxo (ex: pular slots), evitando que as Runas precisem acessar o `GameManager` diretamente.

**7.4. Gerenciamento de Estado (`GameManager`)**
*   Máquina de Estados finita para as fases do jogo: `SETUP` -> `PLANNING` -> `BATTLE` -> `RESOLUTION` -> `REWARD`.
*   Gerencia a curva de dificuldade (Target Score) e o inventário do jogador.

**7.5. Comunicação (Signals)**
O jogo utiliza sinais para manter a UI reativa sem acoplamento forte:
*   `Reader`: `step_started(coord)`, `score_updated(new_total)`, `sequence_finished`.
*   `GridManager`: `slot_changed(coord)` (atualiza visual do slot).
*   `GameManager`: `phase_changed`, `level_started`, `rune_selection_requested`.

## 8. Comercialização e Marketing (Indie Solo)
*   **Build in Public:** YouTube Shorts/TikTok focados no visual do "Laser" e combos matemáticos.
*   **Playtest:** Discord fechado para balanceamento.
*   **Lançamento:** Protótipo -> Demo Itch.io (Web) -> Steam Page -> Mobile Port.
