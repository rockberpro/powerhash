param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Checksum", "Verify")]
    [String]$Mode,
    [Parameter(Mandatory=$false)]
    [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")]
    [String]$Algorithm
)

Clear-Host
Write-Host "--- PowerHash Suite ---" -ForegroundColor Cyan

if (-not $Mode) {
    Write-Host "Select Operation:"
    Write-Host "1. Checksum (Register/Add files)"
    Write-Host "2. Verify   (Audit manifest)"
    $mChoice = Read-Host "`nChoice (1-2)"
    $Mode = if ($mChoice -eq "1") { "Checksum" } else { "Verify" }
}

if (-not $Algorithm) {
    Write-Host "`nSupported Hashing Methods:" -ForegroundColor Gray
    Write-Host "1. SHA256 (Default)"
    Write-Host "2. SHA512"
    Write-Host "3. MD5"
    Write-Host "4. SHA1"
    Write-Host "5. SHA384"
    $aChoice = Read-Host "`nSelect Algorithm (1-5, or Enter for SHA256)"
    $Algorithm = switch ($aChoice) {
        "1" { "SHA256" }; "2" { "SHA512" }; "3" { "MD5" }; "4" { "SHA1" }; "5" { "SHA384" }; Default { "SHA256" }
    }
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$worker = Join-Path $scriptPath "PowerHash-$Mode.ps1"

if (Test-Path $worker) {
    & $worker -Algorithm $Algorithm
} else {
    Write-Error "Error: Worker script not found at $worker"
}