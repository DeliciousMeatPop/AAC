@echo off
setlocal EnableDelayedExpansion

:: =======================================================
::  ARMGDDN Autocracker - Context Menu Installer
:: -------------------------------------------------------
::  Single-version setup. There is no separate OG-GSE or
::  GBE-Fork edition any more, just ARMGDDN Autocracker.
::  It figures out its own install folder (the one that holds
::  ARMGDDN.Main.exe) at runtime, so it works whether it's run
::  as this .bat or as the compiled .exe (which can unpack to
::  a temp dir, making %~dp0 useless on its own).
::
::  On install it first ERASES any previous menu entries
::  -- including the retired OG-GSE / GBE-Fork nested menus
::  and legacy flat entries -- so re-running this FIXES a
::  broken or outdated setup, then adds the current menus.
:: =======================================================

:: -------------------------------------------------------
::  LOCATE THE INSTALL FOLDER (the one holding ARMGDDN.Main.exe)
::  IMPORTANT: when this .bat is compiled to an .exe, the exe usually
::  unpacks the script to a TEMP folder, so %~dp0 is NOT the install
::  folder. Don't trust it blindly -- find the folder that actually
::  contains ARMGDDN.Main.exe: try the script/exe dir, then the launch
::  dir, and if both miss, just ask for it.
:: -------------------------------------------------------
echo Script dir: %~dp0
echo Launch dir: %CD%
echo.

set "installDir="
for %%D in ("%~dp0." "%CD%\.") do (
    if not defined installDir if exist "%%~fD\ARMGDDN.Main.exe" set "installDir=%%~fD"
)

if not defined installDir (
    echo Could not auto-detect the ARMGDDN Autocracker folder.
    echo If this is the compiled .exe, your bat-to-exe tool is unpacking to a
    echo temp folder -- just paste the real path to the folder below.
    echo.
    set /p "installDir=Full path to the folder with ARMGDDN.Main.exe: "
)

:: normalize: strip surrounding quotes, then any trailing backslash
if defined installDir set installDir=%installDir:"=%
if defined installDir if "%installDir:~-1%"=="\" set "installDir=%installDir:~0,-1%"

set "main=%installDir%\ARMGDDN.Main.exe"
if not exist "%main%" (
    echo.
    echo ERROR: ARMGDDN.Main.exe not found in:
    echo   %installDir%
    echo Put this installer in the ARMGDDN Autocracker folder next to
    echo ARMGDDN.Main.exe and run it again.
    pause
    exit /b
)

set "mainIcon=%main%,0"
set "aacIcon=%installDir%\Resources\Tools\AAC_Autocracker.ico"
set "coldIcon=%installDir%\Resources\ARMGDDN.Cold.Client.exe,0"
set "stubIcon=%installDir%\Resources\SteamlessCLI\Steamless.CLI.exe,0"
set "vdIcon=%installDir%\Resources\ARMGDDN.VD.Batmaker.exe,0"
set "siExe=%installDir%\Resources\Tools\generate_interfaces_file.exe"
set "nircmdPath=%installDir%\Resources\Tools\nircmd.exe"
set "excludeExe=%installDir%\Resources\Tools\ExclusionHelper.exe"
set "dotnetInstaller=%installDir%\Resources\Tools\windowsdesktop-runtime-10.0.1-win-x64.exe"

echo Using install dir: %installDir%
echo.

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
    echo Installing .NET Desktop Runtime - needed for Exclusion Helper...
    echo This may take a moment...
    if defined haveNircmd "%nircmdPath%" speak text "Installing dot net runtime. Please wait."
    "%dotnetInstaller%" /quiet /norestart
    echo Done.
    echo.
)

:: -------------------------------------------------------
::  FIX OLD SETUPS: erase any previous menu entries first
::  (retired OG-GSE / GBE-Fork nested menus + legacy flat)
::  so a re-install refreshes/repairs a stale setup.
:: -------------------------------------------------------
echo Cleaning up any previous / outdated menu entries...
for %%T in (exefile dllfile Directory) do reg delete "HKCR\%%T\shell\ARMGDDNAutocracker" /f >nul 2>&1
for %%V in ("01_GBE" "02_OG" "01_OG" "02_GBE" "GBE Fork" "OG GSE") do for %%T in (exefile dllfile Directory) do reg delete "HKCR\%%T\shell\ARMGDDNAutocracker\shell\%%~V" /f >nul 2>&1
for %%K in ("AutoCracker" "ColdClient" "Remove Steam Stub" "VD bat" "ARMGDDN Autocracker" "ARMGDDN Cold Client" "ARMGDDN Steam Stub Remover" "ARMGDDN VD Batmaker" "SteamInterfaces" "Steam Interfaces" "ARMGDDN_Autocracker" "ARMGDDN-Autocracker" "Autocracker") do for %%T in (exefile dllfile Directory) do reg delete "HKCR\%%T\shell\%%~K" /f >nul 2>&1
reg delete "HKCR\Directory\shell\AACFolderExclude" /f >nul 2>&1
echo.

:: -------------------------------------------------------
::  PARENT MENUS FOR EXE / DLL
:: -------------------------------------------------------
for %%T in (exefile dllfile) do reg add "HKCR\%%T\shell\ARMGDDNAutocracker" /v "MUIVerb" /t REG_SZ /d "ARMGDDN Autocracker" /f
for %%T in (exefile dllfile) do reg add "HKCR\%%T\shell\ARMGDDNAutocracker" /v "Icon" /t REG_SZ /d "%aacIcon%" /f
for %%T in (exefile dllfile) do reg add "HKCR\%%T\shell\ARMGDDNAutocracker" /v "SubCommands" /t REG_SZ /d "" /f

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
if exist "%excludeExe%" echo Adding Defender Exclusion context menu...
if exist "%excludeExe%" reg add "HKCR\Directory\shell\AACFolderExclude" /v "MUIVerb" /t REG_SZ /d "AAC Folder Exclude" /f
if exist "%excludeExe%" reg add "HKCR\Directory\shell\AACFolderExclude" /v "Icon" /t REG_SZ /d "%excludeExe%,0" /f
if exist "%excludeExe%" reg add "HKCR\Directory\shell\AACFolderExclude\command" /ve /d "\"%excludeExe%\" \"%%1\"" /f
if exist "%excludeExe%" if defined haveNircmd "%nircmdPath%" speak text "Added Defender folder exclusion context menu."

echo.
echo ============================================
echo   Context Menu Installation Complete!
echo ============================================
echo.
echo   ARMGDDN Autocracker
echo     EXE:  Autocracker / Cold Client / Steam Stub Remover / VD Batmaker
echo     DLL:  Autocracker / Steam Interfaces
echo.
echo   AAC Folder Exclude - right-click any folder
echo.
if defined haveNircmd "%nircmdPath%" speak text "All context menu options added successfully. Enjoy."
pause

endlocal
exit /b
