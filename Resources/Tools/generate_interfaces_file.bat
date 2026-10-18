@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Steam Interface Generator

if "%~1"=="" (
    echo Drop steam_api64.dll or steam_api.dll onto this EXE,
    echo or right-click the DLL and choose Steam Interface.
    goto done
)

set "DLL=%~f1"
set "DLL_NAME=%~nx1"
set "GENERATOR="

if /i "%DLL_NAME%"=="steam_api64.dll" set "GENERATOR=generate_interfaces_x64.exe"
if /i "%DLL_NAME%"=="steam_api.dll" set "GENERATOR=generate_interfaces_x86.exe"

if not defined GENERATOR (
    echo ERROR: The file must be named steam_api64.dll or steam_api.dll.
    echo Try again.
    goto done
)

if not exist "%DLL%" (
    echo ERROR: The DLL file could not be found.
    echo Try again.
    goto done
)

if exist "%DLL%\" (
    echo ERROR: Select a DLL file, not a folder.
    echo Try again.
    goto done
)

if %~z1 GEQ 5242880 (
    echo You need to use the ORIGINAL dll. Try again.
    goto done
)

if not exist "%~dp0%GENERATOR%" (
    echo ERROR: %GENERATOR% was not found beside this program.
    goto done
)

pushd "%~dp1"
if errorlevel 1 (
    echo ERROR: Could not access the DLL folder.
    goto done
)

echo Generating interfaces from "%DLL_NAME%"...
echo.
"%~dp0%GENERATOR%" "%DLL%"
set "RESULT=%ERRORLEVEL%"
popd

if not "%RESULT%"=="0" (
    echo.
    echo ERROR: The generator reported a failure.
    echo Check the output above.
    goto done
)
pause
clr

echo.
echo Drop the resulting steam_interfaces.txt file into the steam_settings folder. 
echo.
echo Right now it will be in the folder with the steam_api or steam_api64 dll

:done
echo.
set /p "EXIT_PROMPT=Press Enter to close..."
endlocal