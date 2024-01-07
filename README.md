# Windows Automated Install Tool (WAIT)

[If for some reason you use Windows 10](https://linuxmint.com/) this tool is here to install it faster!

It completely skips OOBE and Privacy Experience screen, while allowing you to customize your install.

Tested on:
- Tiny10 x64 21H2 Virtual Machine (VirtualBox with UEFI)

# Notes
1. It works only on devices supporting UEFI.
2. If you choose to enable customizations, the install will not be completely automated (you will have to press 'Yes' to a UAC prompt).

# Running
1. Put `WAIT.bat` to your Windows Installation USB.
2. Boot from the USB.
3. Tap Shift+F10, so a command prompt window opens.
4. Type `D:\WAIT.bat` or the location of the file if you put it somewhere else and press Enter.
5. Answer the questions and install Windows!

# Customizations
This tool allows you to customize your install.

These customizations include:
- Removing Microsoft Edge
- Downloading and running MAS to activate Windows
- Installing a web browser (Firefox or Ungoogled Chromium)
- Enabling the sethc bug (Pressing Shift 5 times opens cmd)
- Enabling verbose startup messages

# How it works
See [EXPLANATION.md](EXPLANATION.md) for details.

# Bugs and Feature Requests
Create a new issue to the Issues tab.

# Thanks to
- [Enderman](https://go.enderman.ch/youtube) for teaching me all these amazing registry tricks with his videos
- [ShadowWhisperer](https://github.com/ShadowWhisperer) for creating [Remove-MS-Edge](https://github.com/ShadowWhisperer/Remove-MS-Edge) which is used for the edge removal.
- [massgravel](https://github.com/massgravel) for creating [Microsoft Activation Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts) which is used for the Windows Activation.
- [Firefox](https://www.mozilla.org/en-US/firefox/) because it is such an amazing browser!