param ([String]$Algorithm)

if (-not $Algorithm) { $Algorithm = "SHA256" }

$source = Read-Host "Input Source Folder"
if (-not (Test-Path -LiteralPath $source)) { Write-Warning "Invalid path."; return }
$destination = Read-Host "Manifest Path"

$absDest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($destination)

# 1. Load existing hashes into memory (Normalized paths for comparison)
$registeredPaths = @{}
if (Test-Path -LiteralPath $absDest) {
    Write-Host "Reading existing manifest..." -ForegroundColor Gray
    Get-Content -LiteralPath $absDest | ForEach-Object {
        # This regex captures the hash and the path, handling the CertUtil space format
        if ($_ -match '^[A-F0-9]+\s+(.+)$') {
            $pathInFile = $matches[1].Trim()
            $registeredPaths[$pathInFile] = $true
        }
    }
}

# 2. Scan the folder
Write-Host "Analyzing folder structure..." -ForegroundColor Gray
$allFiles = Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object {
    $_.FullName -ne $absDest -and $_.Extension -ne ".sha256"
}

$totalCount = $allFiles.Count
$newCount = 0
$skippedCount = 0

# 3. The Incremental Loop
for ($i = 0; $i -lt $totalCount; $i++) {
    $currentFile = $allFiles[$i]
    $percent = [int](($i / $totalCount) * 100)

    # UI: Overall Progress
    Write-Progress -Activity "Incremental Hash ($Algorithm)" `
                   -Status "Checking: $($currentFile.Name)" `
                   -PercentComplete $percent `
                   -CurrentOperation "New: $newCount | Existing: $skippedCount"

    # CRITICAL CHECK: Only hash if the path is NOT already in our database
    if ($registeredPaths.ContainsKey($currentFile.FullName)) {
        $skippedCount++
        continue
    }

    try {
        $hash = (Get-FileHash -LiteralPath $currentFile.FullName -Algorithm $Algorithm).Hash
        # ONLY appends if the file was not found in the manifest
        "$hash  $($currentFile.FullName)" | Out-File -LiteralPath $absDest -Append -Encoding utf8
        $newCount++
        # Add to memory so we don't double-count if the script hits the same path twice
        $registeredPaths[$currentFile.FullName] = $true
    } catch {
        Write-Warning "Access Denied or Path too long: $($currentFile.FullName)"
    }
}

Write-Host "`n--- Sync Complete ---" -ForegroundColor Cyan
Write-Host "Files already in manifest: $skippedCount"
Write-Host "New files added:           $newCount"
Write-Host "Total manifest size:       $($registeredPaths.Count) entries" -ForegroundColor Green