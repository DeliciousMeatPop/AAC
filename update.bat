@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  ARMGDDN Autocracker - settings backup / restore for updates
REM
REM    update.bat            save your settings to ..\aacbackup
REM    update.bat -restore   put them back after extracting the new version
REM
REM  Typical update (e.g. v1.0.2 -> v1.0.3):
REM    1. run update.bat
REM    2. delete this folder and extract the new version
REM    3. run update.bat -restore from the new folder
REM ============================================================

set "root=%~dp0"
if "%root:~-1%"=="\" set "root=%root:~0,-1%"
set "backup=%root%\..\aacbackup"

REM Files to preserve, relative to this folder. Add more here as needed.
set "files=Resources\Tools\options.txt"
set "files=%files% Resources\Tools\my_steam_ids.txt"
set "files=%files% Resources\Tools\steam_webapi_key.txt"
set "files=%files% Resources\Tools\.setup_done"
set "files=%files% Resources\steam_ids_cache.txt"
set "files=%files% Resources\steam_app_dict_cache.json"
set "files=%files% Resources\.update_check"

set "mode=backup"
if /i "%~1"=="-restore" set "mode=restore"
if /i "%~1"=="/restore" set "mode=restore"
if /i "%~1"=="restore" set "mode=restore"

set "count=0"

if "%mode%"=="restore" goto :restore

:backup
echo Backing up settings to "%backup%"
if not exist "%backup%" mkdir "%backup%"
for %%F in (%files%) do (
    if exist "%root%\%%F" (
        for %%D in ("%backup%\%%F") do if not exist "%%~dpD" mkdir "%%~dpD"
        copy /y "%root%\%%F" "%backup%\%%F" >nul
        if not errorlevel 1 (
            echo   saved    %%F
            set /a count+=1
        ) else (
            echo   FAILED   %%F
        )
    ) else (
        echo   skipped  %%F ^(not found^)
    )
)
echo.
echo Backed up !count! file^(s^). Now delete this folder, extract the new
echo version, and run "update.bat -restore" from the new folder.
goto :end

:restore
if not exist "%backup%" (
    echo No backup found at "%backup%".
    echo Run update.bat without arguments in the old version first.
    goto :end
)
echo Restoring settings from "%backup%"
for %%F in (%files%) do (
    if exist "%backup%\%%F" (
        for %%D in ("%root%\%%F") do if not exist "%%~dpD" mkdir "%%~dpD"
        copy /y "%backup%\%%F" "%root%\%%F" >nul
        if not errorlevel 1 (
            echo   restored %%F
            set /a count+=1
        ) else (
            echo   FAILED   %%F
        )
    )
)
echo.
echo Restored !count! file^(s^). The backup was left in "%backup%"; delete
echo it once you have confirmed everything works.

:end
echo.
pause
endlocal
