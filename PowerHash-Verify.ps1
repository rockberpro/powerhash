param ([String]$Algorithm)
if (-not $Algorithm) { $Algorithm = "SHA256" }

$manifest = Read-Host "Path to .sha256 manifest"
if (-not (Test-Path -LiteralPath $manifest)) { Write-Warning "Manifest not found."; return }

# Load manifest lines
$lines = Get-Content -LiteralPath $manifest
$total = $lines.Count
$passed = 0
$failed = 0
$missing = 0

Write-Host "Starting Audit of $total files..." -ForegroundColor Cyan

for ($i = 0; $i -lt $total; $i++) {
    $line = $lines[$i]
    # Split hash and path (handles the double-space format)
    if ($line -match '^([A-F0-9]+)\s+(.+)$') {
        $expectedHash = $matches[1]
        $filePath = $matches[2].Trim()

        $percent = [int](($i / $total) * 100)

        # UI: Progress Bar
        Write-Progress -Activity "Verifying Integrity ($Algorithm)" `
                       -Status "File $($i+1) of $total ($percent%)" `
                       -PercentComplete $percent `
                       -CurrentOperation "Checking: $(Split-Path $filePath -Leaf)"

        if (Test-Path -LiteralPath $filePath) {
            try {
                $actualHash = (Get-FileHash -LiteralPath $filePath -Algorithm $Algorithm).Hash
                if ($actualHash -eq $expectedHash) {
                    $passed++
                } else {
                    Write-Host "[MISMATCH] $filePath" -ForegroundColor Red
                    $failed++
                }
            } catch {
                Write-Host "[ERROR] Could not read $filePath" -ForegroundColor Yellow
                $failed++
            }
        } else {
            Write-Host "[MISSING] $filePath" -ForegroundColor Gray
            $missing++
        }
    }
}

# Final Report
Write-Host "`n--- Audit Results ---" -ForegroundColor Cyan
Write-Host "Verified: $passed" -ForegroundColor Green
if ($failed -gt 0) { Write-Host "Corrupted: $failed" -ForegroundColor Red }
if ($missing -gt 0) { Write-Host "Missing:  $missing" -ForegroundColor Yellow }