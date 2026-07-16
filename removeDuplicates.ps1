# Ask user for root folder
$rootFolder = Read-Host "Enter the root folder path"

# Validate path
if (!(Test-Path $rootFolder)) {
    Write-Host "Invalid path!" -ForegroundColor Red
    exit
}

Write-Host "Scanning files and calculating hashes... this may take a while." -ForegroundColor Yellow

# Get all files recursively
$files = Get-ChildItem -Path $rootFolder -Recurse -File

# Create list with hashes
$fileHashes = foreach ($file in $files) {
    try {
        $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
        [PSCustomObject]@{
            Path = $file.FullName
            Name = $file.Name
            Length = $file.Name.Length
            Hash = $hash.Hash
        }
    }
    catch {
        Write-Host "Failed to hash: $($file.FullName)" -ForegroundColor Red
    }
}

# Group by hash
$groups = $fileHashes | Group-Object -Property Hash

$deletedCount = 0

foreach ($group in $groups) {
    if ($group.Count -gt 1) {
        Write-Host "`nDuplicate group found:" -ForegroundColor Cyan

        # Sort by filename length descending (keep longest)
        $sorted = $group.Group | Sort-Object Length -Descending

        $fileToKeep = $sorted[0]
        Write-Host "Keeping: $($fileToKeep.Path)" -ForegroundColor Green

        $duplicatesToRemove = $sorted | Select-Object -Skip 1

        foreach ($dup in $duplicatesToRemove) {
            try {
                Write-Host "Deleting: $($dup.Path)" -ForegroundColor Red
                Remove-Item -Path $dup.Path -Force
                $deletedCount++
            }
            catch {
                Write-Host "Failed to delete: $($dup.Path)" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`nDone. Deleted $deletedCount duplicate files." -ForegroundColor Green