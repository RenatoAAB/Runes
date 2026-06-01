# Spec — Math & Formulas

Fonte: Reverse-engineered from `rune_instance.gd`, `battle_context.gd`, `panel_manager.gd`.
Status: Verified in codebase.
Atualizado: 2026-05-31.

## 1. Rune Score (Local)
Calculated in `RuneInstance.get_modified_score()`.

$$ \text{RuneScore} = (\text{Base} + \text{Bonus} + \text{PermBonus}) \times \text{Mult} \times \text{PermMult} $$

*   **Base:** Value from Payload (e.g., +10).
*   **Bonus:** Temporary buffs specific to this activation/round.
*   **PermBonus:** Permanent buffs stored in `permanent_buffs["score_bonus"]`.
*   **Mult:** Temporary multipliers.
*   **PermMult:** Permanent multipliers stored in `permanent_buffs["score_multiplier"]`.

## 2. Slot Context (Intermediate)
$$ \text{SlotScore} = \text{RuneScore} \times \text{SlotMultiplier} $$

*   **SlotMultiplier:** Defined in the Slot Class/Object.

## 3. Panel Score (Accumulation)
$$ \text{PanelTotal} = \sum \text{SlotScore}_{\text{activated}} $$

## 4. Global Score (Final)
Calculated in `PanelManager` (conceptually, logic distributed).

$$ \text{FinalScore} = \prod (\text{PanelTotal}_i) $$

*   Note: Panels multiply each other. If Panel 1 yields 100 and Panel 2 yields 50, Total is 5000? (Reference `PanelManager`: "Score = Panel1 x Panel2..."). Needs verification if additive or multiplicative based on game design, code comment says `Score = Panel1 × Panel2`.

## 5. Shop, Elemental Probability & Rarity Decay

### 5.1. Elemental Probability Adjustment (Pedestals)
Cada ativação de pedestal elemental adiciona um incremento de $D = 20\% = 0.20$ ao elemento canalizado $E$, reduzindo os demais proporcionalmente à probabilidade que já tinham.

$$ D = \min(0.20, 1.0 - P_E) $$
$$ S = \sum_{j \neq E} P_j $$

Para cada elemento $j \neq E$ (desde que $S > 0$):
$$ P'_j = P_j - D \times \frac{P_j}{S} $$

Para o elemento canalizado $E$:
$$ P'_E = P_E + D $$

### 5.2. Grau de Instabilidade da Loja ($I$)
Representa o nível de polarização das forças mágicas baseando-se no elemento mais saliente $P_{max} = \max(P_{\text{Fogo}}, P_{\text{Água}}, P_{\text{Ar}}, P_{\text{Terra}}, P_{\text{Espírito}})$.

$$ I = \frac{P_{max} - 0.20}{0.80} $$
Onde $I \in [0.0, 1.0]$. A estabilidade perfeita ocorre em $I = 0.0$ ($P_{max} = 20\%$).

### 5.3. Fator de Decaimento de Raridade ($S_{\text{rarity}}$)
Aplica um redutor multiplicativo às probabilidades das raridades superiores com base em curvas de potência ajustadas pela instabilidade $I$.

$$ S_{\text{rarity}}(I) = (1 - I)^{d_{\text{rarity}}} $$

Expoentes de decaimento ($d_{\text{rarity}}$):
- $d_{\text{Common}} = 0$ (Imune ao decaimento; $S_{\text{Common}} = 1.0$)
- $d_{\text{Uncommon}} = 0.5$ (Baixa sensibilidade; decaimento sublinear)
- $d_{\text{Rare}} = 1.0$ (Média sensibilidade; decaimento estritamente linear)
- $d_{\text{Epic}} = 2.0$ (Alta sensibilidade; decaimento quadrático acelerado)
- $d_{\text{Legendary}} = 4.0$ (Sensibilidade extrema; colapso hiperbólico imediato)

### 5.4. Peso Final de Sorteio de Raridade (Com Teto de Evolução/Ceiling)
Para assegurar que o aumento dinâmico do nível do jogador (`player_level`) não infle as chances do pool indefinitivamente, impõe-se um limite de saturação mágica superior (teto de peso $\text{Ceiling}$):

$$ \text{PesoBaseReal}(\text{rarity}, \text{level}) = \min(\text{PesoBase}(\text{rarity}) + \text{Bonus}(\text{rarity}) \times (\text{level} - 1), \text{Ceiling}(\text{rarity})) $$

O peso ponderado final aplicado pelo RNG à vitrine após instabilidade é calculado como:
$$ \text{PesoFinal}(\text{rarity}, \text{level}) = \text{PesoBaseReal}(\text{rarity}, \text{level}) \times S_{\text{rarity}}(I) $$

#### Tabela de Pesos Base, Bônus por Nível e Tetos de Raridade:
| Raridade | Peso Base ($\text{PesoBase}$) | Bônus/Nível ($\text{Bonus}$) | Teto de Peso ($\text{Ceiling}$) | Volatilidade ($d_{\text{rarity}}$) |
| :--- | :---: | :---: | :---: | :---: |
| **Common** | 200 | 0 | 200 (Fixo) | 0.0 (Imune) |
| **Uncommon** | 100 | 2 | 120 | 0.5 (Baixa) |
| **Rare** | 50 | 3 | 80 | 1.0 (Média) |
| **Epic**| 50 | 4 | 70 | 2.0 (Alta) |
| **Legendary**| 10 | 5 | 50 | 4.0 (Extrema) |

---

## 6. Algoritmo de Geração Elemental de Runas (Do Sorteio à Vitrine)

O preenchimento rúnico da loja deve refletir fielmente a agência elemental comprada via pedestais ($\vec{P} = \{P_{Fogo}, P_{Agua}, P_{Ar}, P_{Terra}, P_{Espirito}\}$). Para cada uma das 3 runas geradas de forma independente na vitrine, executa-se o pipeline abaixo.

### Passo 1: Determinação da Raridade ($R_{sorteada}$)
Executa um sorteio ponderado tradicional sobre as raridades habilitadas no nível do jogador, utilizando o vetor de pesos modificados:
$$ \mathcal{W} = \{ \text{PesoFinal}(r, \text{level}) \mid r \in \{\text{Common, Uncommon, Rare, Epic, Legendary}\} \} $$

### Passo 2: Sorteio do Elemento Alvo ($E_{alvo}$)
Sorteia-se um dos 5 elementos fundamentais usando diretamente o vetor de probabilidade elemental $\vec{P}$ do jogador como a tabela de chances de peso:
$$ E_{alvo} \sim \vec{P} $$

### Passo 3: Criação de Sub-Pool de Runa e Seleção Uniforme
O sistema varre todo o acervo global de runas ativas em busca de candidatas que casem com a raridade e o elemento desejado. Como duplicatas são permitidas, não há exclusão de elementos já sorteados nos outros slots da vitrine:
$$ \text{SubPool} = \{ \text{Rune } x \mid \text{Rarity}(x) = R_{sorteada} \land E_{alvo} \in \text{Elements}(x) \} $$

Se $\text{SubPool} \neq \emptyset$, seleciona-se uniformemente uma runa desse grupo utilizando:
$$ x_{sorteada} \sim \text{Uniforme}(\text{SubPool}) $$

### Passo 4: Protocolo de Contingência em Cascata (Fallback)
Se a combinação gerada não possuir runas cadastradas no acervo ativo do jogo:
1. **Fase 1: Vigilância Elemental**: Tenta-se um novo sorteio de $E_{alvo} \sim \vec{P}$ (excluindo os já testados que falharam) por até 3 rotas.
2. **Fase 2: Elasticidade Elemental**: Despreza-se $E_{alvo}$ e cria-se o sub-pool puramente à base de raridade:
   $$ \text{SubPool} = \{ \text{Rune } x \mid \text{Rarity}(x) = R_{sorteada} \} $$
3. **Fase 3: Degradação progressiva**: Rebaixa-se a raridade ($R_{sorteada} \leftarrow R_{sorteada} - 1$) e reinicia-se o Passo 3.

---

## 7. Exemplos Concretos de Resolução Estatística

### Exemplo 1: Jogador focado em Arco Híbrido (Água + Ar) sem Instabilidade Extrema
O jogador comprou pedestais de Água e de Ar igualmente, mantendo as forças estáveis.
*   **Vetor Elemental ($\vec{P}$)**: $\text{Água} = 40\%$, $\text{Ar} = 40\%$, $\text{Fogo} = 10\%$, $\text{Terra} = 10\%$, $\text{Espírito} = 0\%$
*   **Máximo Elemental ($P_{max}$)**: $40\% = 0.40$
*   **Instabilidade ($I$)**: $\frac{0.40 - 0.20}{0.80} = 0.25$
*   **Nível do Jogador**: 10 (Tetos Máximos de Peso Base atingidos).
*   **Raridade Sorteada**: **Rare** (PesoBaseReal = 80).
    *   Fator de Decaimento $S_{\text{Rare}} = (1 - 0.25)^{1.0} = 0.75$
    *   Peso Final Sorteável da Raridade Rare: $80 \times 0.75 = 60$ (Ainda muito ativa).

#### Acervo de Runas Raras no Jogo:
- `Tsunami` (Água pura)
- `Ventania` (Ar pura)
- `Névoa` (**Água e Ar** - Runa Híbrida)
- `Labareda` (Fogo pura)

#### Sorteio do Elemento Alvo ($E_{alvo}$) e Chances Uniformes:
- **Cenário A: Sorteou Água ($40\%$ de chance)**
  - $\text{SubPool(Água)} = \{\text{Tsunami}, \text{Névoa}\}$
  - Chance Uniforme: `Tsunami` $50\%$, `Névoa` $50\%$.
  - Contribuição para `Névoa`: $0.4 \times 0.5 = 20\%$.
- **Cenário B: Sorteou Ar ($40\%$ de chance)**
  - $\text{SubPool(Ar)} = \{\text{Ventania}, \text{Névoa}\}$
  - Chance Uniforme: `Ventania` $50\%$, `Névoa` $50\%$.
  - Contribuição para `Névoa`: $0.4 \times 0.5 = 20\%$.
- **Cenário C: Sorteou Fogo ($10\%$ de chance)**
  - $\text{SubPool(Fogo)} = \{\text{Labareda}\}$
  - Chance Uniforme: `Labareda` $100\%$.
  - Contribuição para `Névoa`: $0\%$.
- **Cenário D: Sorteou Terra ($10\%$ de chance)**
  - $\text{SubPool(Terra)} = \emptyset \implies$ Ativa Fallback de Elementos, migrando para Água/Ar conforme pesos.

#### Comparação de Chance de Aparição por Runa na Vitrine (Slot Único):
*   `Tsunami` (Água): $20\%$
*   `Ventania` (Ar): $20\%$
*   **`Névoa` (Água + Ar)**: $20\% + 20\% = \mathbf{40\%}$ (A runa híbrida tem o dobro de chance de oferta naturalmente pela dupla de entrada de afinidade).
*   `Labareda` (Fogo): $10\%$

---

### Exemplo 2: O Colapso por Monopólio Elemental (100% Fogo)
O jogador comprou exclusivamente pedestais de Fogo para garantir 100% de previsibilidade de elemento.
*   **Vetor Elemental ($\vec{P}$)**: $\text{Fogo} = 100\%$, todos os demais = $0\%$
*   **Máximo Elemental ($P_{max}$)**: $100\% = 1.0$
*   **Instabilidade ($I$)**: $\frac{1.0 - 0.20}{0.80} = 1.0$
*   **Resultados de Decaimento ($S_{\text{rarity}}$)**:
    - $S_{\text{Common}} = (1 - 1)^{0} = 1.0 \implies \text{PesoFinal} = 200 \times 1.0 = 200$
    - $S_{\text{Uncommon}} = (1 - 1)^{0.5} = 0.0 \implies \text{PesoFinal} = 0$
    - $S_{\text{Rare}} = (1 - 1)^{1.0} = 0.0 \implies \text{PesoFinal} = 0$
    - $S_{\text{Epic}} = (1 - 1)^{2.0} = 0.0 \implies \text{PesoFinal} = 0$
    - $S_{\text{Legendary}} = (1 - 1)^{4.0} = 0.0 \implies \text{PesoFinal} = 0$

#### Resultado da Vitrine:
O Peso Final para todas as categorias acima de Comum colapsa a zero absoluto. O sistema sorteia com 100% de certeza a raridade **Common** no Passo 1, e sorteia com 100% de certeza o elemento alvo **Fogo** no Passo 2. As 3 runas geradas na vitrine serão única e exclusivamente runas **Comuns de Fogo**, podendo conter duplicatas idênticas de forma perfeitamente natural (ex: 2 runas Comuns idênticas de Fogo do tipo `Brasa` lado a lado na vitrine).

## Links relacionados
- GDD: [[spec/gdd]]
- Painéis: [[panels]]
- Data schemas: [[impl/data_schemas]]
- Testes: [[impl/testing_checklists]]

