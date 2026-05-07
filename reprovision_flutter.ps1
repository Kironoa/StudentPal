# Flutter SDK Re-provisioning Script for JDK 17 Compatibility
# Run this script to ensure no local SDK files are modified or corrupted

$ErrorActionPreference = "Stop"

Write-Host "Starting Flutter SDK re-provisioning..." -ForegroundColor Cyan

# Step 1: Run flutter upgrade --force to refresh SDK
Write-Host "Running flutter upgrade --force..." -ForegroundColor Yellow
flutter upgrade --force

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: flutter upgrade --force failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Flutter upgrade completed successfully." -ForegroundColor Green