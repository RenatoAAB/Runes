# Sistema — Economia e Loja

Fonte: Roadmap Fase 4-5; scripts `scripts/logic/shop_manager.gd`, `scripts/logic/game_manager.gd`, payloads de economia.
Atualizado: 2026-05-31.
Owner: design/tech.

## Modelo

### Qual a moeda?
- A moeda são pedras de mana (Mana).

### Como se adquire?
- O jogador começa com 5 Mana.
- O jogador ganha 5 Mana cada vez que ganha uma rodada.
- **Morte Súbita**: Perder uma rodada resulta em fracasso imediato (Game Over), exigindo que o jogador reinicie a partida (Restart). Não há mecânica de misericórdia ou catch-up econômico pós-derrota.
- **Rendimento de Juros (Poupança)**: Manas guardados rendem juros à base de poupança acumulativa. Para cada 5 Mana não utilizados guardados ao final da rodada, o jogador recebe 1 Mana extra de juros.
	- Exemplo: Jogador vence a rodada mantendo 11 de mana intocados. Ele recebe 5 (bônus de vitória) + 2 (juros correspondentes a 11 mana), totalizando 7 novos manas para gastar.
	- O valor máximo de juros acumuláveis por rodada é de 5 Mana (conquistado ao reter 25 ou mais de mana).

### Inventário da Loja e Jogador
- **Capacidade do Inventário**: O inventário extra (bolsa/compartimento de reserva) do jogador possui um tamanho limite absoluto de **8 slots** (lugares).
- **Consumo de Espaço**: Qualquer item físico comprado na loja — seja uma Runa, uma peça de slot (Slot Piece) ou um modificador (Slot Modifier) — ocupa exatamente **1 espaço** no inventário. As Relíquias não entram nessa reserva, integrando-se diretamente aos buffs passivos do painel.
- **Trava de Compra**: O jogador **não pode comprar** nenhum item da loja caso seu inventário de bolsa esteja cheio (capacidade em 8/8).
- **Área de Reciclagem (Venda)**: Área drag-and-drop para liquidação física de itens. Ela é universal e aceita não apenas Runas, mas também **Slot Pieces e Slot Modifiers**. Os valores e cotações de revenda encontram-se descritos na tabela de preços abaixo.

### O que tem na loja?
- **Pedestais (Seleção Rúnica)**
	- O jogador tem à disposição 6 opções de pedestais de rolagem: 1 Neutro e 5 Elementais (Fogo, Água, Ar, Terra, Espírito).
	- **Fluxo de Ativação**: Acionar um pedestal custa exatamente **1 de Mana**. A ativação limpa a vitrine atual de ofertas de runas na loja e gera **3 runas inéditas** à venda, ajustadas pelas novas probabilidades elementais da run. O jogador deve pagar normalmente o preço associado à raridade destas runas para guardá-las ou usá-las (valores variando de $2 a $10).
	- **Permissão de Duplicidade**: Duplicatas são permitidas. O sistema sorteia cada uma das 3 runas de forma independente. Logo, a vitrine pode conter **runas idênticas** em gôndolas separadas no mesmo refresh se as rolagens coincidirem.
	- **Manipulação de Probabilidade**: Começa-se com uma base equilibrada de 20% de peso de sorteio para cada um dos 5 elementos. Selecionar um pedestal elemental concede **+20%** à probabilidade do elemento correspondente, reduzindo os outros 4 de forma estritamente proporcional. A somatória dos pesos deve obrigatoriamente totalizar 100% e nenhum elemento pode decair abaixo de 0%. Essa distribuição de forças persiste por toda a jornada e só é reiniciada ao configurar um Novo Jogo. O pedestal Neutro roda novas ofertas baseado estritamente nas probabilidades vigentes sem alterá-las.
	- **Fórmula de Rebalanceamento Proporcional**:
		Ao adicionar o incremento $D = 0.20$ ao elemento escolhido $E$:
		$$ D = \min(0.20, 1.0 - P_E) $$
		Soma das probabilidades dos outros elementos: $S = \sum_{j \neq E} P_j$
		Para cada elemento $j \neq E$ (onde $S > 0$):
		$$ P'_j = P_j - D \times \frac{P_j}{S} $$
		$$ P'_E = P_E + D $$

	- **Como a Distribuição Funciona no Sorteio (Agência do Jogador)**:
		A distribuição de probabilidade elemental $\vec{P}$ dá agência real ao jogador através de um sorteio em duas etapas lógicas (Pipelines) executado de forma idêntica para cada slot da vitrine:
		1. **Sorteador de Alvo**: Primeiro, sorteia-se a Raridade da runa com base na fórmula de decaimento de instabilidade. Depois, sorteia-se qual será o **Elemento Alvo** ($E_{alvo}$) usando o vetor de probabilidade $\vec{P}$ como pesos ponderados diretamente.
		2. **Seleção de Instância**: O sistema filtra as runas registradas no jogo buscando as que casam tanto com a Raridade sorteada quanto com a presença do $E_{alvo}$ no array de elementos da runa. Sorteia-se uma dessas runas válidas utilizando distribuição uniforme simples dentro do sub-pool.
		3. **Tratamento de Pools Vazios (Fallback)**: Caso não haja nenhuma runa física correspondente à combinação exata `(Raridade, Elemento Alvo)` no estágio atual, o jogo engaja um dreno de emergência inteligente em cascata de forma a nunca travar o visor da loja (regras matemáticas detalhadas em [[math_formulas]]).

	- **Instabilidade Rúnica (Restrição de Raridade)**: Forçar exageradamente focar em apenas uma vertente elemental polariza e desestabiliza a canalização de energia da loja. Essa instabilidade sufoca a aparição de raridades elevadas (Raras, Épicas e Lendárias), gerando apenas runas comuns. Manter uma distribuição plana e equilibrada (próxima de 20% cada) maximiza o potencial de canalização, fornecendo as maiores taxas de aparecimento de peças nobres.
	- **Fórmula Matemática de Instabilidade ($I$) e Decaimento de Raridade**:
		O Grau de Instabilidade ($I$) varia de $0.0$ a $1.0$ e é calculado com base no elemento de maior peso $P_{max} = \max(P_i)$:
		$$ I = \frac{P_{max} - 0.20}{0.80} $$
		
		Cada raridade de runa possui um expoente de sensibilidade ao decaimento ($d_{\text{rarity}}$). O multiplicador de peso de drop para cada raridade sob instabilidade ($S_{\text{rarity}}$) segue uma curva de decaimento de potência:
		$$ S_{\text{rarity}}(I) = (1 - I)^{d_{\text{rarity}}} $$
		
		Valores de sensibilidade regulados ($d_{\text{rarity}}$):
		- $d_{\text{Common}} = 0$ (Imune, o peso de drop de Comuns nunca é reduzido)
		- $d_{\text{Uncommon}} = 0.5$ (Baixa sensibilidade / decaimento suave)
		- $d_{\text{Rare}} = 1.0$ (Média sensibilidade / decaimento estritamente linear)
		- $d_{\text{Epic}} = 2.0$ (Alta sensibilidade / decaimento quadrático agressivo)
		- $d_{\text{Legendary}} = 4.0$ (Extrema sensibilidade / colapso imediato)
		
		Modificação Final de Peso de Sorteio (Com Teto/Ceiling para crescimento por nível):
		$$ \text{PesoFinal}(\text{rarity}, \text{player\_level}) = \min(\text{PesoBase}(\text{rarity}) + \text{Bonus} \times (\text{player\_level} - 1), \text{Ceiling}(\text{rarity})) \times S_{\text{rarity}}(I) $$

- **Aprimorar Maquinário Rúnico (Slots e Modifiers)**
	- Ofertados: 1 peça de Slot (Slot Piece) e 1 Modificador (Slot Modifier) em vitrines dedicadas.
	- **Mecânica de Overclock**: Não existe uma recarga simples por mana para o maquinário. Para tentar novas opções, o jogador usa o "Overclock" — custa **1 de Mana** (usável apenas 1 vez por rodada). O Overclock sorteia e coloca à venda **1 Slot Piece extra** e **1 Slot Modifier extra** ao lado das primeiras ofertas (as quais continuam imutáveis).
	- **Defeitos Permanentes das Peças de Overclock**:
		- O defeito da **Slot Piece** extra do overclock é a impossibilidade permanente de receber qualquer Slot Modifier no futuro.
		- O defeito do **Slot Modifier** extra do overclock é que ele vem com a tag/condição permanente `anomalous`.
	- **Mecânica da Anomalia de Mana (Revisada)**: Um slot contendo um modificador `anomalous` acumula uma anomalia de mana por cima do slot toda vez que o leitor passa nele. Quando o leitor atravessa e processa o slot, a anomalia é destruída e drena **2 Mana do jogador**. **A runa instalada naquele slot NÃO é mais destruída junto.**

- **Fazer Pacto (Relíquias)**
	- Ofertada: 1 Relíquia por rodada padrão.
	- Preço único de compra: **10 Mana**. Preço de revenda na reciclagem: 5 Mana.
	- Mecânica de Refresh: O jogador pode pagar **1 Mana** para renovar a Relíquia oferecida (máximo de 1 vez por rodada).
	- Pactos e Juramentos: *[Fase de refinamento futuro - Não considerar para a implementação do MVP]*

## UI/Fluxo
- A interface da loja exibe as runas sorteadas, slots, modificadores, relíquias e reprocessos de pedestais. Navegação bidirecional fluida com o painel estrutural. O clique realiza a finalização do escopo de compras.
- No início de cada rodada (inclusive no início absoluto do jogo), um reroll automático global e limpo preenche novamente todas as gôndolas e vitrines de vendas com equipamentos novos.

## Custos Atuais (ShopConfig) (Refeitos)
Implementados em `scripts/data/shop_config.gd`:

### Runas (por raridade)
| Raridade  | Compra | Venda |
| --------- | ------ | ----- |
| Common    | $2     | $1    |
| Uncommon  | $3     | $1    |
| Rare      | $5     | $2    |
| Epic      | $7     | $3    |
| Legendary | $10    | $5    |

### Slot Pieces
| Quantidade de slots juntos | Compra | Venda |
| -------------------------- | ------ | ----- |
| 1                          | $3     | $1    |
| 2                          | $5     | $2    |
| 3                          | $7     | $3    |
| 4                          | $9     | $4    |

### Slot Modifiers
|             | Compra | Venda |
| ----------- | ------ | ----- |
| preço unico | $4     | $1    |

### Relíquias
|             | Compra | Venda |
| ----------- | ------ | ----- |
| Preço único | $10    | $5    |

