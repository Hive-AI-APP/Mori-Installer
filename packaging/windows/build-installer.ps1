param(
  [string]$PublishDirectory = (Join-Path $PSScriptRoot '..\..\desktop\publish-tokenrouter'),
  [string]$OutputDirectory,
  [string]$Version
)
$ErrorActionPreference = 'Stop'
$PublishDirectory = [IO.Path]::GetFullPath($PublishDirectory)
$fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $PublishDirectory 'Mori.Desktop.exe')).FileVersion
if (-not $Version) {
  $parts = @($fileVersion.Split('.'))
  if ($parts.Count -lt 3) { throw "Could not read a three-part app version from '$fileVersion'." }
  $Version = ($parts | Select-Object -First 3) -join '.'
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must have the form major.minor.patch; got '$Version'." }
$version = $Version
if (-not $OutputDirectory) { $OutputDirectory = Join-Path (Join-Path $PSScriptRoot '..\..\output\release') "v$version" }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$installerName = "Mori-Setup-v$version-win-x64.exe"
$payloadName = "Mori-$version-win-x64.zip"
$iexpress = Join-Path $env:WINDIR 'System32\iexpress.exe'
if (-not (Test-Path (Join-Path $PublishDirectory 'Mori.Desktop.exe'))) { throw 'Build the self-contained Windows app first.' }
if (-not (Test-Path (Join-Path $PublishDirectory 'node.exe')) -or -not (Test-Path (Join-Path $PublishDirectory 'mozaik-runtime\index.cjs'))) { throw 'The Node runtime or bundled Mozaik worker is missing.' }
if (-not (Test-Path $iexpress)) { throw 'The Windows IExpress packaging tool is unavailable.' }

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$work = Join-Path $OutputDirectory 'iexpress-source'
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $work | Out-Null
$payload = Join-Path $work 'payload'
New-Item -ItemType Directory -Path $payload | Out-Null
Get-ChildItem -LiteralPath $PublishDirectory -Force | Where-Object { $_.Extension -ne '.pdb' } | Copy-Item -Destination $payload -Recurse -Force
if (Test-Path (Join-Path $PSScriptRoot 'NODE-LICENSE.txt')) { Copy-Item (Join-Path $PSScriptRoot 'NODE-LICENSE.txt') $payload }
if (Test-Path (Join-Path $PSScriptRoot 'THIRD-PARTY-NOTICES.txt')) { Copy-Item (Join-Path $PSScriptRoot 'THIRD-PARTY-NOTICES.txt') $payload }
Compress-Archive -Path (Join-Path $payload '*') -DestinationPath (Join-Path $work $payloadName) -CompressionLevel Optimal -Force
Remove-Item -LiteralPath $payload -Recurse -Force
Copy-Item (Join-Path $PSScriptRoot 'install.ps1') $work
Copy-Item (Join-Path $PSScriptRoot 'uninstall.ps1') $work
Copy-Item (Join-Path $PSScriptRoot 'setup.cmd') $work

$target = Join-Path $OutputDirectory $installerName
$null = Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
$null = Remove-Item -LiteralPath (Join-Path $OutputDirectory "~Mori-Setup-v$version-win-x64.CAB") -Force -ErrorAction SilentlyContinue
$sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=1
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=Mori $version is installed. Find Mori in the Start menu.
TargetName=$target
FriendlyName=Mori $version Setup
AppLaunched=setup.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=<None>
UserQuietInstCmd=<None>
SourceFiles=SourceFiles
[Strings]
FILE0="$payloadName"
FILE1="install.ps1"
FILE2="uninstall.ps1"
FILE3="setup.cmd"
[SourceFiles]
SourceFiles0=$work
[SourceFiles0]
%FILE0%=
%FILE1%=
%FILE2%=
%FILE3%=
"@
$sedPath = Join-Path $work 'MoriSetup.sed'
Set-Content -LiteralPath $sedPath -Value $sed -Encoding Default
$null = Start-Process -FilePath $iexpress -ArgumentList @('/N', '/Q', $sedPath) -PassThru
$deadline = [DateTime]::UtcNow.AddMinutes(8)
do {
  Start-Sleep -Seconds 2
  $activePackagers = @(Get-Process -Name 'iexpress','makecab' -ErrorAction SilentlyContinue)
  if ((Test-Path -LiteralPath $target) -and $activePackagers.Count -eq 0) { break }
  if ([DateTime]::UtcNow -gt $deadline) { throw 'IExpress packaging timed out.' }
} while ($true)
if (-not (Test-Path -LiteralPath $target)) { throw "IExpress failed to create $target" }
$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$target.sha256" -Value "$hash  $installerName" -Encoding ascii
Write-Host "Created $target"
Write-Host "SHA-256 $hash"
