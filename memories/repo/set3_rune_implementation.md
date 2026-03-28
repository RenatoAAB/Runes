# Set 3 Rune Implementation

## Status: COMPLETE (resource generation)

## Generated: 154 files total

### Shared Resources (new)
- filters: filter_fire_air.tres, filter_water_earth.tres
- conditions: condition_2_earth_adjacent, condition_2_air_adjacent, condition_3_water_adjacent, condition_consecutive_2, condition_simultaneous, condition_adj_mana_residue, condition_adj_mana_anomaly, condition_adj_residue_and_anomaly
- selectors: selector_above, selector_sequence_both

### Effect Files: 77 new ge_s3_*.tres files in resources/effects/rune_effects/

### Rune Files: 63 rune .tres files across all rarities

## Rune Roster (Set 3)
- **Fogo (7):** Incendio, Plasma, Calor, Explosao, Queimadura, Labareda, Supernova
- **Agua (6):** Gota, Lago, Chuva, Rio, Cachoeira, Fluxo
- **Ar (5):** Vento, Redemoinho, Pressao, Vendaval, Furacao
- **Terra (10):** Rocha, Tremor, Terremoto, Quartzo, Ametista, Topazio, Esmeralda, Estalactite, Diamante, Rubi
- **Fogo+Terra (3):** Lava, Obsidiana, Erupcao
- **Fogo+Agua (3):** Oleo, Acido, Ebulicao
- **Fogo+Ar (3):** Raio, Eletricidade, Conveccao
- **Agua+Terra (3):** Gelo, Lama, Praia
- **Agua+Ar (4):** Corrente, Geada, Bolha, Nuvem
- **Ar+Terra (3):** Areia, Poeira, Sedimentacao
- **Espirito (9):** Trevas, Luz, Caos, Tempo, Ordem, Entropia, Mudanca, Pleroma, Vacuo
- **Espirito+Elem (5):** Fenix, Empatia, Ninfa, Djinn, Golem
- **Triple (3):** Vida, Estagnacao, Gravidade

## ID Conflicts Resolved
- Removed old common/rune_plasma.tres (kept uncommon/ set 3 version)
- Removed old uncommon/rune_djinn.tres (kept rare/ set 3 version)
- Removed old uncommon/rune_golem.tres (kept rare/ set 3 version)

## Notes
- All set 3 runes: 1 activation, indestructible (except Gota, Lama, Fenix)
- Rarity NOT linked to element composition
- Old set 1/2 runes still exist alongside (fire, water, air, etc.)
- Tremor swap_previous_to_below uses ActionSwapPosition (may need custom action)
- Terremoto swap uses simplified approach
- Generation script: tools/generate_set3_runes.ps1
