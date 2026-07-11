<#
.SYNOPSIS
  Run the app on a physical phone and an emulator with Start-Transcript logging.

.USAGE
  .\scripts\run-dual-debug.ps1
  .\scripts\run-dual-debug.ps1 -EmulatorName flutter_emulator
  .\scripts\run-dual-debug.ps1 -SkipEmulatorLaunch
  .\scripts\run-dual-debug.ps1 -PhoneDeviceId 17f882ee -EmulatorDeviceId emulator-5554

  Logs are written to logs\<timestamp>\phone_console.log and emulator_console.log
#>
param(
    [string]$PhoneDeviceId,
    [string]$EmulatorDeviceId,
    [string]$EmulatorName = "Pixel_7_Pro",
    [switch]$SkipEmulatorLaunch
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$TranscriptScript = Join-Path $PSScriptRoot "flutter-run-transcript.ps1"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogsDir = Join-Path $ProjectRoot "logs\$Timestamp"

function Get-FlutterDevices {
    $json = flutter devices --machine 2>$null
    if (-not $json) {
        return @()
    }
    return @($json | ConvertFrom-Json)
}

function Wait-ForEmulator {
    param(
        [int]$TimeoutSeconds = 300
    )

    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $emulator = Get-FlutterDevices | Where-Object {
            $_.emulator -eq $true -and $_.isSupported -eq $true
        } | Select-Object -First 1

        if ($emulator) {
            return $emulator.id
        }

        $adbEmulators = @(adb devices 2>$null |
            Select-Object -Skip 1 |
            Where-Object { $_ -match "emulator-\d+\s+device" })

        if ($adbEmulators.Count -gt 0) {
            $adbId = ($adbEmulators[0] -split "\s+")[0]
            $flutterMatch = Get-FlutterDevices | Where-Object { $_.id -eq $adbId } | Select-Object -First 1
            if ($flutterMatch) {
                return $flutterMatch.id
            }
            return $adbId
        }

        $adbState = adb devices 2>$null |
            Select-Object -Skip 1 |
            Where-Object { $_ -match "emulator-" } |
            Select-Object -First 1

        $stateHint = if ($adbState) { " ($($adbState.Trim()))" } else { "" }
        Write-Host "Waiting for emulator... ($elapsed s)$stateHint" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        $elapsed += 5
    }

    throw "Timed out waiting for an emulator to appear."
}

function Start-FlutterTranscriptWindow {
    param(
        [string]$DeviceId,
        [string]$LogFile,
        [string]$Label
    )

    $arguments = @(
        "-NoExit",
        "-ExecutionPolicy", "Bypass",
        "-File", $TranscriptScript,
        "-DeviceId", $DeviceId,
        "-LogFile", $LogFile,
        "-Label", $Label
    )

    Start-Process powershell -ArgumentList $arguments | Out-Null
}

Set-Location $ProjectRoot
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

$devices = Get-FlutterDevices
$androidDevices = $devices | Where-Object {
    $_.targetPlatform -like "android-*"
}

if (-not $PhoneDeviceId) {
    $phone = $androidDevices | Where-Object { $_.emulator -eq $false } | Select-Object -First 1
    if ($phone) {
        $PhoneDeviceId = $phone.id
    }
}

if (-not $EmulatorDeviceId) {
    $emulator = $androidDevices | Where-Object { $_.emulator -eq $true } | Select-Object -First 1
    if ($emulator) {
        $EmulatorDeviceId = $emulator.id
    }
}

if (-not $PhoneDeviceId) {
    throw "No physical Android device found. Connect a phone with USB debugging enabled, or pass -PhoneDeviceId."
}

if (-not $EmulatorDeviceId) {
    if ($SkipEmulatorLaunch) {
        throw "No emulator found. Start one manually or omit -SkipEmulatorLaunch."
    }

    Write-Host "No emulator running. Launching '$EmulatorName'..." -ForegroundColor Yellow
    flutter emulators --launch $EmulatorName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to launch emulator '$EmulatorName'. Run 'flutter emulators' to list available emulators."
    }
    $EmulatorDeviceId = Wait-ForEmulator
}

$phoneLog = Join-Path $LogsDir "phone_console.log"
$emulatorLog = Join-Path $LogsDir "emulator_console.log"

Write-Host ""
Write-Host "Starting dual debug sessions (Start-Transcript)" -ForegroundColor Green
Write-Host "  Phone    : $PhoneDeviceId"
Write-Host "  Emulator : $EmulatorDeviceId"
Write-Host "  Logs dir : $LogsDir"
Write-Host ""

Start-FlutterTranscriptWindow -DeviceId $PhoneDeviceId -LogFile $phoneLog -Label "phone"
Start-Sleep -Seconds 2
Start-FlutterTranscriptWindow -DeviceId $EmulatorDeviceId -LogFile $emulatorLog -Label "emulator"

Write-Host "Opened two PowerShell windows." -ForegroundColor Green
Write-Host "  Phone log    : $phoneLog"
Write-Host "  Emulator log : $emulatorLog"
Write-Host ""
Write-Host "Close each window or stop flutter run to finish the transcript."
