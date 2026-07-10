@echo off
REM ============================================================
REM   ARMGDDN Autocracker - GBE FORK
REM   Steam Settings via Detanup01's generate_emu_config.exe
REM ============================================================
REM
REM This replaces the old ARMGDDN.Steam.Settings.exe step with the
REM official, maintained gbe_fork_tools generator. It is based on the
REM "_user" launcher (log in with a Steam account -- the same way our
REM tool was always meant to work; it uses the AchievementTestAccount)
REM with -img added so achievement ICONS are downloaded too, matching
REM the info our old Steam Settings step produced (achievements.json,
REM stats.json, images/, DLC config, etc.).
REM
REM ------------------------------------------------------------
REM   LOGIN MODE  (this is the important one for achievements)
REM ------------------------------------------------------------
REM   -tok  : log in with a real Steam account (interactive the first
REM           time, then it caches a token so later runs are silent).
REM           This is the reliable path -- as long as the account can
REM           see the game, achievements/stats come back. This is what
REM           our tool was built around, so it is the default.
REM   -anon : anonymous login, no account. Falls back to pulling the
REM           schema from the ~250 "top owner" accounts in
REM           top_owners_ids.txt. If NONE of them own the game (common
REM           for niche titles like StarMiner) you get NO achievements.
REM           This is what silently broke achievements for us.
REM
REM Flip the default here without touching the command below:
set "LOGINMODE=-tok"
REM set "LOGINMODE=-anon"

REM ------------------------------------------------------------
REM   APPID
REM ------------------------------------------------------------
REM Accept the AppID from the autocracker pipeline as the 1st argument.
REM If it wasn't passed in, fall back to prompting (like the original).
set "arg=%~1"
if "%arg%"=="" set /p arg="Generate Emu Config for Steam AppId: "

if "%arg%"=="" (
    echo No AppID provided. Nothing to do.
    pause
    exit /b 1
)

REM ------------------------------------------------------------
REM   Flags kept identical to the launchers you already use, plus -img
REM   -cdx -rne -acw -clr : the standard config flags from your bats
REM   -img                : download achievement icons (our old tool did
REM                         this; the plain launchers do not)
REM   %LOGINMODE%         : -tok (default) or -anon, see above
REM ------------------------------------------------------------
"%~dp0generate_emu_config.exe" -cdx -rne -acw -clr -img %LOGINMODE% %arg%
