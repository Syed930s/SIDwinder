@echo off
setlocal

set /p "KIOSK_USER=Enter kiosk username: "

schtasks /create /tn "KioskAdminCmd" /tr "cmd.exe /k psexec.exe -si cmd.exe" /sc onlogon /ru "%KIOSK_USER%" /rl highest /f
