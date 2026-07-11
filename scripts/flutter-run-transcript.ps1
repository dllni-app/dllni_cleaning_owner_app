param(
    [Parameter(Mandatory)]
    [string]$DeviceId,

    [Parameter(Mandatory)]
    [string]$LogFile,

    [string]$Label = "device"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

Set-Location $ProjectRoot
$logDir = Split-Path -Parent $LogFile
if ($logDir) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

$Host.UI.RawUI.WindowTitle = "Flutter ($Label) - $DeviceId"
Write-Host "Project : $ProjectRoot" -ForegroundColor DarkGray
Write-Host "Device  : $DeviceId" -ForegroundColor Cyan
Write-Host "Log file: $LogFile" -ForegroundColor Cyan
Write-Host ""

Start-Transcript -Path $LogFile -Append
try {
    flutter run -d $DeviceId
}
finally {
    Stop-Transcript
    Write-Host ""
    Write-Host "Transcript saved: $LogFile" -ForegroundColor Green
}
