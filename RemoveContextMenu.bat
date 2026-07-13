@echo off
setlocal EnableDelayedExpansion

echo.
echo ============================================
echo   ARMGDDN Autocracker - Registry Cleanup
echo   Removes ALL menu entries - current plus legacy OG/GBE
echo ============================================
echo.

:: -------------------------------------------------------
::  ADMIN CHECK
:: -------------------------------------------------------
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script requires administrator privileges.
    echo Right-click and select "Run as administrator".
    pause
    exit /b
)

echo Running with administrative privileges.
echo.
echo This will remove all ARMGDDN Autocracker context menu entries.
echo.
pause
echo.

:: -------------------------------------------------------
::  Current single-brand menu (removes any nested subtrees too)
:: -------------------------------------------------------
echo Removing current menu structure...
for %%T in (exefile dllfile Directory) do reg delete "HKCR\%%T\shell\ARMGDDNAutocracker" /f >nul 2>&1
:: CommandStore leaf verbs that back the submenu (current method)
for %%V in (Crack Cold Stub VD Interfaces) do reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\ARMGDDNAutocracker.%%V" /f >nul 2>&1
:: Retired ExtendedSubCommandsKey container keys (older layout)
for %%K in ("ARMGDDNAutocracker.Exe" "ARMGDDNAutocracker.Dll") do reg delete "HKCR\%%~K" /f >nul 2>&1

:: -------------------------------------------------------
::  Retired OG / GBE nested submenus (in case a parent lingered)
:: -------------------------------------------------------
echo Removing retired OG / GBE nested submenus...
for %%V in ("01_GBE" "02_OG" "01_OG" "02_GBE" "GBE Fork" "OG GSE") do for %%T in (exefile dllfile Directory) do reg delete "HKCR\%%T\shell\ARMGDDNAutocracker\shell\%%~V" /f >nul 2>&1

:: -------------------------------------------------------
::  Folder exclusion
:: -------------------------------------------------------
echo Removing AAC Folder Exclude...
reg delete "HKCR\Directory\shell\AACFolderExclude" /f >nul 2>&1

:: -------------------------------------------------------
::  Legacy flat entries (v1.x - v2.x) and every old name variant
:: -------------------------------------------------------
echo Removing legacy flat entries and old name variants...
for %%K in ("AutoCracker" "ColdClient" "Remove Steam Stub" "VD bat" "ARMGDDN Autocracker" "ARMGDDN Cold Client" "ARMGDDN Steam Stub Remover" "ARMGDDN VD Batmaker" "SteamInterfaces" "Steam Interfaces" "ARMGDDNAutocracker" "ARMGDDN_Autocracker" "ARMGDDN-Autocracker" "Autocracker") do for %%T in (exefile dllfile Directory) do reg delete "HKCR\%%T\shell\%%~K" /f >nul 2>&1

echo.
echo ============================================
echo   VERIFICATION
echo ============================================
echo.

set "stillExists=0"
for %%T in (exefile dllfile Directory) do reg query "HKCR\%%T\shell\ARMGDDNAutocracker" >nul 2>&1 && set "stillExists=1"

if "%stillExists%"=="0" echo All ARMGDDN context menu entries removed successfully!
if not "%stillExists%"=="0" echo WARNING: some entries may remain - check HKCR\exefile\shell, HKCR\dllfile\shell and HKCR\Directory\shell in regedit.

echo.
echo Cleanup Complete!
echo Restart Explorer or log out/in for menu changes to update.
echo.
pause
endlocal
exit /b
