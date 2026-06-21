$targetFile = "debug docs\LOGS_APP_SURVEILLEE_EPURES.md"
$appendFile = "debug docs\_append_content.md"

# Read all lines from target, drop the last (truncated) line
$lines = Get-Content $targetFile
$keptLines = $lines[0..($lines.Length - 2)]
$keptLines | Set-Content -Path $targetFile -Encoding UTF8

# Append the new content
Get-Content $appendFile -Encoding UTF8 | Add-Content -Path $targetFile -Encoding UTF8

# Cleanup
Remove-Item $appendFile -Force

Write-Host "Done. File size:"
(Get-Item $targetFile).Length
Write-Host "Line count:"
(Get-Content $targetFile).Count
