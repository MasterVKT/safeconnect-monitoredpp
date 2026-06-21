# Prepends .venv activation to every PowerShell tool command.
# PowerShell syntax: . '.venv\Scripts\Activate.ps1'
# Exits 0 (no-op) if command is empty — never blocks.

$raw = [System.Console]::In.ReadToEnd()
if (-not $raw.Trim()) { exit 0 }

try {
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0
}

$cmd = $data.tool_input.command
if (-not $cmd) { exit 0 }

$venvActivate = '.venv\Scripts\Activate.ps1'
$newCmd = "if (Test-Path '$venvActivate') { . '$venvActivate' }; $cmd"

$output = @{
    hookSpecificOutput = @{
        hookEventName = 'PreToolUse'
        updatedInput  = @{ command = $newCmd }
    }
}
Write-Output ($output | ConvertTo-Json -Compress -Depth 5)
