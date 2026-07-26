# ============================================================================
# export_vault_runes.ps1 — Sincroniza runas do jogo com o vault Obsidian
# ----------------------------------------------------------------------------
# Lê resources/runes/**/*.tres (fonte da verdade) e gera uma nota markdown por
# runa em <vault>/Runes/design/runas/, com frontmatter para a Runas.base:
#   nome, elementos, raridade (pasta do .tres), arte (existe sprite?), descricao
# Copia os sprites existentes para design/runas/img/ (covers na view de cards).
# Regeneração completa: apaga as notas .md da pasta antes de reescrever.
# Rodar sempre que runas mudarem no jogo:  .\tools\export_vault_runes.ps1
# ============================================================================

$ErrorActionPreference = 'Stop'

$RepoRoot   = Split-Path $PSScriptRoot -Parent
$VaultRunas = 'C:\Users\Renato Augusto\Documents\Obsidian Vault\Psicodelila\Runes\design\runas'
$ImgDir     = Join-Path $VaultRunas 'img'

New-Item -ItemType Directory -Force $VaultRunas | Out-Null
New-Item -ItemType Directory -Force $ImgDir | Out-Null

# enum GameEnums.Element (scripts/core/game_enums.gd)
$ElemMap = @{ 0 = 'fogo'; 1 = 'agua'; 2 = 'terra'; 3 = 'ar'; 4 = 'espirito' }
# raridade = nome da pasta do .tres
$RarMap  = @{ 'common' = 'comum'; 'uncommon' = 'incomum'; 'rare' = 'raro'; 'epic' = 'epico'; 'legendary' = 'lendario' }

Get-ChildItem $VaultRunas -Filter '*.md' | Remove-Item -Confirm:$false

$treated = 0
$semArte = 0
$files = Get-ChildItem (Join-Path $RepoRoot 'resources\runes') -Recurse -Filter '*.tres'
foreach ($f in $files) {
    $text = Get-Content $f.FullName -Raw
    if ($text -notmatch 'script_class="RuneData"') { continue }
    if ($text -notmatch '(?m)^id = "([^"]+)"') { continue }
    $id = $Matches[1]

    $nome = if ($text -match '(?m)^rune_name = "([^"]+)"') { $Matches[1] } else { $id }
    $desc = if ($text -match '(?m)^description = "((?:[^"\\]|\\.)*)"') { $Matches[1] -replace '\\"', '"' } else { '' }

    $elems = @()
    if ($text -match 'elements = Array\[[^\]]*\]\(\[([^\]]*)\]\)') {
        $elems = @($Matches[1] -split ',' | ForEach-Object { $ElemMap[[int]$_.Trim()] } | Where-Object { $_ })
    }

    $rar = $RarMap[$f.Directory.Name]
    if (-not $rar) { $rar = $f.Directory.Name }

    $sprite = Join-Path $RepoRoot "sprites\runes\$id.png"
    $arte = Test-Path $sprite
    if ($arte) { Copy-Item $sprite (Join-Path $ImgDir "$id.png") -Force } else { $semArte++ }

    $descYaml = $desc -replace '\\', '\\' -replace '"', '\"'
    $elemYaml = if ($elems.Count) { ($elems | ForEach-Object { "`n  - $_" }) -join '' } else { ' []' }
    $arteYaml = if ($arte) { 'true' } else { 'false' }

    $lines = @(
        '---'
        'type: runa'
        "nome: $nome"
        "elementos:$elemYaml"
        "raridade: $rar"
        "arte: $arteYaml"
        "descricao: `"$descYaml`""
    )
    if ($arte) { $lines += "image: `"[[$id.png]]`"" }
    $lines += @(
        '---'
        ''
        '> [!info] Nota auto-gerada de `resources/runes` — não editar. Atualizar: `tools/export_vault_runes.ps1`.'
        ''
        "# $nome"
        ''
    )
    if ($arte) { $lines += @("![[$id.png|96]]", '') }
    $lines += @(
        $desc
        ''
        ('Elementos: ' + ($(if ($elems.Count) { $elems -join ', ' } else { '—' })) + " · Raridade: $rar")
        ''
        'Catálogo: [[runes_set_4]]'
    )

    [System.IO.File]::WriteAllLines((Join-Path $VaultRunas "$id.md"), $lines)
    $treated++
}

Write-Host "Runas exportadas: $treated (sem arte: $semArte) -> $VaultRunas"
