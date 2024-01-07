# How WAIT works
First, it partitions the disk using `diskpart` (line 72).
It creates one EFI partition, one MSR partition, and one primary partition.

Then, it finds the installation image (usually named `install.wim` or `install.esd`) and deploys it using DISM (line 90).

The registry (specifically `HKEY_LOCAL_MACHINE`) is stored to some files in `C:\Windows\system32\config`.
The script loads the `SYSTEM` key from the newly installed Windows to the registry using `reg` (line 94).

It then modifies the `CmdLine` value in `HKLM\SYSTEM\Setup`. That value sets what will execute after the image deployment. The default is `oobe\windeploy.exe`. The script sets it to a new `bootstrap.bat` script that it will create (line 96).

It creates the `bootstrap.bat` and writes to it commands to create the new user (lines 181-184) and skip OOBE (lines 186-188).
OOBE is skipped by setting three values (`OOBEInProgress`, `SystemSetupInProgress` and `SetupType` inside `HKLM\SYSTEM\Setup`) to 0. This tells Windows to skip OOBE.
Then it creates the `OOBE` key in `HKLM\SOFTWARE\Policies\Microsoft\Windows` and sets `DisablePrivacyExperience` to 1.
This tells Windows to not show the Privacy options screen on sign-in.
It also sets again the `CmdLine` value to point to a new `killwinlogon.bat` script, that -you guessed it- kills `winlogon.exe` (line 196).
This ends the current session and for some reason allows Windows to continue to the sign in process.

The customizations are applied by overwriting the `Shell` value in `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon` to point to `elevate.bat` which gives elevated priviliges to `customize.bat` (line 213) which applies the customizations.
The `Shell` key sets which file is executed on sign-in (default is `explorer.exe`).

It then sets the `Shell` key back to `explorer.exe` and exits.