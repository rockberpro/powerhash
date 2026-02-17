param ([String]$Algorithm)

if (-not $Algorithm) {
    Write-Host "--- Checksum Registration ---" -ForegroundColor Cyan
    Write-Host "Available: MD5, SHA1, SHA256, SHA384, SHA512"
    $Algorithm = Read-Host "Enter Algorithm [Default: SHA256]"
    if ([string]::IsNullOrWhiteSpace($Algorithm)) { $Algorithm = "SHA256" }
}

$source = Read-Host "Input Source (Folder or File)"
if (-not (Test-Path $source)) { Write-Warning "Invalid path."; return }
$destination = Read-Host "Manifest Path (e.g., records.sha256)"

# Build existing database to skip already hashed files
$registeredPaths = @{}
if (Test-Path $destination) {
    Get-Content $destination | ForEach-Object {
        if ($_ -match '^[A-F0-9]+\s+(.+)$') { $registeredPaths[$matches[1].Trim()] = $true }
    }
}

$items = Get-ChildItem -Path $source -File -Recurse | Where-Object { -not $registeredPaths.ContainsKey($_.FullName) }

if ($items.Count -eq 0) {
    Write-Host "All checksums registered using $Algorithm. Nothing to do." -ForegroundColor Green
    return
}

$index = 0
foreach ($item in $items) {
    $index++
    Write-Progress -Activity "Hashing ($Algorithm)" -Status "Processing $item" -PercentComplete (($index/$items.Count)*100)
    try {
        $hash = (Get-FileHash $item.FullName -Algorithm $Algorithm).Hash
        "$hash  $($item.FullName)" | Out-File $destination -Append -Encoding utf8
    } catch { Write-Warning "Skipped: $($item.FullName)" }
}
Write-Host "`nSuccess: $index files registered." -ForegroundColor Green