$Input = [Console]::In.ReadToEnd() | ConvertFrom-Json
$Command = $Input.tool_input.command
if ([string]::IsNullOrWhiteSpace($Command)) {
    exit 0
}
if ($Command.Trim() -notmatch '^obsidian(\.com)?\s') {
    Write-Error "Blocked: game-designer may only run 'obsidian ...' CLI commands, no other shell commands."
    exit 2
}
exit 0
