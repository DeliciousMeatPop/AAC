# ARMGDDN Autocracker Changelog

Welcome to the ARMGDDN Autocracker Changelog! Same chaos, better emulation, more features. Let's see what trouble we've gotten ourselves into!

## **v1.0.5 - 07/10/2026**
Achievements are back, the tool checks itself for updates, and the whole thing is now just *one* ARMGDDN Autocracker instead of the old OG/GBE split. Spring cleaning, in July.

**Highlights**
- 🏆 **Achievements Actually Work Again:** The Steam Settings generator logs in with an account again. The switch to anonymous login could only see games owned by a tiny hardcoded list, so niche titles (looking at you, StarMiner) came back with nothing. It now pulls achievement/stat schemas against a bundled list of ~250 top-owner accounts, so things generate reliably instead of silently skipping.
- 🔑 **Bring-Your-Own-Account:** If the shared achievement account ever gets rate-limited, drop a `Resources/Tools/steam_account.txt` with `username=` / `password=` and it'll use that instead — no recompiling. It caches a login token so later runs stay silent.
- 🔔 **Daily Update Check:** `ARMGDDN.Main` quietly checks GitHub for a newer release once every 24 hours and tells you if one's out. No spam, no phoning home more than once a day.
- 🧹 **One Brand, Cleaner Menus:** No more separate OG-GSE / GBE-Fork editions or nested version submenus — just a single **ARMGDDN Autocracker** menu. EXEs get Autocracker / Cold Client / Steam Stub Remover / VD Batmaker; DLLs get Autocracker / Steam Interfaces; folders get AAC Folder Exclude.
- 🔧 **Self-Repairing Installer:** Re-running the context-menu installer now wipes any old or broken entries first (including the retired OG/GBE nested menus and every legacy flat entry) before rebuilding, so a re-install *fixes* a busted setup. The uninstaller still nukes everything.
- 🏷️ **x86 Loader Naming:** The 32-bit Cold Client loader is `steamclient_loader_x86.exe` now, and the renamed output matches as `ExeNameCCLx86.exe` (64-bit unchanged).

**Technical Details**
- Steam Settings: restored a resilient account login with a `cli_login` fallback for Steam's newer auth flow; replaced the 20-ID hardcoded owner list with a bundled `top_owners_ids.txt` (~250 IDs, still merged with the online list).
- Dropped the per-run ~16 MB `steam_app_dict.json` download and the whitelist gate entirely; the game name now comes from Steam's product info, which was already being fetched.
- Removed dead code (unused inventory helpers and stale imports).
- Context menu now targets a single install folder via `%~dp0` instead of the old "one level up" dual-version detection.

**Notes**
- Coming from an older build? Just run the installer again — it cleans up the old menus for you. Or run the uninstaller for a totally clean slate.

---

## **v1.0.2 - v1.0.4**
Various fixes when steam broke shit. Not worth listing.


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
