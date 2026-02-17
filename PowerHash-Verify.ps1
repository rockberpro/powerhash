param ([String]$Algorithm)

$manifest = Read-Host "Select manifest file to verify"
if (-not (Test-Path $manifest)) { return }

if (-not $Algorithm) {
    # Detect algorithm based on the character count of the first hash found
    $firstLine = Get-Content $manifest | Select-Object -First 1
    if ($firstLine -match '^([A-F0-9]+)\s+') {
        $len = $matches[1].Length
        $Algorithm = switch ($len) {
            32  { "MD5" }
            40  { "SHA1" }
            64  { "SHA256" }
            96  { "SHA384" }
            128 { "SHA512" }
            Default { "SHA256" }
        }
        Write-Host "Auto-detected $Algorithm based on manifest hash length." -ForegroundColor Gray
    } else {
        $Algorithm = "SHA256"
    }
}

$lines = Get-Content $manifest | Where-Object { $_ -match '^[A-F0-9]+\s+.+$' }
$results = New-Object System.Collections.Generic.List[PSObject]

foreach ($line in $lines) {
    if ($line -match '^([A-F0-9]+)\s+(.+)$') {
        $storedHash = $matches[1]
        $filePath   = $matches[2].Trim()
        
        $status = "MATCH"
        if (-not (Test-Path $filePath)) { $status = "MISSING" }
        else {
            $currentHash = (Get-FileHash $filePath -Algorithm $Algorithm).Hash
            if ($currentHash -ne $storedHash) { $status = "MISMATCH" }
        }
        $results.Add([PSCustomObject]@{Status=$status; File=(Split-Path $filePath -Leaf); Path=$filePath})
    }
}

Clear-Host
Write-Host "--- Audit Report ($Algorithm) ---" -ForegroundColor Cyan
$results | Group-Object Status | Select-Object Count, Name | Format-Table -AutoSize
$results | Where-Object { $_.Status -ne "MATCH" } | Format-Table Status, File, Path -AutoSize