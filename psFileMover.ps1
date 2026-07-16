# Ask user for root folder
$rootPath = Read-Host "Enter the full path to the root folder"

# Validate path
if (!(Test-Path $rootPath)) {
    Write-Host "Invalid path. Exiting." -ForegroundColor Red
    exit
}

# Get all files from subfolders (excluding files already in root)
$files = Get-ChildItem -Path $rootPath -Recurse -File -Force | Where-Object {
    $_.DirectoryName -ne $rootPath
}

foreach ($file in $files) {
    $destination = Join-Path $rootPath $file.Name

    # Handle duplicate file names
    $counter = 1
    while (Test-Path $destination) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $ext = $file.Extension
        $destination = Join-Path $rootPath "$name`_$counter$ext"
        $counter++
    }

    Move-Item -Path $file.FullName -Destination $destination
}

# Delete empty folders (bottom-up to avoid issues)
Get-ChildItem -Path $rootPath -Recurse -Directory |
    Sort-Object FullName -Descending |
    Where-Object { (Get-ChildItem -Path $_.FullName -Force | Measure-Object).Count -eq 0 } |
    Remove-Item -Force

Write-Host "All files copied to root folder."