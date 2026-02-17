# Verification / Audit Logic
$manifest = Read-Host "Path to manifest for verification"
if (-not (Test-Path $manifest)) { Write-Warning "Manifest not found."; return }

$lines = Get-Content $manifest | Where-Object { $_ -match '^[A-F0-9]{64}\s+.+$' }
$results = [System.Collections.Generic.List[PSObject]]::new()
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$index = 0
foreach ($line in $lines) {
    $index++
    if ($line -match '^([A-F0-9]{64})\s+(.+)$') {
        $storedHash = $matches[1]
        $filePath   = $matches[2].Trim()

        Write-Progress -Activity "PowerHash: Verifying Integrity" -Status "Checking $index/$($lines.Count)" -PercentComplete (($index/$lines.Count)*100)

        $status = "MATCH"
        if (-not (Test-Path $filePath)) {
            $status = "MISSING"
        } else {
            $currentHash = (Get-FileHash $filePath -Algorithm SHA256).Hash
            if ($currentHash -ne $storedHash) { $status = "MISMATCH" }
        }
        $results.Add([PSCustomObject]@{ Status = $status; File = (Split-Path $filePath -Leaf); Path = $filePath })
    }
}
$sw.Stop()

Clear-Host
Write-Host "--- PowerHash Audit Results ---`n" -ForegroundColor Cyan
$results | Group-Object Status | Select-Object Count, Name | Format-Table -AutoSize

$failures = $results | Where-Object { $_.Status -ne "MATCH" }
if ($failures) {
    Write-Host "INTEGRITY FAILURES FOUND:" -ForegroundColor Red
    $failures | Sort-Object Status | Format-Table Status, File, Path -AutoSize
} else {
    Write-Host "Integrity Verified: All files match the manifest." -ForegroundColor Green
}
Write-Host "`nTime elapsed: $($sw.Elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow