# ARMGDDN Autocracker Changelog

Welcome to the ARMGDDN Autocracker Changelog! Same chaos, better emulation, more features. Let's see what trouble we've gotten ourselves into!

## **v1.0.7 - 07/13/2026**
A Windows 11 update quietly broke the right-click menu, and the Steam Settings step tripped over where Windows was launching it from. Both fixed.

**Highlights**
- 🖱️ **Right-Click Menu Fixed on Windows 11:** After a Windows update, the *ARMGDDN Autocracker* submenu still appeared but clicking anything inside it did nothing — throwing *"This file does not have an app associated with it for performing this action"* on EXEs or *"The parameter is incorrect"* on DLLs. The menu had been built with an undocumented cascade trick (an empty `SubCommands` value plus a nested `shell` key) that newer Windows builds stopped honoring. It's been rebuilt using the **documented `CommandStore` cascade method** — the same one Windows itself uses — so the nested menu works again. Drag-and-drop was never affected.
- 📁 **Output Files Now Land in the Game Folder:** With the menu fixed, a second bug surfaced — the tools write their output *relative to the working directory*, and the context menu launches them from `C:\Windows\System32` (not writable). That made **Steam Settings** die with `PermissionError: [WinError 5] Access is denied: 'steam_settings'`, and made **VD Batmaker** and **Steam Stub Remover** silently produce nothing. All of them now switch into the **game folder** first, so `steam_settings\`, `VD.bat`, and the unpacked EXE all land next to your game where they belong.
- 🧯 **Friendlier Failures Instead of Silence:** Steam Settings now prints a **clear, specific message** if the destination genuinely isn't writable (Read-only folder, `Program Files`, etc.) instead of a raw Python traceback, VD Batmaker confirms where it wrote `VD.bat` (or says why it couldn't), and the Stub Remover tells you whether a stub was actually removed.

**Technical Details**
- Context menu: `ContextMenuRegEdits.bat` defines each submenu leaf once under `HKLM\...\Explorer\CommandStore\shell` and references them by name from the `exefile` / `dllfile` parents via a `SubCommands` list; installer cleanup and the uninstaller remove the CommandStore verbs (and the retired container keys).
- Working directory: `ARMGDDN.Autocracker.bat` and `ARMGDDN.Cold.Client.bat` `cd /d "%droppedDir%"` before generating; `ARMGDDN.Stub.Remover.bat` cd's into the game folder before running Steamless; `ARMGDDN.VD.Batmaker.bat` writes `VD.bat` to the game folder via an absolute path (and Main no longer needs to move it). The Python side wraps `os.makedirs('steam_settings')` to catch `PermissionError` and exit with guidance.

**Notes**
- **Re-run the context-menu installer** after updating so the menu is rebuilt with the working method. Upgrading from the broken menu? The installer wipes the old entries first, so it repairs itself.

---

## **v1.0.6 - 07/12/2026**
No more 403s. A quieter release focused on schema-fetch reliability and a couple of crash fixes.

**Highlights**
- 🏆 **Achievement Icon 403 Fixed:** Achievements that have no uploaded icon no longer trigger a 403 during Steam Settings generation, so games with partial icon sets stop failing.
- 🔔 **Update Check You Can Actually See:** The daily update check now gates its banner on a keypress, surfaces failures instead of silently no-op'ing, and forces TLS 1.2 so the GitHub call doesn't quietly fail.
- 🧵 **No More stdin Crash:** Interactive prompts no longer crash with `lost sys.stdin` when the tool runs without an attached console.

---

## **v1.0.5 - 07/10/2026**
Achievements are back, the tool checks itself for updates, and the whole thing is now just *one* ARMGDDN Autocracker instead of the old OG/GBE split. Spring cleaning, in July.

**Highlights**
- 🏆 **Achievements Actually Work Again:** The old build only queried a tiny 20-account owner list (and gated games behind a whitelist), so niche titles (looking at you, StarMiner) came back with nothing. It now pulls achievement/stat schemas against the full bundled list of ~250 top-owner accounts with the whitelist gone, so far more games generate reliably instead of silently skipping — all over an anonymous connection, no account or password needed.
- ⬆️ **Latest GBE Fork Core:** Updated all the bundled GBE Fork pieces — the `steam_api` / `steam_api64` DLLs (regular and ExOL), the Cold Client Loader files, and the tooling behind the `steam_settings` folder — to Detanup01's newest release (May 30, 2026). Latest emulator fixes and game compatibility, baked in.
- 🔑 **Web API Schema Fetch (the reliable one):** Drop a free Steam Web API key into `Resources/Tools/steam_webapi_key.txt` and achievements/stats are pulled **directly by AppID** (`GetSchemaForGame`) — owner-independent, so it fixes niche games the top-owner scan can't find (and it's fast). Used first when present, owner scan as fallback. Get a key at steamcommunity.com/dev/apikey. The first run walks you through adding it (and your SteamID64), with instructions, and tells you how to add them later if you skip.
- ⚡ **Faster Owner Scan With Your Own ID:** Drop your SteamID64 into `Resources/Tools/my_steam_ids.txt` and it's tried *first* in the owner scan. (Heads-up: the owner scan needs an account that has actually generated stats for the game, so a game you own but never played can still miss — the Web API key above avoids that entirely.)
- 🔔 **Daily Update Check:** `ARMGDDN.Main` quietly checks GitHub for a newer release once every 24 hours and tells you if one's out. No spam, no phoning home more than once a day.
- 🧹 **One Brand, Cleaner Menus:** No more separate OG-GSE / GBE-Fork editions or nested version submenus — just a single **ARMGDDN Autocracker** menu. EXEs get Autocracker / Cold Client / Steam Stub Remover / VD Batmaker; DLLs get Autocracker / Steam Interfaces; folders get AAC Folder Exclude.
- 🔧 **Self-Repairing Installer:** Re-running the context-menu installer now wipes any old or broken entries first (including the retired OG/GBE nested menus and every legacy flat entry) before rebuilding, so a re-install *fixes* a busted setup. The uninstaller still nukes everything.
- 🏷️ **x86 Loader Naming:** The 32-bit Cold Client loader is `steamclient_loader_x86.exe` now, and the renamed output matches as `ExeNameCCLx86.exe` (64-bit unchanged).

**Technical Details**
- Steam Settings: stays on anonymous login (real-account login via the steam library is broken by Steam's newer IAuthenticationService flow, which rejects the old password login with InvalidPassword); replaced the 20-ID hardcoded owner list with a bundled `top_owners_ids.txt` (~250 IDs, still merged with the online list) — the bigger owner pool is what actually fixes coverage.
- Dropped the per-run ~16 MB `steam_app_dict.json` download and the whitelist gate entirely; the game name now comes from Steam's product info, which was already being fetched.
- Removed dead code (unused inventory helpers and stale imports).
- Context menu rebuilt as a single-folder installer that locates its own install directory at runtime, so it works both as the raw `.bat` and as the compiled `.exe` (which can unpack to a temp dir where `%~dp0` is useless).
- Installer and uninstaller reworked to compile cleanly — no more "was unexpected at this time" crashes from batch-parser quirks (stray parentheses, multi-line `for` lists, subroutines).

**Notes**
- Coming from an older build? Just run the installer again — it cleans up the old menus for you. Or run the uninstaller for a totally clean slate.

---

## **v1.0.4 - 06/28/2026**
Housekeeping after the OG version got archived.

**Highlights**
- 📍 **New Home for the Data:** Archiving the OG-GSE repo stopped the automated workflow both versions shared, so it moved here — and the App ID and Steam Settings components were repointed to the new location.

**Notes**
- Updating from v1.0.x? Just replace `ARMGDDN.App.ID.exe` and `ARMGDDN.Steam.Settings.exe`. Fresh install? Grab the whole zip.

---

## **v1.0.3 - 06/28/2026**
Steam changed something on their end and broke logins. Patched, and faster too.

**Highlights**
- 🔓 **Login Fix:** The Steam Settings tool was throwing a bogus "bad login info" error that wasn't even true. It now connects anonymously with a fallback instead of hard-failing. *(The anonymous approach stuck; v1.0.5 later fixed the "some games have no achievements" gap by expanding the top-owner list to ~250 accounts.)*
- ⚡ **Faster steam_settings:** Folder creation was taking forever — refactored for speed.
- 🏆 **String-Type Schemas:** Carries the v1.0.2 achievement/stat fix for games that use string type identifiers.

**Notes**
- Updating? Just replace `ARMGDDN.Steam.Settings.exe`. Fresh install? Grab the whole zip.

---

## **v1.0.2 - 02/03/2026**
Bugfix release for games whose schemas speak in words, not numbers.

**Highlights**
- 🏆 **Fixed Achievement & Stat Detection:** Some games use string type identifiers (`ACHIEVEMENTS`, `INT`, `FLOAT`, `AVGRATE`) instead of the numeric constants, which made stats and achievements silently fail to generate. Both numeric and string identifiers are handled now.

**Technical Details**
- `stats_schema_achievement_gen/achievements_gen.py`: `stat['type'] == STAT_TYPE_BITS` now also matches `'ACHIEVEMENTS'`; same treatment for `INT` / `FLOAT` / `AVGRATE`.

**Thanks**
- **[EndzE](https://github.com/Detanup01/gbe_fork_tools/issues/9#issuecomment-3795927921)** — for identifying the string-identifier fix.

**Notes**
- Updating? Just replace `ARMGDDN.Steam.Settings.exe`. Fresh install? Grab the whole zip.

---

## **v1.0.1 - 12/18/2025**
Cold Client Loader just got a serious glow-up. Now it's not just functional — it's *pretty*.

**Highlights**
- 🎨 **Game Icon Extraction:** The Cold Client Loader now extracts the icon from your game's EXE and applies it to the renamed loader. Your game folder actually looks organized now. Revolutionary.
- 📛 **Smart Loader Renaming:** Instead of generic `steamclient_loader_x64.exe`, you now get `ExeNameCCLx64.exe` or `ExeNameCCLx32.exe`. No more guessing which exe makes the game go.
- 🔧 **New Tools Added:** Added `ffmpeg.exe` and `rcedit-x64.exe` to the Tools folder for icon conversion and embedding. They work silently in the background — you'll never even know they're there. Who knew ffmpeg had this up its sleeve??
- 🛡️ **Graceful Fallback:** If ffmpeg or rcedit are missing, the script continues normally without the icon. No crashes, no drama, just slightly less pretty loaders.

**Technical Details**
- Uses PowerShell + System.Drawing to extract icons from game EXEs
- ffmpeg converts PNG → ICO (because Windows is picky about its icon formats)
- rcedit embeds the ICO into the loader executable
- All temp files cleaned up automatically

**What It Looks Like Now**
```
Detected architecture: 64
Game is 64 bit. Using steamclient_loader_x64.exe
Loader renamed to: Expedition33_SteamCCLx64.exe
Extracting icon from game executable...
Icon applied successfully!
```

**Acknowledgements**
- **[NirSoft/NirCmd](https://www.nirsoft.net/utils/nircmd.html)** - For helping make the context menu install less boring
- **[electron/rcedit](https://github.com/electron/rcedit)** - For making icon embedding possible
- **[ffmpeg](https://www.ffmpeg.org/)** — For converting PNGs to ICOs easily! Who knew it could do that?! I sure didn't.
---

## **v1.0.0 - 12/12/2025**
🎉 **THE GBE FORK EDITION IS HERE!** 🎉

Remember back in v1.1.0 of the OG version when we said "Seriously considering finally doing a proper ARMGDDN Autocracker version based on the latest GBE fork"? Well, we actually did it. Took us long enough.

This is a complete rebuild powered by [Detanup01's GBE Fork](https://github.com/Detanup01/gbe_fork) — the actively maintained successor to Mr. Goldberg's original emulator. Same "right-click and go" philosophy, but with all the modern GBE Fork goodies.

**Core Features**
- 🔄 **One-Click DLL Replacement** — Right-click `steam_api.dll` or `steam_api64.dll`, pick Autocracker, done. Same workflow you know and love.
- 🧊 **Cold Client Loader** — For stubborn games that need injection. Auto-detects 32/64-bit architecture from the EXE header.
- 🔓 **Steam Stub Remover** — Steamless integration, same as always. Rip out those Steam stubs like a bad tooth.
- 🎮 **Steam Settings Generator** — Fetches achievements, stats, DLC, and images from Steam servers. Now outputs proper GBE Fork format.
- 🥽 **VD Batmaker** — For the VR headset gang using Virtual Desktop.

**Smart Features**
- 🔍 **Fuzzy Game Search** — Type "cyberpnuk" and find "Cyberpunk 2077". Three-tier matching: exact, token, and fuzzy. We believe in you. Mostly.
- 🔢 **Direct AppID Input** — Already know the AppID? Just type the number. We'll verify it exists and let you confirm.
- 🏗️ **Auto Architecture Detection** — Reads PE headers like a boss. No more guessing if it's 32 or 64-bit.
- 💾 **Persistent User Settings** — Set your username and save location once. Add `ask=0` to skip prompts forever.

**GBE Fork Specific Goodies**
- 📊 **Proper JSON Formats** — `stats.json` instead of `stats.txt`, `achievements.json` as expected by GBE Fork.
- 🖼️ **Correct Image Folder** — Achievement icons go to `images/` not `achievement_images/`.
- 📝 **Full Config Templates** — Generates `configs.app.ini`, `configs.user.ini`, and `configs.overlay.ini.disabled` with ALL the comments and documentation.
- 🎨 **Overlay Support (ExOL)** — Optional DLL builds with working SHIFT+TAB overlay and achievement popups. Choose between Regular and ExOL when cracking.
- 🔔 **Overlay Enable Prompts** — After using ExOL DLLs, you'll be asked if you want to enable the overlay with proper warnings about potential crashes.

**Context Menu Wizardry**
- 🖱️ **Nested Menus** — Clean 7-Zip style menus. Everything tucked under one parent menu, not scattered across your context menu like confetti.
- 🤝 **Dual Version Support** — Works alongside OG GSE! Put both folders in the same parent directory, run the installer, get both versions in one unified menu.
- 🛡️ **Windows Defender Integration** — Right-click any folder → "AAC Folder Exclude". Adds to Defender exclusions, even checks if it's already excluded.
- 📦 **Silent .NET Install** — Required runtime installs automatically during context menu setup. Already have it? Skips in 1-2 seconds.

**File Format Comparison**

| What | OG Goldberg | GBE Fork |
|------|-------------|----------|
| Stats | `stats.txt` | `stats.json` |
| Achievement icons | `achievement_images/` | `images/` |
| DLC config | `DLC.txt` | `configs.app.ini` |
| User settings | Scattered | `configs.user.ini` |
| Overlay config | N/A | `configs.overlay.ini` |

**Notes**
- This is a **separate project** from OG GSE — both will be maintained independently.
- Some games work better with OG, some with GBE Fork. That's why we made them work together.
- GBE Fork is actively maintained by Detanup01 and contributors. Bugs actually get fixed. Wild concept.

**Acknowledgements**
- **[Detanup01](https://github.com/Detanup01/gbe_fork)** — For keeping the dream alive with GBE Fork
- **[Mr. Goldberg](https://gitlab.com/Mr_Goldberg/goldberg_emulator)** — The OG. The legend. The reason any of this exists.
- **[Rat431](https://github.com/Rat431/ColdAPI_Steam)** — Cold Client Loader's humble beginnings
- **[atom0s](https://github.com/atom0s/Steamless)** — Steamless, because Steam stubs are annoying
- **[Sak32009](https://github.com/Sak32009/steam_py_fork)** — Steam module fixes that made everything faster
- **[SteamLadder](https://steamladder.com/)** — API access for achievement/DLC data
- **George Jefferson** — For being a great friend and telling me when I'm wrong (frequently)
- **The cs.rin.ru community** — For being the reason any of this matters

---

So there you have it! The GBE Fork Edition is officially a thing. We delivered on that v1.1.0 promise, only... *checks notes*... 7 months later. But hey, it's here now, and it's pretty great if we do say so ourselves.

**Happy cracking!** 🎮🔓
