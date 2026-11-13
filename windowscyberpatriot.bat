@echo off
title CyberPatriot Helper
color 0A
setlocal EnableExtensions EnableDelayedExpansion

net session >nul 2>&1
if errorlevel 1 (
    echo Please run this as Administrator.
    pause
    exit /b
)

set "LOG=%~dp0CyberPatriot_Log.txt"

echo Computer: %COMPUTERNAME%
echo User: %USERNAME%

:MENU
echo [1] Check accounts
echo [2] Password policies
echo [3] Windows Firewall
echo [4] Windows Defender
echo [5] Remote Desktop
echo [6] Network shares
echo [7] Windows services
echo [8] Security auditing
echo [9] Installed software
echo [10] Windows updates
echo [11] Server information
echo [0] Exit
echo.
set /p "choice=Choose an option: "

if "!choice!"=="1" goto USERS
if "!choice!"=="2" goto PASSWORDS
if "!choice!"=="3" goto FIREWALL
if "!choice!"=="4" goto DEFENDER
if "!choice!"=="5" goto RDP
if "!choice!"=="6" goto SHARES
if "!choice!"=="7" goto SERVICES
if "!choice!"=="8" goto AUDIT
if "!choice!"=="9" goto SOFTWARE
if "!choice!"=="10" goto UPDATES
if "!choice!"=="11" goto SERVER
if "!choice!"=="0" goto EXIT

echo Invalid option.
goto MENU

:USERS
cls
echo Account Security

echo.
echo Local users:
net user

echo.
echo Administrators:
net localgroup administrators

echo.
echo Guest account:
net user Guest

echo.
echo Disable Guest account?
call :ASK

if "!answer!"=="Y" (
    net user Guest /active:no
    call :LOG "Guest account change"
)

pause
goto MENU

:PASSWORDS
cls
echo Password Policies

net accounts

echo.
echo Check the README for required:
echo - Password length
echo - Password complexity
echo - Password history
echo - Account lockout

pause
goto MENU

:FIREWALL
cls
echo Firewall

netsh advfirewall show allprofiles

echo.
echo Enable all firewall profiles?
call :ASK

if "!answer!"=="Y" (
    netsh advfirewall set allprofiles state on
    call :LOG "Enabled Windows Firewall"
)

pause
goto MENU

:DEFENDER
cls
echo Defender

powershell -NoProfile -Command "Get-MpComputerStatus | Select-Object AntivirusEnabled,RealTimeProtectionEnabled"

echo.
echo Enable real-time protection?
call :ASK

if "!answer!"=="Y" (
    powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
    call :LOG "Enabled Defender real-time protection"
)

pause
goto MENU

:RDP
cls
echo Remote Desktop

reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections

echo.
echo Disabling RDP may affect server administration.
echo Check the README before making changes.

pause
goto MENU

:SHARES
cls
echo Network Shares

net share

echo.
echo Look for unfamiliar shared folders.
echo Don't remove default administrative shares.

pause
goto MENU

:SERVICES
cls
echo Services

powershell -NoProfile -Command "Get-Service | Format-Table Status,Name,DisplayName -AutoSize"

echo.
echo Look for unfamiliar services.
echo Don't disable anything without checking first.

pause
goto MENU


:AUDIT
cls
echo Security Auditing

auditpol /get /category:*

echo.
echo Enable successful and failed logon auditing?
call :ASK

if "!answer!"=="Y" (
    auditpol /set /subcategory:{0CCE9215-69AE-11D9-BED3-505054503030} /success:enable /failure:enable
    call :LOG "Enabled logon auditing"
)

pause
goto MENU


:SOFTWARE
cls
echo Installed Software

powershell -NoProfile -Command "Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion"

pause
goto MENU


:UPDATES
cls
echo Updates

sc query wuauserv

echo.
echo Recently installed updates:

powershell -NoProfile -Command "Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID,InstalledOn"

pause
goto MENU


:SERVER
cls
echo Server Info

systeminfo | findstr /i "OS Name Domain"

echo.
echo DNS service:
sc query DNS

echo.
echo Active Directory:
sc query NTDS

echo.
echo These services may not be installed.
echo Check which server roles are required.

pause
goto MENU

:ASK
choice /c YN /n /m "Apply this change? [Y/N]: "
set "answer=N"
if errorlevel 2 exit /b
set "answer=Y"
exit /b

:LOG
echo [%date% %time%] %~1>>"%LOG%"
echo Change recorded in log.
exit /b

:EXIT
echo Log: %LOG%
pause
exit /b
