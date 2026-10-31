# Mori Installer

Windows x64 release assets and packaging sources for Mori.

## V0.1

- Platform: Windows x64
- Package: `Mori-Setup-v0.1.0-win-x64.exe`
- Installer type: per-user setup; no administrator prompt is required
- Includes the self-contained Mori desktop app, Node.js runtime, and bundled Mozaik worker
- Creates a Start menu shortcut and a Windows uninstall entry
- Chat history and settings under `%LOCALAPPDATA%\Mori` are preserved when uninstalling
- The Settings page checks the latest release from this repository
- Updates are downloaded from the official release, checked against its SHA-256 sidecar, and installed after Mori closes
- Unsigned: Windows may show an unknown publisher or SmartScreen warning
- macOS and Linux installers are not included

Download the installer from the [V0.1 release](https://github.com/Hive-AI-APP/Mori-Installer/releases/tag/v0.1). The repository and release must be public for the app's unauthenticated update check to work. Verify the installer using its accompanying `.sha256` file.

## Build the Windows installer

Build Mori's self-contained Windows publish output from the Mori source checkout, including `node.exe` and `mozaik-runtime/index.cjs`. The installer version is derived from the published executable. Then run:

```powershell
./build-installer.ps1 -PublishDirectory "C:\path\to\Mori\desktop\publish-tokenrouter" -OutputDirectory "C:\path\to\output"
```

The Windows IExpress build produces `Mori-Setup-v<version>-win-x64.exe` and its SHA-256 sidecar. Exclude PDB debug symbols. Keep provider credentials and private signing keys out of the publish directory.

For a future release, bump the app version in the Mori project, build the desktop app, create a release tag such as `v0.1.1`, and attach both the matching installer and `.sha256` asset to the GitHub release. The app will offer that newer version under Settings → Mori updates.

## Install / uninstall

Run the setup executable and follow its prompts. Mori appears in the Start menu. To remove it, use Windows Installed apps or run the included uninstaller. The uninstall script intentionally leaves user data in `%LOCALAPPDATA%\Mori` intact.
