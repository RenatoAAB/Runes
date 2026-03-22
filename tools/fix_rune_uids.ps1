# Phase 8.7b - Strip UIDs from ext_resource lines that reference new GameEffect files
# Godot uses UID over path, so old UIDs would still resolve to old effect files

$runesDir = "c:\Users\55119\Documents\runes\resources\runes"
$updated = 0

Get-ChildItem "$runesDir" -Recurse -Filter "rune_*.tres" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw -Encoding UTF8
    $original = $content
    
    # Pattern: ext_resource lines with uid that point to rune_effects/ge_ paths
    # Remove the uid="uid://XXXX" portion from these lines
    $content = $content -replace '(\[ext_resource type="Resource") uid="uid://[^"]+" (path="res://resources/effects/rune_effects/ge_)', '$1 $2'
    
    if ($content -ne $original) {
        Set-Content $file -Value $content -NoNewline -Encoding UTF8
        Write-Output "FIXED UIDs: $($_.Name)"
        $updated++
    }
}

Write-Output "`nFixed: $updated rune files"
