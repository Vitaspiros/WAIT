@echo off

set location="Windows"
set advanced=0
set debug=0
set deploy=1

rem Parse arguments
:parse
if "%~1"=="" goto endparse
if "%~1"=="/help" goto printhelp
if "%~1"=="/?" goto printhelp
if "%~1"=="/advanced" (
	set advanced=1
)
if "%~1"=="/nodeploy" (
	set deploy=0
)
if "%~1"=="/debug" (
	echo on
	set debug=1
)
shift
goto parse

:printhelp
echo Windows Automated Install Tool (WAIT)
echo This tool automates the Windows Install for you.
echo.
echo    /help        -     Prints this help dialog
echo    / ?          -     Alias for /help
echo    /advanced    -     Enables advanced options
echo    /nodeploy    -     Does not do the deployment
echo    /debug       -     Enables debug mode
echo.
goto end

:endparse

echo Windows Automated Install Tool (WAIT)
echo Make sure this device supports UEFI!
echo.

if %advanced%==1 (
	echo The custom install location has not been tested and it is guaranteed that it will not result in a working system right away.
	echo Do not use it unless you know what you are doing.
	set /p "location=How do you want the root folder to be called (Windows) "
	if "%location%"=="" set "location=Windows"
)
set /p "name=What do you want your username to be? (Nick) "
if "%name%"=="" set "name=Nick"

if %debug%==0 cls

set /p "password=What do you want your password to be? (Empty for no password) "

if %debug%==0 cls

echo list disk | diskpart
echo.
echo.
set /p "disk=Choose which of the above is the disk you want to install Windows to (Type number, e.g 0) "

if %debug%==0 cls
echo Partitioning disks...

rem Setup Disks
cd /d X:
echo sel disk %disk% >> diskpart.txt
echo clean >> diskpart.txt
echo convert gpt >> diskpart.txt
echo create part efi size=300 >> diskpart.txt
echo format fs=fat32 quick >> diskpart.txt
echo assign letter W >> diskpart.txt
echo create part msr size=500 >> diskpart.txt
echo create part primary >> diskpart.txt
echo format fs=ntfs quick >> diskpart.txt
echo assign letter C >> diskpart.txt

if %deploy%==1 diskpart /s diskpart.txt>nul
del diskpart.txt

if %debug%==0 cls

cd /d D:\sources

if exist install.wim (
	set "imagefile=install.wim"
)
if exist install.esd (
	set "imagefile=install.esd"
)

dism /get-imageinfo /imagefile:%imagefile%
echo.
echo.
set /p "index=Choose your preferred Windows edition (index, e.g 2): "
if "%index%"=="" set index=1

if %debug%==0 cls
echo Installing Windows...
echo.
echo.
echo.


if %deploy%==1 dism /apply-image /index:%index% /imagefile:%imagefile% /applydir:C:

if %debug%==0 cls
echo Configuring...
reg load HKLM\SYS C:\Windows\system32\config\SYSTEM>nul

reg add HKLM\SYS\Setup /v CmdLine /t REG_SZ /d "C:\Windows\system32\cmd.exe /c C:\bootstrap.bat" /f>nul

if %location%=="Windows" (
	bcdboot C:\Windows /s W:
	goto customizations
)

reg load HKLM\SOFT C:\Windows\system32\config\SOFTWARE>nul

reg export HKLM\SYS C:\sys.reg
reg export HKLM\SOFT C:\soft.reg

rem Replaces every occurence of C:\Windows with the custom directory
C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe -Command "(gc C:\sys.reg) -replace 'C:\\Windows', 'C:\\%location%' | Out-File -encoding ASCII C:\sys.reg"
C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe -Command "(gc C:\soft.reg) -replace 'C:\\Windows', 'C:\\%location%' | Out-File -encoding ASCII C:\soft.reg"

reg import C:\sys.reg
@rem reg import C:\soft.reg

del C:\sys.reg
@rem del C:\soft.reg

rem Enables the sethc.exe bug - You are going to need it
copy C:\Windows\system32\cmd.exe C:\Windows\system32\sethc.exe /y

rename C:\Windows C:\%location%

rem Generate boot files
bcdboot C:\%location% /s W:



rem Customizations
:customizations
if %debug%==0 cls
set /p "iscustomize=Do you want to proceed to further customizations to your install? (Y/n) "
if "%iscustomize%"=="" set "iscustomize=Y"

if "%iscustomize%"=="n" goto bootstrap
if "%iscustomize%"=="N" goto bootstrap

if %debug%==0 cls
set /p "removeedge=Do you want to remove Microsoft Edge and install some other browser? (Y/n) "
if "%removeedge%"=="" set "removeedge=Y"

if "%removeedge%"=="n" goto activation
if "%removeedge%"=="N" goto activation

rem Select the browser

if %debug%==0 cls
echo Which browser do you want to install? (Default: Firefox)
echo     0. None
echo     1. Firefox (Latest)
echo     2. Ungoogled Chromium (v120.0.6099.200 - Probably outdated)

set /p "browser=Type the number (e.g 1) "
if "%browser%"=="" set browser=1

:activation
if %debug%==0 cls
set /p "activation=Do you want to activate Windows after install (Y/n) "
if "%activation%"=="" set "activation=Y"


:sethcbug
if %debug%==0 cls
set /p "sethc=Do you want to enable the sethc.exe bug? (Y/n) "
if "%sethc%"=="" set "sethc=Y"

if "%sethc%"=="n" goto verbosestatus
if "%sethc%"=="N" goto verbosestatus

copy C:\Windows\system32\cmd.exe C:\Windows\system32\sethc.exe /y

:verbosestatus
if %debug%==0 cls
set /p "verbosestatus=Do you want to enable VerboseStatus (Verbose startup messages) (Y/n) "
if "%verbosestatus%"=="" set "verbosestatus=Y"

:bootstrap
cd /d C:
if %debug%==0 echo @echo off >> bootstrap.bat
echo oobe\windeploy >> bootstrap.bat
echo timeout 5 ^> nul >> bootstrap.bat
if not "%password%"=="" echo net user "%name%" "%password%" >> bootstrap.bat
if "%password%"=="" echo net user /add "%name%" >> bootstrap.bat
echo net localgroup /add Users "%name%" >> bootstrap.bat
echo net localgroup /add Administrators "%name%" >> bootstrap.bat
echo reg add HKLM\SYSTEM\Setup /v CmdLine /t REG_SZ /d "C:\Windows\system32\cmd.exe /k C:\killwinlogon.bat" /f >> bootstrap.bat
echo reg add HKLM\SYSTEM\Setup /v OOBEInProgress /t REG_DWORD /d 0 /f >> bootstrap.bat
echo reg add HKLM\SYSTEM\Setup /v SystemSetupInProgress /t REG_DWORD /d 0 /f >> bootstrap.bat
echo reg add HKLM\SYSTEM\Setup /v SetupType /t REG_DWORD /d 0 /f >> bootstrap.bat
rem Disable the privacy screen on sign-in
echo reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 >> bootstrap.bat
echo timeout 5 ^> nul >> bootstrap.bat
echo shutdown -r -t 0 >> bootstrap.bat

echo @echo off >> killwinlogon.bat
echo timeout 3 ^> null >> killwinlogon.bat
echo wmic process where name="winlogon.exe" call terminate >> killwinlogon.bat
echo del killwinlogon.bat >> killwinlogon.bat

if "%iscustomize%"=="y" goto enablecustomization
if "%iscustomize%"=="Y" goto enablecustomization

if %debug%==0 echo del C:\bootstrap.bat >> bootstrap.bat

if %debug%==0 wpeutil reboot


:enablecustomization
echo reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "C:\Windows\system32\cmd.exe /c C:\elevate.bat" /f >> bootstrap.bat
echo del C:\bootstrap.bat >> bootstrap.bat

rem Create elevate.bat which launches customize.bat with elevated privileges
echo @echo off >> elevate.bat
echo powershell -Command "start \"cmd\" \"/k C:\\customize.bat\" -Verb runAs" >> elevate.bat

rem Create customize.bat
if %debug%==0 echo @echo off >> customize.bat
echo cd "C:\Users\%name%\Desktop" >> customize.bat

:checkcustomizations
if "%removeedge%"=="y" goto removeedge
if "%removeedge%"=="Y" goto removeedge

if "%activation%"=="y" goto enableactivation
if "%activation%"=="Y" goto enableactivation

if "%verbosestatus%"=="y" goto enableverbosestatus
if "%verbosestatus%"=="Y" goto enableverbosestatus

if not %browser%==0 goto installbrowser

:finalizecustomizations
echo reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "explorer.exe" /f >> customize.bat
echo start explorer.exe >> customize.bat
if %debug%==0 echo exit >> customize.bat 
if %debug%==0 wpeutil reboot
goto end


:removeedge
echo curl https://raw.githubusercontent.com/ShadowWhisperer/Remove-MS-Edge/main/Remove-Edge.exe --output RemoveEdge.exe >> customize.bat
echo RemoveEdge /s >> customize.bat
echo del RemoveEdge.exe >> customize.bat

set "removeedge=N"

goto checkcustomizations

:enableactivation
echo powershell -Command "irm https://massgrave.dev/get | iex" >> customize.bat

set "activation=N"
goto checkcustomizations

:enableverbosestatus
echo reg add HKLM\SOFTWARE\Microsoft\Windows\Policies\System /v VerboseStatus /t REG_DWORD /d 1 >> customize.bat

set "verbosestatus=N"
goto checkcustomizations

:installbrowser
if %browser%==1 (
	echo curl -L "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" --output FirefoxSetup.exe >> customize.bat
	echo FirefoxSetup.exe >> customize.bat
	echo del FirefoxSetup.exe >> customize.bat
)

if %browser%==2 (
	echo curl -L "https://github.com/macchrome/winchrome/releases/download/v120.6099.200-M120.0.6099.200-r1217362-Win64/120.0.6099.200_ungoogled_mini_installer.exe" --output ChromiumSetup.exe >> customize.bat
	echo ChromiumSetup.exe >> customize.bat
	echo del ChromiumSetup.exe >> customize.bat
)

set browser=0
goto checkcustomizations

:end