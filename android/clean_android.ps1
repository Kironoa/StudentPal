# Scorched-Earth Android Build Reset Script
# Run this from your Flutter project root directory

$ErrorActionPreference = "SilentlyContinue"

$ProjectRoot = "C:\Personal\Roro\My projects\Flutter App\student_pal"
$AndroidDir = Join-Path $ProjectRoot "android"
$GradleCache = Join-Path $env:USERPROFILE ".gradle\caches"

Write-Host "=== Android Build Environment Reset ===" -ForegroundColor Yellow
Write-Host ""

# 1. Delete android/.gradle
Write-Host "Deleting android/.gradle..." -ForegroundColor Cyan
$AndroidGradle = Join-Path $AndroidDir ".gradle"
if (Test-Path $AndroidGradle) {
    Remove-Item -Path $AndroidGradle -Recurse -Force
    Write-Host "  Removed: $AndroidGradle" -ForegroundColor Green
} else {
    Write-Host "  Already clean: $AndroidGradle" -ForegroundColor Gray
}

# 2. Delete android/build
Write-Host "Deleting android/build..." -ForegroundColor Cyan
$AndroidBuild = Join-Path $AndroidDir "build"
if (Test-Path $AndroidBuild) {
    Remove-Item -Path $AndroidBuild -Recurse -Force
    Write-Host "  Removed: $AndroidBuild" -ForegroundColor Green
} else {
    Write-Host "  Already clean: $AndroidBuild" -ForegroundColor Gray
}

# 3. Delete ~/.gradle/caches
Write-Host "Deleting global Gradle caches..." -ForegroundColor Cyan
if (Test-Path $GradleCache) {
    Remove-Item -Path $GradleCache -Recurse -Force
    Write-Host "  Removed: $GradleCache" -ForegroundColor Green
} else {
    Write-Host "  Not found: $GradleCache" -ForegroundColor Gray
}

# 4. Clean Flutter build cache
Write-Host "Cleaning Flutter build cache..." -ForegroundColor Cyan
$FlutterBuild = Join-Path $ProjectRoot "build"
if (Test-Path $FlutterBuild) {
    Remove-Item -Path $FlutterBuild -Recurse -Force
    Write-Host "  Removed: $FlutterBuild" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Build Environment Reset Complete ===" -ForegroundColor Green
Write-Host "Run 'flutter build apk --debug' to rebuild." -ForegroundColor Yellow