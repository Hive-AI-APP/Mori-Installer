param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'Programs\Mori'),
  [switch]$SkipRegistry,
  [switch]$SkipShortcuts,
  [switch]$SkipLaunch
)
$ErrorActionPreference = 'Stop'
$package = Join-Path $PSScriptRoot 'Mori-0.1.0-win-x64.zip'
if (-not (Test-Path -LiteralPath $package)) { throw 'The Mori V0.1 package is missing.' }
if (Get-Process -Name 'Mori.Desktop' -ErrorAction SilentlyContinue) {
  throw 'Close Mori before installing or updating it, then run this installer again.'
}

$resolved = [IO.Path]::GetFullPath($InstallRoot)
$parent = Split-Path -Parent $resolved
New-Item -ItemType Directory -Force -Path $parent | Out-Null
$staging = Join-Path $env:TEMP ('Mori-Install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging | Out-Null
try {
  Expand-Archive -LiteralPath $package -DestinationPath $staging -Force
  $app = Join-Path $staging 'Mori.Desktop.exe'
  $node = Join-Path $staging 'node.exe'
  $worker = Join-Path $staging 'mozaik-runtime\index.cjs'
  if (-not (Test-Path $app) -or -not (Test-Path $node) -or -not (Test-Path $worker)) {
    throw 'The package failed its required-file check and was not installed.'
  }

  New-Item -ItemType Directory -Force -Path $resolved | Out-Null
  Copy-Item -Path (Join-Path $staging '*') -Destination $resolved -Recurse -Force
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'uninstall.ps1') -Destination (Join-Path $resolved 'uninstall.ps1') -Force

  if (-not $SkipShortcuts) {
    $menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Mori'
    New-Item -ItemType Directory -Force -Path $menu | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Join-Path $menu 'Mori.lnk'))
    $shortcut.TargetPath = Join-Path $resolved 'Mori.Desktop.exe'
    $shortcut.WorkingDirectory = $resolved
    $shortcut.IconLocation = (Join-Path $resolved 'Mori.Desktop.exe') + ',0'
    $shortcut.Description = 'Start Mori, your pixel-cat desktop companion.'
    $shortcut.Save()
  }

  if (-not $SkipRegistry) {
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Mori'
    New-Item -Path $key -Force | Out-Null
    $uninstaller = Join-Path $resolved 'uninstall.ps1'
    Set-ItemProperty $key DisplayName 'Mori'
    Set-ItemProperty $key DisplayVersion '0.1.0'
    Set-ItemProperty $key Publisher 'Mori'
    Set-ItemProperty $key InstallLocation $resolved
    Set-ItemProperty $key UninstallString ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $uninstaller + '"')
    Set-ItemProperty $key NoModify 1 -Type DWord
    Set-ItemProperty $key NoRepair 1 -Type DWord
  }

  Write-Host 'Mori V0.1 is installed. Find Mori in the Start menu.'
  if (-not $SkipLaunch) { Start-Process -FilePath (Join-Path $resolved 'Mori.Desktop.exe') -WorkingDirectory $resolved }
}
finally {
  Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}
