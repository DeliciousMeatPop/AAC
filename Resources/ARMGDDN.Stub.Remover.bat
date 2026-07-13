@echo off
SETLOCAL
set "extension=%~x1"

if /i not "%extension%"==".exe" (
    echo WARNING: The file must be an EXE
    echo.
    echo NOW EXITING...
    echo.
    pause
    exit /b 1
)

set steamless="%~dp0SteamlessCLI\Steamless.CLI.exe"

REM cd into the game folder BEFORE running Steamless, so the unpacked
REM file is written next to the game rather than the launch dir. From the
REM context menu that launch dir is C:\Windows\System32 (not writable),
REM which would make the unpack silently produce nothing.
cd /d "%~dp1"

%steamless% --keepbind %1

IF EXIST "%~dp1%~nx1.unpacked.exe" (
  REN %1 "%~n1.AG"
  REN "%~nx1.unpacked.exe" "%~nx1"
  echo.
  echo Steam stub removed. Original backed up as "%~n1.AG".
) ELSE (
  echo.
  echo No unpacked file was produced.
  echo This EXE either has no Steam stub, or Steamless could not unpack it.
)
Pause