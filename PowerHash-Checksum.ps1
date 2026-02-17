param ([String]$Algorithm)

if (-not $Algorithm) { $Algorithm = "SHA256" }

$source = Read-Host "Input Source Folder"
if (-not (Test-Path -LiteralPath $source)) { Write-Warning "Invalid path."; return }
$destination = Read-Host "Manifest Path"

$absDest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($destination)

# 1. Load existing hashes into a hash table for instant lookup
$registeredPaths = @{}
if (Test-Path -LiteralPath $absDest) {
    Write-Host "Syncing with existing manifest..." -ForegroundColor Gray
    Get-Content -LiteralPath $absDest | ForEach-Object {
        if ($_ -match '^[A-F0-9]+\s+(.+)$') { $registeredPaths[$matches[1].Trim()] = $true }
    }
}

# 2. Get ALL files in the folder (This is the "Full Scale")
Write-Host "Analyzing folder structure..." -ForegroundColor Gray
$allFiles = Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object {
    $_.FullName -ne $absDest -and $_.Extension -ne ".sha256"
}

$totalCount = $allFiles.Count
$newCount = 0
$skippedCount = 0

# 3. Process the loop with a "Total Progress" view
for ($i = 0; $i -lt $totalCount; $i++) {
    $currentFile = $allFiles[$i]

    # Update progress bar for EVERY file (even skipped ones) so it moves smoothly
    $percent = [int](($i / $totalCount) * 100)
    Write-Progress -Activity "Overall Progress ($Algorithm)" `
                   -Status "Checking: $($currentFile.Name)" `
                   -PercentComplete $percent `
                   -CurrentOperation "New: $newCount | Already Hashed: $skippedCount"

    if ($registeredPaths.ContainsKey($currentFile.FullName)) {
        $skippedCount++
        continue # Move to next file immediately
    }

    # If it's not registered, hash it
    try {
        $hash = (Get-FileHash -LiteralPath $currentFile.FullName -Algorithm $Algorithm).Hash
        "$hash  $($currentFile.FullName)" | Out-File -LiteralPath $absDest -Append -Encoding utf8
        $newCount++
    } catch {
        Write-Warning "Failed: $($currentFile.FullName)"
    }
}

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
Write-Host "Verified/Skipped: $skippedCount"
Write-Host "Newly Hashed:    $newCount"
Write-Host "Total Managed:   $totalCount" -ForegroundColor Green