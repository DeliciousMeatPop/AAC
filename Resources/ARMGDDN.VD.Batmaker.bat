@echo off
setlocal EnableExtensions DisableDelayedExpansion
title ARMGDDN Advanced Virtual Desktop BAT Maker

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%VD_BatMaker_Config.txt"
set "DEFAULT_VD=C:\Program Files\Virtual Desktop Streamer\VirtualDesktop.Streamer.exe"
set "SKIP_ARGUMENT_GUIDE=0"

call :Banner

if "%~1"=="" goto NoFile
if not exist "%~f1" goto MissingFile
if /I not "%~x1"==".exe" goto NotExe

set "GAME_PATH=%~f1"
set "GAME_DIR=%~dp1"
set "GAME_FILE=%~nx1"
set "OUTPUT_FILE=%GAME_DIR%VD.bat"

call :GetStreamerPath

if not defined VD_STREAMER goto SetupFailed
if not exist "%VD_STREAMER%" goto SetupFailed

goto AskArguments


:AskArguments
cls
call :Banner
echo Game selected:
echo "%GAME_PATH%"
echo.
if /I "%SKIP_ARGUMENT_GUIDE%"=="1" goto ContinueArguments

echo Dont know which arguments are needed?
echo https://qpmegathread.top/pcvr/#arguments
echo.
choice /C OCD /N /M "O = open guide, C = continue, D = dont ask me again im an old pro: "
if errorlevel 3 goto DisableArgumentGuide
if errorlevel 2 goto ContinueArguments

start "" "https://qpmegathread.top/pcvr/#arguments"
echo.
echo The argument guide was opened in your default browser.
echo Review it, then return to this window.
echo.
pause
goto ContinueArguments

:DisableArgumentGuide
set "SKIP_ARGUMENT_GUIDE=1"
call :SaveConfig
if errorlevel 1 goto ConfigSaveFailed
echo.
echo Got it, old pro mode enabled.
echo This question will be skipped from now on.
echo.

goto ContinueArguments

:ContinueArguments
echo.
echo IMPORTANT:
echo Always use the Meta argument if one exists.
echo Meta arguments usually give the best Virtual Desktop performance.
echo Only use SteamVR or OpenVR when no Meta option exists or Meta does not work.
echo.
echo Enter the arguments exactly as they should appear after the game EXE.
echo Do not put quotes around the entire argument list.
echo.
set "GAME_ARGS="
set /p "GAME_ARGS=Enter any needed arguments, or press Enter for none: "
cls
goto CheckWriteAccess


:CheckWriteAccess
set "WRITE_TEST=%GAME_DIR%.__vd_batmaker_write_test_%RANDOM%_%RANDOM%.tmp"

> "%WRITE_TEST%" echo test 2>nul

if not exist "%WRITE_TEST%" goto WriteFailed

del /q "%WRITE_TEST%" >nul 2>&1
goto CreateLauncher


:CreateLauncher
echo.
echo Creating:
echo "%OUTPUT_FILE%"
echo.

> "%OUTPUT_FILE%" echo @echo off
if not exist "%OUTPUT_FILE%" goto WriteFailed

>> "%OUTPUT_FILE%" echo setlocal EnableExtensions DisableDelayedExpansion
>> "%OUTPUT_FILE%" echo title Virtual Desktop Launcher - %GAME_FILE%
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo set "VD_STREAMER=%VD_STREAMER%"
>> "%OUTPUT_FILE%" echo set "GAME_EXE=%%~dp0%GAME_FILE%"
>> "%OUTPUT_FILE%" echo set "GAME_NAME=%GAME_FILE%"
>> "%OUTPUT_FILE%" echo set "GAME_ARGS=%GAME_ARGS%"
>> "%OUTPUT_FILE%" echo set "DISPLAY_ARGS=%%GAME_ARGS%%"
>> "%OUTPUT_FILE%" echo if not defined DISPLAY_ARGS set "DISPLAY_ARGS=no arguments"
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo if not exist "%%VD_STREAMER%%" ^(
>> "%OUTPUT_FILE%" echo     echo ERROR: Virtual Desktop Streamer was not found at:
>> "%OUTPUT_FILE%" echo     echo "%%VD_STREAMER%%"
>> "%OUTPUT_FILE%" echo     echo.
>> "%OUTPUT_FILE%" echo     echo Open VD.bat in Notepad and correct the VD_STREAMER path.
>> "%OUTPUT_FILE%" echo     echo.
>> "%OUTPUT_FILE%" echo     pause
>> "%OUTPUT_FILE%" echo     exit /b 1
>> "%OUTPUT_FILE%" echo ^)
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo if not exist "%%GAME_EXE%%" ^(
>> "%OUTPUT_FILE%" echo     echo ERROR: The game executable was not found at:
>> "%OUTPUT_FILE%" echo     echo "%%GAME_EXE%%"
>> "%OUTPUT_FILE%" echo     echo.
>> "%OUTPUT_FILE%" echo     echo Keep VD.bat in the same folder as %GAME_FILE%.
>> "%OUTPUT_FILE%" echo     echo.
>> "%OUTPUT_FILE%" echo     pause
>> "%OUTPUT_FILE%" echo     exit /b 1
>> "%OUTPUT_FILE%" echo ^)
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo cls
>> "%OUTPUT_FILE%" echo echo Now launching %%GAME_NAME%% with %%DISPLAY_ARGS%%. Please wait
>> "%OUTPUT_FILE%" echo echo.
>> "%OUTPUT_FILE%" echo echo 3
>> "%OUTPUT_FILE%" echo timeout /t 1 /nobreak ^>nul
>> "%OUTPUT_FILE%" echo echo 2
>> "%OUTPUT_FILE%" echo timeout /t 1 /nobreak ^>nul
>> "%OUTPUT_FILE%" echo echo 1
>> "%OUTPUT_FILE%" echo timeout /t 1 /nobreak ^>nul
>> "%OUTPUT_FILE%" echo echo.
>> "%OUTPUT_FILE%" echo pushd "%%~dp0"
>> "%OUTPUT_FILE%" echo "%%VD_STREAMER%%" "%%GAME_EXE%%" %%GAME_ARGS%%
>> "%OUTPUT_FILE%" echo set "LAUNCH_EXIT_CODE=%%ERRORLEVEL%%"
>> "%OUTPUT_FILE%" echo popd
>> "%OUTPUT_FILE%" echo exit /b %%LAUNCH_EXIT_CODE%%

if not exist "%OUTPUT_FILE%" goto WriteFailed
cls
echo VD.bat was created successfully:
echo "%OUTPUT_FILE%"
echo.
echo It will launch:
echo "%GAME_FILE%"
echo.
if defined GAME_ARGS (
    echo Arguments:
    echo %GAME_ARGS%
) else (
    echo Arguments:
    echo None
)
echo.
pause
exit /b 0


:GetStreamerPath
set "VD_STREAMER="
set "SKIP_ARGUMENT_GUIDE=0"
set "CONFIG_NEEDS_RESAVE=0"
call :LoadConfig

set "VD_STREAMER=%VD_STREAMER:"=%"
call :RepairStreamerPath

if defined VD_STREAMER if exist "%VD_STREAMER%" (
    if "%CONFIG_NEEDS_RESAVE%"=="1" call :SaveConfig
    goto :eof
)

if defined VD_STREAMER (
    echo.
    echo The saved Virtual Desktop Streamer path is no longer valid:
    echo "%VD_STREAMER%"
    echo.
    echo It needs to be configured again.
    echo.
)

goto ConfigureStreamer


:ConfigureStreamer
echo Virtual Desktop Streamer setup
echo.
echo Default location:
echo "%DEFAULT_VD%"
echo.
choice /C YN /N /M "Is Virtual Desktop Streamer installed there? [Y/N]: "

if errorlevel 2 goto CustomStreamerPath

set "VD_STREAMER=%DEFAULT_VD%"

if not exist "%VD_STREAMER%" (
    echo.
    echo Virtual Desktop Streamer was not found in the default location.
    echo.
    goto CustomStreamerPath
)

call :SaveConfig
if errorlevel 1 goto ConfigSaveFailed
goto :eof


:CustomStreamerPath
set "VD_STREAMER="
set /p "VD_STREAMER=Paste the absolute path to VirtualDesktop.Streamer.exe: "
set "VD_STREAMER=%VD_STREAMER:"=%"

if not defined VD_STREAMER (
    echo.
    echo No path was entered. Try again.
    echo.
    goto CustomStreamerPath
)

if not exist "%VD_STREAMER%" (
    echo.
    echo That file does not exist:
    echo "%VD_STREAMER%"
    echo.
    goto CustomStreamerPath
)

for %%I in ("%VD_STREAMER%") do set "VD_FILE_NAME=%%~nxI"

if /I not "%VD_FILE_NAME%"=="VirtualDesktop.Streamer.exe" (
    echo.
    echo WARNING: The selected file is:
    echo "%VD_FILE_NAME%"
    echo.
    echo The expected file is:
    echo "VirtualDesktop.Streamer.exe"
    echo.
    choice /C YN /N /M "Use the selected file anyway? [Y/N]: "
    if errorlevel 2 goto CustomStreamerPath
)

call :SaveConfig
if errorlevel 1 goto ConfigSaveFailed
goto :eof


:LoadConfig
if not exist "%CONFIG_FILE%" goto :eof

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG_FILE%") do (
    if /I "%%A"=="VD_STREAMER" set "VD_STREAMER=%%B"
    if /I "%%A"=="SKIP_ARGUMENT_GUIDE" set "SKIP_ARGUMENT_GUIDE=%%B"
)

if defined VD_STREAMER goto :eof

rem Backward compatibility with the older one-line config format.
set /p "VD_STREAMER="<"%CONFIG_FILE%"
set "VD_STREAMER=%VD_STREAMER:"=%"
goto :eof


:RepairStreamerPath
rem Self-heal configs where the SKIP_ARGUMENT_GUIDE setting was folded onto
rem the VD_STREAMER line, for example:
rem   VD_STREAMER=...\VirtualDesktop.Streamer.exe SKIP_ARGUMENT_GUIDE=1
rem The "tokens=1,* delims==" parse in :LoadConfig swallows everything after
rem the first "=" into VD_STREAMER, so the trailing key/value becomes part of
rem the path and "if exist" then reports it as invalid. Split it back out and
rem flag the config for a rewrite in the correct two-line format.
if not defined VD_STREAMER goto :eof
setlocal EnableDelayedExpansion
if "!VD_STREAMER!"=="!VD_STREAMER: SKIP_ARGUMENT_GUIDE=!" (
    rem Nothing folded in; leave the value untouched.
    endlocal
    goto :eof
)
set "sentinel=!VD_STREAMER: SKIP_ARGUMENT_GUIDE=|!"
for /f "tokens=1* delims=|" %%a in ("!sentinel!") do (
    set "cleanpath=%%a"
    set "foldedskip=%%b"
)
endlocal & set "VD_STREAMER=%cleanpath%" & set "SKIP_ARGUMENT_GUIDE=%foldedskip%" & set "CONFIG_NEEDS_RESAVE=1"
if defined SKIP_ARGUMENT_GUIDE if "%SKIP_ARGUMENT_GUIDE:~0,1%"=="=" set "SKIP_ARGUMENT_GUIDE=%SKIP_ARGUMENT_GUIDE:~1%"
if not "%SKIP_ARGUMENT_GUIDE%"=="1" set "SKIP_ARGUMENT_GUIDE=0"
goto :eof


:SaveConfig
if not defined SKIP_ARGUMENT_GUIDE set "SKIP_ARGUMENT_GUIDE=0"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
    "$path = [Environment]::GetEnvironmentVariable('CONFIG_FILE');" ^
    "$vd = [Environment]::GetEnvironmentVariable('VD_STREAMER');" ^
    "$skip = [Environment]::GetEnvironmentVariable('SKIP_ARGUMENT_GUIDE');" ^
    "$utf8 = New-Object System.Text.UTF8Encoding($false);" ^
    "$lines = @('VD_STREAMER=' + $vd, 'SKIP_ARGUMENT_GUIDE=' + $skip);" ^
    "[System.IO.File]::WriteAllLines($path, $lines, $utf8)"

if errorlevel 1 exit /b 1
if not exist "%CONFIG_FILE%" exit /b 1
exit /b 0


:ConfigSaveFailed
echo.
echo ERROR: The settings file could not be saved:
echo "%CONFIG_FILE%"
echo.
echo Move this BAT maker to a writable folder and try again.
echo.
set "VD_STREAMER="
exit /b 1


:NoFile
echo Drag the games EXE directly onto this BAT maker.
echo.
echo VD.bat will be created in the same folder as the dropped game EXE.
echo.
pause
exit /b 1


:MissingFile
echo ERROR: The dropped file could not be found:
echo "%~f1"
echo.
pause
exit /b 1


:NotExe
echo ERROR: Please drop a game EXE onto this BAT maker.
echo.
echo Dropped file:
echo "%~f1"
echo.
pause
exit /b 1


:SetupFailed
echo.
echo ERROR: The Virtual Desktop Streamer path was not configured.
echo.
pause
exit /b 1


:WriteFailed
echo.
echo ERROR: VD.bat could not be created in:
echo "%GAME_DIR%"
echo.
echo This normally means Windows does not allow writing to that folder.
echo Try running this BAT maker as administrator, then drop the EXE onto it again.
echo.
pause
exit /b 1


:Banner
echo.
echo                             ^.______  .______  ._____ ___ ._____  .______  .______  .____  ___
echo                             ^:   _   \: __   \ :     V   ^|:     \ : _._  \ : _._  \ :    \ ^|  ^|
echo                             ^|  ^|_^|  ^|^|  \____^|^|   \  /  ^|^|    __^|^|^|   ^:  ^|^|^|   ^:  ^|^|  ^|\ \^|  ^|
echo                             ^|   ^:   ^|^|   :  \ ^|   ^|\/   ^|^|   /  ^|^|^:_._^|  ^|^|^:_._^|  ^|^|  ^| \ \  ^|
echo                             ^|___^|   ^|^|   ^|___\^|___^| ^|   ^|^|      ^|^|_.____/ ^|_.____/ ^|__^|  \   ^|
echo                                 ^|___^|^|___^|          ^|___^|: _____^|                     DMP \__^|
echo                            :----------------PC/PCVR------:/------:--------:-----------------:
echo.
goto :eof
