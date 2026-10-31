param(
  [string]$InstallRoot = (Split-Path -Parent $PSCommandPath),
  [switch]$SkipRegistry,
  [switch]$SkipShortcuts
)
$ErrorActionPreference = 'Stop'
$installRoot = [IO.Path]::GetFullPath($InstallRoot)
if (Get-Process -Name 'Mori.Desktop' -ErrorAction SilentlyContinue) {
  Write-Error 'Close Mori before uninstalling it, then run Uninstall Mori again.'
  exit 1
}
if (-not $SkipRegistry) {
  $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Mori'
  Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not $SkipShortcuts) {
  $menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Mori'
  Remove-Item -LiteralPath $menu -Recurse -Force -ErrorAction SilentlyContinue
}
Set-Location $env:TEMP
Remove-Item -LiteralPath $installRoot -Recurse -Force
Write-Host 'Mori was removed. Your account session, settings, and chats in LocalAppData were kept.'
