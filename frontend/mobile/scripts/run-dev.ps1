# Loads .env.local from the project root and runs `flutter run` with one
# --dart-define flag per KEY=VALUE pair. Forwards any extra args to flutter.
#
# Usage:
#   ./scripts/run-dev.ps1
#   ./scripts/run-dev.ps1 -d emulator-5554
#   ./scripts/run-dev.ps1 --release

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envFile = Join-Path $projectRoot ".env.local"

if (!(Test-Path $envFile)) {
    Write-Host "Missing $envFile" -ForegroundColor Red
    Write-Host "Copy .env.local.example to .env.local and fill in your TMDB + Last.fm keys."
    exit 1
}

$dartDefines = @()
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    if ($line -match "^([^=]+)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        if ($value -ne "") {
            $dartDefines += "--dart-define=$name=$value"
        }
    }
}

Write-Host "Running with $($dartDefines.Count) --dart-define values from .env.local" -ForegroundColor Cyan

Push-Location $projectRoot
try {
    & flutter run @dartDefines @args
} finally {
    Pop-Location
}
