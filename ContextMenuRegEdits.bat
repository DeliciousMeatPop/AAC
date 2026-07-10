@echo off
setlocal EnableDelayedExpansion

:: =======================================================
::  ARMGDDN Autocracker - Context Menu Installer
:: -------------------------------------------------------
::  Single-version setup. There is no separate OG-GSE or
::  GBE-Fork edition any more, just ARMGDDN Autocracker.
::  This script lives in the install folder itself, so all
::  paths are relative to %~dp0 (no "one level up" logic).
::
::  On install it first ERASES any previous menu entries
::  -- including the retired OG-GSE / GBE-Fork nested menus
::  and legacy flat entries -- so re-running this FIXES a
::  broken or outdated setup, then adds the current menus.
:: =======================================================

set "installDir=%~dp0"
if "%installDir:~-1%"=="\" set "installDir=%installDir:~0,-1%"

set "main=%installDir%\ARMGDDN.Main.exe"
set "mainIcon=%installDir%\ARMGDDN.Main.exe,0"
set "coldIcon=%installDir%\Resources\ARMGDDN.Cold.Client.exe,0"
set "stubIcon=%installDir%\Resources\SteamlessCLI\Steamless.CLI.exe,0"
set "vdIcon=%installDir%\Resources\ARMGDDN.VD.Batmaker.exe,0"
set "siExe=%installDir%\Resources\Tools\generate_interfaces_file.exe"
set "aacIcon=%installDir%\Resources\Tools\AAC_Autocracker.ico"
set "nircmdPath=%installDir%\Resources\Tools\nircmd.exe"
set "excludeExe=%installDir%\Resources\Tools\ExclusionHelper.exe"
set "dotnetInstaller=%installDir%\Resources\Tools\windowsdesktop-runtime-10.0.1-win-x64.exe"

echo Install dir: %installDir%
echo.

:: --- the main executable is required ---
if not exist "%main%" (
    echo ERROR: ARMGDDN.Main.exe not found in:
    echo   %installDir%
    echo Run this from inside the ARMGDDN Autocracker folder.
    pause
    exit /b
)

:: --- nircmd is optional (the voice / intro fun) ---
set "haveNircmd="
if exist "%nircmdPath%" set "haveNircmd=1"

:: -------------------------------------------------------
::  TALKY INTRO + ADMIN CHECK
:: -------------------------------------------------------
if defined haveNircmd (
    "%nircmdPath%" infobox "This Script TALKS." "Warning!"
    "%nircmdPath%" infobox "LOUDLY..." "Warning!"
    "%nircmdPath%" infobox "Turn down your volume NOW..." "Warning!"
    "%nircmdPath%" infobox "Ok I'm waiting..." "Warning!"
)

cls

if defined haveNircmd "%nircmdPath%" speak text "This script needs admin to run."
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Please run this script as administrator.
    pause
    exit /b
)

if defined haveNircmd "%nircmdPath%" speak text "Installing Armageddon Autocracker context menus."
echo.

:: -------------------------------------------------------
::  INSTALL .NET DESKTOP RUNTIME (REQUIRED FOR EXCLUSIONHELPER)
:: -------------------------------------------------------
if exist "%dotnetInstaller%" (
    echo Installing .NET Desktop Runtime (required for Exclusion Helper)...
    echo This may take a moment...
    if defined haveNircmd "%nircmdPath%" speak text "Installing dot net runtime. Please wait."
    "%dotnetInstaller%" /quiet /norestart
    if !errorlevel! EQU 0 (
        echo .NET Desktop Runtime installed successfully.
    ) else if !errorlevel! EQU 1638 (
        echo .NET Desktop Runtime already installed.
    ) else if !errorlevel! EQU 3010 (
        echo .NET Desktop Runtime installed. Restart may be required.
    ) else (
        echo .NET Desktop Runtime installer returned code: !errorlevel!
    )
    echo.
)

:: -------------------------------------------------------
::  FIX OLD SETUPS: erase any previous menu entries first
::  (retired OG-GSE / GBE-Fork nested menus + legacy flat)
::  so a re-install refreshes/repairs a stale setup.
:: -------------------------------------------------------
echo Cleaning up any previous / outdated menu entries...
call :cleanup_menus
echo.

:: -------------------------------------------------------
::  PARENT MENUS FOR EXE / DLL
:: -------------------------------------------------------
for %%T in (exefile dllfile) do (
    reg add "HKCR\%%T\shell\ARMGDDNAutocracker" /v "MUIVerb" /t REG_SZ /d "ARMGDDN Autocracker" /f
    reg add "HKCR\%%T\shell\ARMGDDNAutocracker" /v "Icon"   /t REG_SZ /d "%aacIcon%" /f
    reg add "HKCR\%%T\shell\ARMGDDNAutocracker" /v "SubCommands" /t REG_SZ /d "" /f
)

:: -------------------------------------------------------
::  EXE SUBMENU: Autocracker / Cold Client / Stub / VD Bat
:: -------------------------------------------------------
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\01_Autocracker" /v "MUIVerb" /d "Autocracker" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\01_Autocracker" /v "Icon"   /d "%mainIcon%" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\01_Autocracker\command" /ve /d "\"%main%\" \"%%1\"" /f

reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\02_ColdClient" /v "MUIVerb" /d "Cold Client" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\02_ColdClient" /v "Icon"   /d "%coldIcon%" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\02_ColdClient\command" /ve /d "\"%main%\" \"%%1\" \"3\"" /f

reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\03_SteamStub" /v "MUIVerb" /d "Steam Stub Remover" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\03_SteamStub" /v "Icon"   /d "%stubIcon%" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\03_SteamStub\command" /ve /d "\"%main%\" \"%%1\" \"1\"" /f

reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\04_VDBat" /v "MUIVerb" /d "VD Batmaker (VR)" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\04_VDBat" /v "Icon"   /d "%vdIcon%" /f
reg add "HKCR\exefile\shell\ARMGDDNAutocracker\shell\04_VDBat\command" /ve /d "\"%main%\" \"%%1\" \"2\"" /f

:: -------------------------------------------------------
::  DLL SUBMENU: Autocracker / Steam Interfaces
:: -------------------------------------------------------
reg add "HKCR\dllfile\shell\ARMGDDNAutocracker\shell\01_Autocracker" /v "MUIVerb" /d "Autocracker" /f
reg add "HKCR\dllfile\shell\ARMGDDNAutocracker\shell\01_Autocracker" /v "Icon"   /d "%mainIcon%" /f
reg add "HKCR\dllfile\shell\ARMGDDNAutocracker\shell\01_Autocracker\command" /ve /d "\"%main%\" \"%%1\"" /f

reg add "HKCR\dllfile\shell\ARMGDDNAutocracker\shell\02_SteamInterfaces" /v "MUIVerb" /d "Steam Interfaces" /f
reg add "HKCR\dllfile\shell\ARMGDDNAutocracker\shell\02_SteamInterfaces" /v "Icon"   /d "%coldIcon%" /f
reg add "HKCR\dllfile\shell\ARMGDDNAutocracker\shell\02_SteamInterfaces\command" /ve /d "\"%siExe%\" \"%%1\"" /f

if defined haveNircmd "%nircmdPath%" speak text "Added executable and DLL context menus."

:: -------------------------------------------------------
::  AAC FOLDER EXCLUDE - DIRECTORY MENU (standalone)
:: -------------------------------------------------------
if exist "%excludeExe%" (
    echo Adding Defender Exclusion context menu...
    reg add "HKCR\Directory\shell\AACFolderExclude" /v "MUIVerb" /t REG_SZ /d "AAC Folder Exclude" /f
    reg add "HKCR\Directory\shell\AACFolderExclude" /v "Icon" /t REG_SZ /d "%excludeExe%,0" /f
    reg add "HKCR\Directory\shell\AACFolderExclude\command" /ve /d "\"%excludeExe%\" \"%%1\"" /f
    if defined haveNircmd "%nircmdPath%" speak text "Added Defender folder exclusion context menu."
)

echo.
echo ============================================
echo   Context Menu Installation Complete!
echo ============================================
echo.
echo   ARMGDDN Autocracker
echo     (EXE)  Autocracker / Cold Client / Steam Stub Remover / VD Batmaker
echo     (DLL)  Autocracker / Steam Interfaces
echo.
echo   AAC Folder Exclude (right-click any folder)
echo.
if defined haveNircmd "%nircmdPath%" speak text "All context menu options added successfully. Enjoy."
pause

endlocal
exit /b

:: =======================================================
::  :cleanup_menus
::  Erases ALL current + legacy ARMGDDN menu entries.
::  Same coverage as RemoveContextMenu.bat, used here so
::  installing over an old/broken setup repairs it.
:: =======================================================
:cleanup_menus
:: current + retired nested master keys (also drops OG/GBE subtrees)
for %%T in (exefile dllfile Directory) do (
    reg delete "HKCR\%%T\shell\ARMGDDNAutocracker" /f >nul 2>&1
)
:: retired version subkeys, in case only a parent lingered
for %%V in ("01_GBE" "02_OG" "01_OG" "02_GBE" "GBE Fork" "OG GSE") do (
    for %%T in (exefile dllfile Directory) do (
        reg delete "HKCR\%%T\shell\ARMGDDNAutocracker\shell\%%~V" /f >nul 2>&1
    )
)
:: legacy flat entries (v1.x - v2.x) and every old name variant
for %%K in (
    "AutoCracker"
    "ColdClient"
    "Remove Steam Stub"
    "VD bat"
    "ARMGDDN Autocracker"
    "ARMGDDN Cold Client"
    "ARMGDDN Steam Stub Remover"
    "ARMGDDN VD Batmaker"
    "SteamInterfaces"
    "Steam Interfaces"
    "ARMGDDN_Autocracker"
    "ARMGDDN-Autocracker"
    "Autocracker"
) do (
    for %%T in (exefile dllfile Directory) do (
        reg delete "HKCR\%%T\shell\%%~K" /f >nul 2>&1
    )
)
:: old standalone folder-exclude (re-added afterwards)
reg delete "HKCR\Directory\shell\AACFolderExclude" /f >nul 2>&1
goto :eof
