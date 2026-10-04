@echo off
setlocal enabledelayedexpansion

:: ---- require admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This must be run as Administrator.
    pause
    exit /b 1
)

set PLKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
set COUNT=0

echo.
echo Scanning user profiles...
echo.

for /f "tokens=*" %%K in ('reg query "%PLKEY%" 2^>nul ^| findstr /i "S-1-5-21-"') do (
    set "SUBKEY=%%K"
    for %%A in ("!SUBKEY!") do set "SID=%%~nxA"

    rem pull ProfileImagePath for this SID
    set "IMGPATH="
    for /f "tokens=2,*" %%B in ('reg query "%PLKEY%\!SID!" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do set "IMGPATH=%%C"

    if defined IMGPATH (
        for %%N in ("!IMGPATH!") do set "UNAME=%%~nxN"

        rem check if hive is currently loaded
        reg query "HKU\!SID!" >nul 2>&1
        if !errorlevel! equ 0 (set "LOADED=loaded") else (set "LOADED=not loaded")

        set /a COUNT+=1
        set "SID_!COUNT!=!SID!"
        set "NAME_!COUNT!=!UNAME!"
        set "PATH_!COUNT!=!IMGPATH!"
        set "LOAD_!COUNT!=!LOADED!"

        echo !COUNT!^) !UNAME!   [!LOADED!]
        echo    !SID!
        echo.
    )
)

if %COUNT%==0 (
    echo No user profiles found.
    pause
    exit /b 1
)

:selectuser
set /p USEL=Select a user number: 
echo !USEL!| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 goto selectuser
if %USEL% gtr %COUNT% goto selectuser

set "SEL_SID=!SID_%USEL%!"
set "SEL_NAME=!NAME_%USEL%!"
set "SEL_PATH=!PATH_%USEL%!"
set "SEL_LOAD=!LOAD_%USEL%!"

echo.
echo Selected: !SEL_NAME!  (!SEL_SID!)

set "WELOADED=0"
if "!SEL_LOAD!"=="not loaded" (
    echo.
    set /p LOADIT=Hive not loaded. Load it now? [y/n]: 
    if /i "!LOADIT!"=="y" (
        reg load "HKU\!SEL_SID!" "!SEL_PATH!\NTUSER.DAT"
        if errorlevel 1 (
            echo Failed to load hive - it may be in use.
            pause
            exit /b 1
        )
        set "WELOADED=1"
    )
)

:menu
echo.
echo Registry paths for !SEL_NAME!:
echo   1^) HKU\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon     (per-user Shell)
echo   2^) HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon               (machine-wide Shell)
echo   3^) HKU\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System  (policy Shell override)
echo   4^) Quit
echo.
set /p PSEL=Select a path to open in regedit: 

if "!PSEL!"=="1" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="2" set "TARGET=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="3" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if "!PSEL!"=="4" goto cleanup

if not defined TARGET (
    echo Invalid choice.
    set "TARGET="
    goto menu
)

rem print current Shell value if present
set "SHORTPATH=!TARGET:HKEY_LOCAL_MACHINE=HKLM:!"
set "SHORTPATH=!SHORTPATH:HKEY_USERS=HKU:!"
echo.
reg query "!SHORTPATH!" /v Shell 2>nul
if errorlevel 1 echo   Shell = ^<not set^>

rem point regedit at this key, close any open regedit, relaunch
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /v LastKey /t REG_SZ /d "Computer\!TARGET!" /f >nul
taskkill /f /im regedit.exe >nul 2>&1
start regedit

set "TARGET="
echo.
echo regedit opened at that key.
goto menu

:cleanup
if "!WELOADED!"=="1" (
    echo.
    echo Close regedit before unloading, then press any key.
    pause >nul
    reg unload "HKU\!SEL_SID!" >nul 2>&1
    if errorlevel 1 (
        echo Unload failed - regedit is probably still holding the hive open. Close it and run:
        echo   reg unload HKU\!SEL_SID!
    ) else (
        echo Hive unloaded.
    )
)

pause
exit /b 0@echo off
setlocal enabledelayedexpansion

:: ---- require admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This must be run as Administrator.
    pause
    exit /b 1
)

set PLKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
set COUNT=0

echo.
echo Scanning user profiles...
echo.

for /f "tokens=*" %%K in ('reg query "%PLKEY%" 2^>nul ^| findstr /i "S-1-5-21-"') do (
    set "SUBKEY=%%K"
    for %%A in ("!SUBKEY!") do set "SID=%%~nxA"

    rem pull ProfileImagePath for this SID
    set "IMGPATH="
    for /f "tokens=2,*" %%B in ('reg query "%PLKEY%\!SID!" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do set "IMGPATH=%%C"

    if defined IMGPATH (
        for %%N in ("!IMGPATH!") do set "UNAME=%%~nxN"

        rem check if hive is currently loaded
        reg query "HKU\!SID!" >nul 2>&1
        if !errorlevel! equ 0 (set "LOADED=loaded") else (set "LOADED=not loaded")

        set /a COUNT+=1
        set "SID_!COUNT!=!SID!"
        set "NAME_!COUNT!=!UNAME!"
        set "PATH_!COUNT!=!IMGPATH!"
        set "LOAD_!COUNT!=!LOADED!"

        echo !COUNT!^) !UNAME!   [!LOADED!]
        echo    !SID!
        echo.
    )
)

if %COUNT%==0 (
    echo No user profiles found.
    pause
    exit /b 1
)

:selectuser
set /p USEL=Select a user number: 
echo !USEL!| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 goto selectuser
if %USEL% gtr %COUNT% goto selectuser

set "SEL_SID=!SID_%USEL%!"
set "SEL_NAME=!NAME_%USEL%!"
set "SEL_PATH=!PATH_%USEL%!"
set "SEL_LOAD=!LOAD_%USEL%!"

echo.
echo Selected: !SEL_NAME!  (!SEL_SID!)

set "WELOADED=0"
if "!SEL_LOAD!"=="not loaded" (
    echo.
    set /p LOADIT=Hive not loaded. Load it now? [y/n]: 
    if /i "!LOADIT!"=="y" (
        reg load "HKU\!SEL_SID!" "!SEL_PATH!\NTUSER.DAT"
        if errorlevel 1 (
            echo Failed to load hive - it may be in use.
            pause
            exit /b 1
        )
        set "WELOADED=1"
    )
)

:menu
echo.
echo Registry paths for !SEL_NAME!:
echo   1^) HKU\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon     (per-user Shell)
echo   2^) HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon               (machine-wide Shell)
echo   3^) HKU\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System  (policy Shell override)
echo   4^) Quit
echo.
set /p PSEL=Select a path to open in regedit: 

if "!PSEL!"=="1" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="2" set "TARGET=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="3" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if "!PSEL!"=="4" goto cleanup

if not defined TARGET (
    echo Invalid choice.
    set "TARGET="
    goto menu
)

rem print current Shell value if present
set "SHORTPATH=!TARGET:HKEY_LOCAL_MACHINE=HKLM:!"
set "SHORTPATH=!SHORTPATH:HKEY_USERS=HKU:!"
echo.
reg query "!SHORTPATH!" /v Shell 2>nul
if errorlevel 1 echo   Shell = ^<not set^>

rem point regedit at this key, close any open regedit, relaunch
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /v LastKey /t REG_SZ /d "Computer\!TARGET!" /f >nul
taskkill /f /im regedit.exe >nul 2>&1
start regedit

set "TARGET="
echo.
echo regedit opened at that key.
goto menu

:cleanup
if "!WELOADED!"=="1" (
    echo.
    echo Close regedit before unloading, then press any key.
    pause >nul
    reg unload "HKU\!SEL_SID!" >nul 2>&1
    if errorlevel 1 (
        echo Unload failed - regedit is probably still holding the hive open. Close it and run:
        echo   reg unload HKU\!SEL_SID!
    ) else (
        echo Hive unloaded.
    )
)

pause
exit /b 0@echo off
setlocal enabledelayedexpansion

:: ---- require admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This must be run as Administrator.
    pause
    exit /b 1
)

set PLKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
set COUNT=0

echo.
@echo off
setlocal enabledelayedexpansion

:: ---- require admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This must be run as Administrator.
    pause
    exit /b 1
)

set PLKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
set COUNT=0

echo.
echo Scanning user profiles...
echo.

for /f "tokens=*" %%K in ('reg query "%PLKEY%" 2^>nul ^| findstr /i "S-1-5-21-"') do (
    set "SUBKEY=%%K"
    for %%A in ("!SUBKEY!") do set "SID=%%~nxA"

    rem pull ProfileImagePath for this SID
    set "IMGPATH="
    for /f "tokens=2,*" %%B in ('reg query "%PLKEY%\!SID!" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do set "IMGPATH=%%C"

    if defined IMGPATH (
        for %%N in ("!IMGPATH!") do set "UNAME=%%~nxN"

        rem check if hive is currently loaded
        reg query "HKU\!SID!" >nul 2>&1
        if !errorlevel! equ 0 (set "LOADED=loaded") else (set "LOADED=not loaded")

        set /a COUNT+=1
        set "SID_!COUNT!=!SID!"
        set "NAME_!COUNT!=!UNAME!"
        set "PATH_!COUNT!=!IMGPATH!"
        set "LOAD_!COUNT!=!LOADED!"

        echo !COUNT!^) !UNAME!   [!LOADED!]
        echo    !SID!
        echo.
    )
)

if %COUNT%==0 (
    echo No user profiles found.
    pause
    exit /b 1
)

:selectuser
set /p USEL=Select a user number: 
echo !USEL!| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 goto selectuser
if %USEL% gtr %COUNT% goto selectuser

set "SEL_SID=!SID_%USEL%!"
set "SEL_NAME=!NAME_%USEL%!"
set "SEL_PATH=!PATH_%USEL%!"
set "SEL_LOAD=!LOAD_%USEL%!"

echo.
echo Selected: !SEL_NAME!  (!SEL_SID!)

set "WELOADED=0"
if "!SEL_LOAD!"=="not loaded" (
    echo.
    set /p LOADIT=Hive not loaded. Load it now? [y/n]: 
    if /i "!LOADIT!"=="y" (
        reg load "HKU\!SEL_SID!" "!SEL_PATH!\NTUSER.DAT"
        if errorlevel 1 (
            echo Failed to load hive - it may be in use.
            pause
            exit /b 1
        )
        set "WELOADED=1"
    )
)

:menu
echo.
echo Registry paths for !SEL_NAME!:
echo   1^) HKU\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon     (per-user Shell)
echo   2^) HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon               (machine-wide Shell)
echo   3^) HKU\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System  (policy Shell override)
echo   4^) Quit
echo.
set /p PSEL=Select a path to open in regedit: 

if "!PSEL!"=="1" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="2" set "TARGET=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="3" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if "!PSEL!"=="4" goto cleanup

if not defined TARGET (
    echo Invalid choice.
    set "TARGET="
    goto menu
)

rem print current Shell value if present
set "SHORTPATH=!TARGET:HKEY_LOCAL_MACHINE=HKLM:!"
set "SHORTPATH=!SHORTPATH:HKEY_USERS=HKU:!"
echo.
reg query "!SHORTPATH!" /v Shell 2>nul
if errorlevel 1 echo   Shell = ^<not set^>

rem point regedit at this key, close any open regedit, relaunch
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /v LastKey /t REG_SZ /d "Computer\!TARGET!" /f >nul
taskkill /f /im regedit.exe >nul 2>&1
start regedit

set "TARGET="
echo.
echo regedit opened at that key.
goto menu

:cleanup
if "!WELOADED!"=="1" (
    echo.
    echo Close regedit before unloading, then press any key.
    pause >nul
    reg unload "HKU\!SEL_SID!" >nul 2>&1
    if errorlevel 1 (
        echo Unload failed - regedit is probably still holding the hive open. Close it and run:
        echo   reg unload HKU\!SEL_SID!
    ) else (
        echo Hive unloaded.
    )
)

pause
exit /b 0echo Scanning user profiles...
echo.

for /f "tokens=*" %%K in ('reg query "%PLKEY%" 2^>nul ^| findstr /i "S-1-5-21-"') do (
    set "SUBKEY=%%K"
    for %%A in ("!SUBKEY!") do set "SID=%%~nxA"

    rem pull ProfileImagePath for this SID
    set "IMGPATH="
    for /f "tokens=2,*" %%B in ('reg query "%PLKEY%\!SID!" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do set "IMGPATH=%%C"

    if defined IMGPATH (
        for %%N in ("!IMGPATH!") do set "UNAME=%%~nxN"

        rem check if hive is currently loaded
        reg query "HKU\!SID!" >nul 2>&1
        if !errorlevel! equ 0 (set "LOADED=loaded") else (set "LOADED=not loaded")

        set /a COUNT+=1
        set "SID_!COUNT!=!SID!"
        set "NAME_!COUNT!=!UNAME!"
        set "PATH_!COUNT!=!IMGPATH!"
        set "LOAD_!COUNT!=!LOADED!"

        echo !COUNT!^) !UNAME!   [!LOADED!]
        echo    !SID!
        echo.
    )
)

if %COUNT%==0 (
    echo No user profiles found.
    pause
    exit /b 1
)

:selectuser
set /p USEL=Select a user number: 
echo !USEL!| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 goto selectuser
if %USEL% gtr %COUNT% goto selectuser

set "SEL_SID=!SID_%USEL%!"
set "SEL_NAME=!NAME_%USEL%!"
set "SEL_PATH=!PATH_%USEL%!"
set "SEL_LOAD=!LOAD_%USEL%!"

echo.
echo Selected: !SEL_NAME!  (!SEL_SID!)

set "WELOADED=0"
if "!SEL_LOAD!"=="not loaded" (
    echo.
    set /p LOADIT=Hive not loaded. Load it now? [y/n]: 
    if /i "!LOADIT!"=="y" (
        reg load "HKU\!SEL_SID!" "!SEL_PATH!\NTUSER.DAT"
        if errorlevel 1 (
            echo Failed to load hive - it may be in use.
            pause
            exit /b 1
        )
        set "WELOADED=1"
    )
)

:menu
echo.
echo Registry paths for !SEL_NAME!:
echo   1^) HKU\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon     (per-user Shell)
echo   2^) HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon               (machine-wide Shell)
echo   3^) HKU\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System  (policy Shell override)
echo   4^) Quit
echo.
set /p PSEL=Select a path to open in regedit: 

if "!PSEL!"=="1" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="2" set "TARGET=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="3" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if "!PSEL!"=="4" goto cleanup

if not defined TARGET (
    echo Invalid choice.
    set "TARGET="
    goto menu
)

rem print current Shell value if present
set "SHORTPATH=!TARGET:HKEY_LOCAL_MACHINE=HKLM:!"
set "SHORTPATH=!SHORTPATH:HKEY_USERS=HKU:!"
echo.
reg query "!SHORTPATH!" /v Shell 2>nul
if errorlevel 1 echo   Shell = ^<not set^>

rem point regedit at this key, close any open regedit, relaunch
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /v LastKey /t REG_SZ /d "Computer\!TARGET!" /f >nul
taskkill /f /im regedit.exe >nul 2>&1
start regedit

set "TARGET="
echo.
echo regedit opened at that key.
goto menu

:cleanup
if "!WELOADED!"=="1" (
    echo.
    echo Close regedit before unloading, then press any key.
    pause >nul
    reg unload "HKU\!SEL_SID!" >nul 2>&1
    if errorlevel 1 (
        echo Unload failed - regedit is probably still holding the hive open. Close it and run:
        echo   reg unload HKU\!SEL_SID!
    ) else (
        echo Hive unloaded.
    )
)

pause
exit /b 0@echo off
setlocal enabledelayedexpansion

:: ---- require admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This must be run as Administrator.
    pause
    exit /b 1
)

set PLKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
set COUNT=0

echo.
echo Scanning user profiles...
echo.

for /f "tokens=*" %%K in ('reg query "%PLKEY%" 2^>nul ^| findstr /i "S-1-5-21-"') do (
    set "SUBKEY=%%K"
    for %%A in ("!SUBKEY!") do set "SID=%%~nxA"

    rem pull ProfileImagePath for this SID
    set "IMGPATH="
    for /f "tokens=2,*" %%B in ('reg query "%PLKEY%\!SID!" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do set "IMGPATH=%%C"

    if defined IMGPATH (
        for %%N in ("!IMGPATH!") do set "UNAME=%%~nxN"

        rem check if hive is currently loaded
        reg query "HKU\!SID!" >nul 2>&1
        if !errorlevel! equ 0 (set "LOADED=loaded") else (set "LOADED=not loaded")

        set /a COUNT+=1
        set "SID_!COUNT!=!SID!"
        set "NAME_!COUNT!=!UNAME!"
        set "PATH_!COUNT!=!IMGPATH!"
        set "LOAD_!COUNT!=!LOADED!"

        echo !COUNT!^) !UNAME!   [!LOADED!]
        echo    !SID!
        echo.
    )
)

if %COUNT%==0 (
    echo No user profiles found.
    pause
    exit /b 1
)

:selectuser
set /p USEL=Select a user number: 
echo !USEL!| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 goto selectuser
if %USEL% gtr %COUNT% goto selectuser

set "SEL_SID=!SID_%USEL%!"
set "SEL_NAME=!NAME_%USEL%!"
set "SEL_PATH=!PATH_%USEL%!"
set "SEL_LOAD=!LOAD_%USEL%!"

echo.
echo Selected: !SEL_NAME!  (!SEL_SID!)

set "WELOADED=0"
if "!SEL_LOAD!"=="not loaded" (
    echo.
    set /p LOADIT=Hive not loaded. Load it now? [y/n]: 
    if /i "!LOADIT!"=="y" (
        reg load "HKU\!SEL_SID!" "!SEL_PATH!\NTUSER.DAT"
        if errorlevel 1 (
            echo Failed to load hive - it may be in use.
            pause
            exit /b 1
        )
        set "WELOADED=1"
    )
)

:menu
echo.
echo Registry paths for !SEL_NAME!:
echo   1^) HKU\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon     (per-user Shell)
echo   2^) HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon               (machine-wide Shell)
echo   3^) HKU\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System  (policy Shell override)
echo   4^) Quit
echo.
set /p PSEL=Select a path to open in regedit: 

if "!PSEL!"=="1" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="2" set "TARGET=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="3" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if "!PSEL!"=="4" goto cleanup

if not defined TARGET (
    echo Invalid choice.
    set "TARGET="
    goto menu
)

rem print current Shell value if present
set "SHORTPATH=!TARGET:HKEY_LOCAL_MACHINE=HKLM:!"
set "SHORTPATH=!SHORTPATH:HKEY_USERS=HKU:!"
echo.
reg query "!SHORTPATH!" /v Shell 2>nul
if errorlevel 1 echo   Shell = ^<not set^>

rem point regedit at this key, close any open regedit, relaunch
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /v LastKey /t REG_SZ /d "Computer\!TARGET!" /f >nul
taskkill /f /im regedit.exe >nul 2>&1
start regedit

set "TARGET="
echo.
echo regedit opened at that key.
goto menu

:cleanup
if "!WELOADED!"=="1" (
    echo.
    echo Close regedit before unloading, then press any key.
    pause >nul
    reg unload "HKU\!SEL_SID!" >nul 2>&1
    if errorlevel 1 (
        echo Unload failed - regedit is probably still holding the hive open. Close it and run:
        echo   reg unload HKU\!SEL_SID!
    ) else (
        echo Hive unloaded.
    )
)

pause
exit /b 0@echo off
setlocal enabledelayedexpansion

:: ---- require admin ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This must be run as Administrator.
    pause
    exit /b 1
)

set PLKEY=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList
set COUNT=0

echo.
echo Scanning user profiles...
echo.

for /f "tokens=*" %%K in ('reg query "%PLKEY%" 2^>nul ^| findstr /i "S-1-5-21-"') do (
    set "SUBKEY=%%K"
    for %%A in ("!SUBKEY!") do set "SID=%%~nxA"

    rem pull ProfileImagePath for this SID
    set "IMGPATH="
    for /f "tokens=2,*" %%B in ('reg query "%PLKEY%\!SID!" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do set "IMGPATH=%%C"

    if defined IMGPATH (
        for %%N in ("!IMGPATH!") do set "UNAME=%%~nxN"

        rem check if hive is currently loaded
        reg query "HKU\!SID!" >nul 2>&1
        if !errorlevel! equ 0 (set "LOADED=loaded") else (set "LOADED=not loaded")

        set /a COUNT+=1
        set "SID_!COUNT!=!SID!"
        set "NAME_!COUNT!=!UNAME!"
        set "PATH_!COUNT!=!IMGPATH!"
        set "LOAD_!COUNT!=!LOADED!"

        echo !COUNT!^) !UNAME!   [!LOADED!]
        echo    !SID!
        echo.
    )
)

if %COUNT%==0 (
    echo No user profiles found.
    pause
    exit /b 1
)

:selectuser
set /p USEL=Select a user number: 
echo !USEL!| findstr /r "^[1-9][0-9]*$" >nul
if errorlevel 1 goto selectuser
if %USEL% gtr %COUNT% goto selectuser

set "SEL_SID=!SID_%USEL%!"
set "SEL_NAME=!NAME_%USEL%!"
set "SEL_PATH=!PATH_%USEL%!"
set "SEL_LOAD=!LOAD_%USEL%!"

echo.
echo Selected: !SEL_NAME!  (!SEL_SID!)

set "WELOADED=0"
if "!SEL_LOAD!"=="not loaded" (
    echo.
    set /p LOADIT=Hive not loaded. Load it now? [y/n]: 
    if /i "!LOADIT!"=="y" (
        reg load "HKU\!SEL_SID!" "!SEL_PATH!\NTUSER.DAT"
        if errorlevel 1 (
            echo Failed to load hive - it may be in use.
            pause
            exit /b 1
        )
        set "WELOADED=1"
    )
)

:menu
echo.
echo Registry paths for !SEL_NAME!:
echo   1^) HKU\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon     (per-user Shell)
echo   2^) HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon               (machine-wide Shell)
echo   3^) HKU\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System  (policy Shell override)
echo   4^) Quit
echo.
set /p PSEL=Select a path to open in regedit: 

if "!PSEL!"=="1" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="2" set "TARGET=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
if "!PSEL!"=="3" set "TARGET=HKEY_USERS\!SEL_SID!\Software\Microsoft\Windows\CurrentVersion\Policies\System"
if "!PSEL!"=="4" goto cleanup

if not defined TARGET (
    echo Invalid choice.
    set "TARGET="
    goto menu
)

rem print current Shell value if present
set "SHORTPATH=!TARGET:HKEY_LOCAL_MACHINE=HKLM:!"
set "SHORTPATH=!SHORTPATH:HKEY_USERS=HKU:!"
echo.
reg query "!SHORTPATH!" /v Shell 2>nul
if errorlevel 1 echo   Shell = ^<not set^>

rem point regedit at this key, close any open regedit, relaunch
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" /v LastKey /t REG_SZ /d "Computer\!TARGET!" /f >nul
taskkill /f /im regedit.exe >nul 2>&1
start regedit

set "TARGET="
echo.
echo regedit opened at that key.
goto menu

:cleanup
if "!WELOADED!"=="1" (
    echo.
    echo Close regedit before unloading, then press any key.
    pause >nul
    reg unload "HKU\!SEL_SID!" >nul 2>&1
    if errorlevel 1 (
        echo Unload failed - regedit is probably still holding the hive open. Close it and run:
        echo   reg unload HKU\!SEL_SID!
    ) else (
        echo Hive unloaded.
    )
)

pause
exit /b 0
