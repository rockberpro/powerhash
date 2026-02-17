param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Checksum", "Verify")]
    [String]$Mode
)

Clear-Host
Write-Host "--- PowerHash Suite (SHA-256) ---" -ForegroundColor Cyan

# Interactive menu if no parameter is provided
if (-not $Mode) {
    Write-Host "1. Checksum (Register new files)"
    Write-Host "2. Verify   (Audit existing manifest)"
    $choice = Read-Host "`nSelect an option (1-2)"
    $Mode = if ($choice -eq "1") { "Checksum" } else { "Verify" }
}

# Resolve the path to the worker scripts
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$workerFile = "PowerHash-$Mode.ps1"
$workerPath = Join-Path $scriptPath $workerFile

if (Test-Path $workerPath) {
    & $workerPath
} else {
    Write-Error "Execution Error: '$workerFile' not found in $scriptPath"
}