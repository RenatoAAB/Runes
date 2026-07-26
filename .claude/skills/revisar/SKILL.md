---
name: revisar
description: Revisa as notas modificadas recentemente no vault Runes (Psicodelila) e as adequa às regras do sistema definidas em Runes/_meta/CONVENCOES.md — pasta certa, frontmatter, tags, nomenclatura, links de trio e wikilinks quebrados. Use quando o usuário pedir /revisar ou uma revisão de conformidade/organização do vault. Argumento opcional, número de dias a cobrir (padrão 7).
---

# /revisar — conformidade do vault Runes

Vault: `C:\Users\Renato Augusto\Documents\Obsidian Vault\Psicodelila`, pasta `Runes/`.
Regras canônicas (fonte da verdade — **leia antes de qualquer correção**):
- `Runes/_meta/CONVENCOES.md` — contratos de pasta, frontmatter mínimo, nomenclatura, tags, trio de sistema
- `Runes/_meta/FLUXOS.md` — fluxos operacionais
- Skill `game-design-status` — tags de ciclo de vida em docs de design

## 1. Coletar escopo

Notas `.md` e `.base` modificadas nos últimos N dias (argumento do comando; padrão 7):

```bash
find "<vault>/Runes" -name "*.md" -o -name "*.base" -mtime -N
```

**Excluir sempre**: `Runes/design/runas/` (auto-gerada), `Runes/impl/notes/archive/`, `Runes/_meta/templates/`, `.obsidian/`, `_claude-edits/`, `Psicodelia/`.

Se a lista for grande (>15 arquivos), usar um subagente Explore com `model: haiku` para a leitura em massa e trazer só os achados.

## 2. Checklist por nota

1. **Pasta certa** — o conteúdo respeita o contrato da pasta (tabela em CONVENCOES)? Ex.: brainstorm em `spec/` é violação; tarefa fora de `tasks/` é violação.
2. **Frontmatter mínimo** — `type` e `criada` presentes; em `tasks/` também `status` ∈ `backlog|proximo|fazendo|feito`, `area` ∈ `arte|design|impl|conteudo|meta`, `tamanho` ∈ `P|M|G`.
3. **Nomenclatura** — arquivos criados no período em snake_case português (não renomear antigos). **Exceção: `tasks/`** — cartões criados pelo Kanban usam o título como nome do arquivo (Title Case com espaços); isso é esperado, não é violação.
4. **Tags de ciclo de vida** — em docs de design/expansão, toda ideia nova carrega exatamente **uma** tag (`EXPLORE:`/`WORK IN PROGRESS:`/etc., formato exato da skill). Item que mudou de estado sem atualizar a tag é violação.
5. **Tags transversais** — nota viva de sistema sem `#sys/*` aplicável.
6. **Trio de sistema** — spec/design/roadmap novos ou alterados linkam seus pares nas duas direções.
7. **Wikilinks quebrados** — verificar no app (não por grep):
   ```bash
   obsidian vault="Psicodelila" eval code="const u=app.metadataCache.unresolvedLinks; ..."
   ```
8. **Sync de runas** — se `resources/runes/` ou `sprites/runes/` do repo (`C:\Users\55119\Documents\runes`) mudou depois da última geração de `design/runas/`, rodar `tools\export_vault_runes.ps1`.

## 3. Agir

- **Corrigir direto** (mecânico, sem julgamento): frontmatter faltante/inválido, wikilinks quebrados com alvo óbvio, links de trio faltantes, sync de runas.
- **Propor, não executar** (julgamento do designer): mover nota de pasta, renomear arquivo, promover/rebaixar tag de ciclo de vida (`DECIDED:` é exclusivo do designer), deletar qualquer coisa.
- Se a seção **Agora** da `HOME.md` estiver defasada em relação ao Quadro/frentes, propor o texto novo.

## 4. Relatório

Terminar com:
- Tabela: nota | problema(s) | ação (✅ corrigido / 💬 proposto)
- Estado do Quadro: contagem por coluna (`grep -c` de `status:` em `tasks/`)
- Uma linha: inbox de insights vazia ou com N itens pendentes de triagem
