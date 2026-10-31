# Mori Installer

Windows release assets and packaging sources for Mori.

## V0.1

- Platform: Windows x64
- Package: `Mori-Setup-v0.1.0-win-x64.exe`
- Installer type: per-user setup; no administrator prompt is required
- Includes the self-contained Mori desktop app, Node.js runtime, and bundled Mozaik worker
- Creates a Start menu shortcut and an uninstall entry
- Chat history and settings under `%LOCALAPPDATA%\Mori` are preserved when uninstalling
- Updates are manual in V0.1; this release does not include an automatic updater
- Unsigned: Windows may show an unknown publisher or SmartScreen warning
- macOS and Linux installers are not included

Download the installer from the [V0.1 release](https://github.com/Hive-AI-APP/Mori-Installer/releases/tag/v0.1). Verify it with the accompanying SHA-256 file before running it.

## Build the Windows installer

Build Mori's self-contained Windows publish output from the Mori source checkout, including `node.exe` and `mozaik-runtime/index.cjs`. Then run:

```powershell
./build-installer.ps1 -PublishDirectory "C:\path\to\Mori\desktop\publish-tokenrouter" -OutputDirectory "C:\path\to\output"
```

The build script uses Windows IExpress and creates the setup executable plus a SHA-256 sidecar. It excludes PDB debug symbols. Keep provider credentials and private signing keys out of the publish directory.

## Install / uninstall

Run the setup executable and follow its prompts. Mori appears in the Start menu. To remove it, use Windows Installed apps or run the included uninstaller. The uninstall script intentionally leaves user data in `%LOCALAPPDATA%\Mori` intact.

The installer is an initial V0.1 distribution. It is not code-signed, and its update process is manual.
