param ([String]$Algorithm = "SHA256")

$source = Read-Host "Input Source Folder"
if (-not (Test-Path -LiteralPath $source)) { Write-Warning "Invalid path."; return }
$destination = Read-Host "Manifest Path"
$absDest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($destination)

# 1. Load existing hashes into memory
$registeredPaths = @{}
if (Test-Path -LiteralPath $absDest) {
    Write-Host "Reading existing manifest..." -ForegroundColor Gray
    Get-Content -LiteralPath $absDest | ForEach-Object {
        if ($_ -match '^[A-F0-9]+\s+(.+)$') {
            $pathInFile = $matches[1].Trim()
            $registeredPaths[$pathInFile] = $true
        }
    }
}

# 2. Scan and Filter (The "Smart" way)
Write-Host "Analyzing folder structure..." -ForegroundColor Gray
$allFiles = Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object {
    $_.FullName -ne $absDest -and $_.Extension -ne ".sha256"
}

# Split the work: What's already there vs. what's actually new
$newFiles = $allFiles | Where-Object { -not $registeredPaths.ContainsKey($_.FullName) }
$skippedCount = $allFiles.Count - $newFiles.Count
$newCount = 0

# 3. The Incremental Loop (Only iterates over NEW files)
if ($newFiles.Count -eq 0) {
    Write-Host "No new files found. Everything is up to date." -ForegroundColor Green
} else {
    for ($i = 0; $i -lt $newFiles.Count; $i++) {
        $currentFile = $newFiles[$i]
        $percent = [int](($i / $newFiles.Count) * 100)

        Write-Progress -Activity "Incremental Hash ($Algorithm)" `
                       -Status "File $($i+1) of $($newFiles.Count) ($percent%)" `
                       -PercentComplete $percent `
                       -CurrentOperation "Hashing: $($currentFile.Name)"

        try {
            $hash = (Get-FileHash -LiteralPath $currentFile.FullName -Algorithm $Algorithm).Hash
            "$hash  $($currentFile.FullName)" | Out-File -LiteralPath $absDest -Append -Encoding utf8
            $newCount++
            $registeredPaths[$currentFile.FullName] = $true
        } catch {
            Write-Warning "Access Denied or Path too long: $($currentFile.FullName)"
        }
    }
}

Write-Host "`n--- Sync Complete ---" -ForegroundColor Cyan
Write-Host "Files already in manifest: $skippedCount"
Write-Host "New files added:           $newCount"
Write-Host "Total manifest size:       $($registeredPaths.Count) entries" -ForegroundColor Green