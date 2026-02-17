# Archive / Registration Logic
$source = Read-Host "Input Source Path (Folder or File)"
if (-not (Test-Path $source)) { Write-Warning "Path not found."; return }

$destination = Read-Host "Target Manifest Path (e.g., C:\Audit\files.sha256)"

# Build lookup table of already hashed files
$registeredPaths = @{}
if (Test-Path $destination) {
    Write-Host "Analyzing existing manifest..." -ForegroundColor Gray
    Get-Content $destination | ForEach-Object {
        if ($_ -match '^[A-F0-9]{64}\s+(.+)$') {
            $registeredPaths[$matches[1].Trim()] = $true
        }
    }
}

# Filter for new items only
$items = Get-ChildItem -Path $source -File -Recurse | Where-Object { -not $registeredPaths.ContainsKey($_.FullName) }

if ($items.Count -eq 0) {
    Clear-Host
    Write-Host "All checksums registered. No new files to process." -ForegroundColor Green
    return
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$index = 0
foreach ($item in $items) {
    $index++
    Write-Progress -Activity "PowerHash: Registering Checksums" -Status "Hashing $index/$($items.Count)" -PercentComplete (($index/$items.Count)*100)
    try {
        $hash = (Get-FileHash $item.FullName -Algorithm SHA256).Hash
        "$hash  $($item.FullName)" | Out-File $destination -Append -Encoding utf8
    } catch {
        Write-Warning "Skipped (Access Denied/In Use): $($item.FullName)"
    }
}

$sw.Stop()
Clear-Host
Write-Host "Success: $index new checksums registered." -ForegroundColor Green
Write-Host "Manifest: $destination"
Write-Host "Time: $($sw.Elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow