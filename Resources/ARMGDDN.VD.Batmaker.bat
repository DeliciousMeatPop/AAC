@echo off
setlocal enableExtensions disableDelayedExpansion
echo                            _____ __________    _____    ________________  ________    _______   
echo                           /  _  \\______   \  /     \  /  _____/\______ \ \______ \MP \      \  
echo                          /  /_\  \^|       _/ /  \ /  \/   \  ___ ^|    ^|  \ ^|    ^|  \  /   ^|   \ 
echo                         /    ^|    \    ^|   \/    Y    \    \_\  \^|    `   \^|    `   \/    ^|    \
echo                         \____^|__  /____^|_  /\____^|__  /\______  /_______  /_______  /\____^|__  /
echo                                 \/       \/         \/        \/        \/        \/         \/ 
echo.
echo. 
set "extension=%~x1"

if /i not "%extension%"==".exe" (
    echo WARNING: The file must be an EXE
    echo.
    echo NOW EXITING...
    echo.
    pause
    exit /b 1
)

set /p cstm=Type in any needed arguments or just hit enter for none (EG:"-VR -Windowed", no quotes): 
echo.
echo.
echo Arguments set!
echo.
echo.
TIMEOUT /T 3

REM Write VD.bat straight into the GAME folder (%~dp1) with an absolute
REM path. Using a bare "> VD.bat" wrote it relative to the current dir,
REM which is C:\Windows\System32 when launched from the context menu --
REM so it silently failed (not writable) or landed somewhere invisible.
echo "C:\Program Files\Virtual Desktop Streamer\VirtualDesktop.Streamer.exe" "%~nx1" ^%cstm% > "%~dp1VD.bat"

if exist "%~dp1VD.bat" (
    echo.
    echo Created VD.bat in:
    echo   %~dp1
) else (
    echo.
    echo ERROR: Could not create VD.bat in:
    echo   %~dp1
    echo That folder may be read-only or otherwise not writable.
)
echo.
pause
goto :end

:end
endlocal
