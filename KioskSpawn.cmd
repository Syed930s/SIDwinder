@echo off
setlocal enabledelayedexpansion

set /p "KIOSK_USER=Enter kiosk username: "

set "PSEXEC=%WINDIR%\System32\psexec.exe"
set "TEMPZIP=%TEMP%\PSTools.zip"
set "TEMPDIR=%TEMP%\PSTools"

if not exist "%PSEXEC%" (
    echo psexec.exe not found in System32, downloading PSTools...

    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/PSTools.zip' -OutFile '%TEMPZIP%'"
    if errorlevel 1 (
        echo Download failed.
        exit /b 1
    )

    powershell -NoProfile -Command "Expand-Archive -Path '%TEMPZIP%' -DestinationPath '%TEMPDIR%' -Force"
    if errorlevel 1 (
        echo Extraction failed.
        exit /b 1
    )

    if not exist "%TEMPDIR%\PsExec.exe" (
        echo psexec.exe not found in extracted archive.
        exit /b 1
    )

    copy /y "%TEMPDIR%\PsExec.exe" "%PSEXEC%" >nul
    if errorlevel 1 (
        echo Copy to System32 failed - run as admin.
        exit /b 1
    )

    del /q "%TEMPZIP%" >nul 2>&1
    rd /s /q "%TEMPDIR%" >nul 2>&1

    echo psexec.exe installed to System32.
)

schtasks /create /tn "KioskAdminCmd" /tr "cmd.exe /k \"%PSEXEC%\" -accepteula -nobanner -si cmd.exe" /sc onlogon /ru "%KIOSK_USER%" /rl highest /f@echo off
setlocal

set /p "KIOSK_USER=Enter kiosk username: "

schtasks /create /tn "KioskAdminCmd" /tr "cmd.exe /k psexec.exe -si cmd.exe" /sc onlogon /ru "%KIOSK_USER%" /rl highest /f
