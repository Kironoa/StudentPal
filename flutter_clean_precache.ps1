# Clean Flutter artifacts and re-download pre-compiled binaries
# This ensures clean, JDK 17 compatible binaries

$ErrorActionPreference = "Stop"

$FlutterPath = "C:\flutter"

# Step 1: Delete artifacts cache
$ArtifactsPath = Join-Path $FlutterPath "bin\cache\artifacts"
if (Test-Path $ArtifactsPath) {
    Write-Host "Deleting $ArtifactsPath..." -ForegroundColor Yellow
    Remove-Item -Path $ArtifactsPath -Recurse -Force
    Write-Host "Artifacts deleted successfully." -ForegroundColor Green
} else {
    Write-Host "Artifacts folder not found, skipping deletion." -ForegroundColor Yellow
}

# Step 2: Run flutter precache to download clean binaries
Write-Host "Running flutter precache..." -ForegroundColor Yellow
flutter precache

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter precache failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Flutter precache completed successfully." -ForegroundColor Green