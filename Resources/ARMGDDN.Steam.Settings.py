import os
import sys
import json
import urllib.request
import urllib.error
import threading
import queue

# Add Tools/ to path so imports work both when run directly and when frozen
_base = os.path.dirname(sys.executable) if getattr(sys, 'frozen', False) else os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_base, 'Tools'))


def _safe_input(prompt=""):
    """input() that returns "" instead of crashing when stdin is unavailable.

    When this tool is launched by another process (e.g. the Autocracker) the
    child can have no attached console, and CPython's input() then raises
    RuntimeError('lost sys.stdin') rather than EOFError. Treat both as "no
    answer" so interactive prompts skip gracefully instead of aborting the run.
    """
    try:
        return input(prompt)
    except (EOFError, RuntimeError):
        return ""


HARDCODED_STEAM_IDS = [
    76561198017975643, 76561198028121353, 76561197979911851, 76561198355953202,
    76561198217186687, 76561197993544755, 76561198001237877, 76561198237402290,
    76561198152618007, 76561198213148949, 76561198037867621, 76561197969050296,
    76561198134044398, 76561198001678750, 76561198094227663, 76561197973009892,
    76561198019712127, 76561197976597747, 76561197963550511, 76561198044596404,
]

STEAM_IDS_URL = "https://raw.githubusercontent.com/DeliciousMeatPop/steam-top-accounts-data/main/steam_ids_only.txt"
LOCAL_STEAM_IDS_FILE = "steam_ids_cache.txt"
# Bundled list of ~250 "top owner" Steam IDs. A game's stats schema is fetched
# by asking an account that owns the game, so a larger owner pool massively
# improves coverage for niche titles (this file replaces the old 20-ID list).
TOP_OWNERS_FILE = "top_owners_ids.txt"

def get_base_path():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    else:
        return os.path.dirname(os.path.abspath(__file__))

BASE_PATH = get_base_path()
LOCAL_STEAM_IDS_FILE = os.path.join(BASE_PATH, LOCAL_STEAM_IDS_FILE)
TOP_OWNERS_FILE = os.path.join(BASE_PATH, "Tools", TOP_OWNERS_FILE)

def get_options_file_path():
    base = get_base_path()
    return os.path.join(base, "Tools", "options.txt")

def load_user_options():
    defaults = {
        'account_name': 'ARMGDDN',
        'portable': '0',
        'local_save_path': 'saves',
        'saves_folder_name': 'GSE Saves',
        'ask': '1'
    }
    
    options_file = get_options_file_path()
    
    if not os.path.exists(options_file):
        return defaults
    
    try:
        with open(options_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if '=' in line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    if key == 'username':
                        key = 'account_name'
                    if key in defaults:
                        defaults[key] = value
    except Exception as e:
        print(f"Warning: Could not load options.txt: {e}")
    
    return defaults


def save_user_options(options):
    options_file = get_options_file_path()
    
    tools_dir = os.path.dirname(options_file)
    if not os.path.exists(tools_dir):
        os.makedirs(tools_dir)
    
    try:
        with open(options_file, 'w', encoding='utf-8') as f:
            f.write("# ARMGDDN Autocracker User Options\n")
            f.write("# These settings are used when generating steam_settings\n")
            f.write("\n")
            f.write(f"account_name={options['account_name']}\n")
            f.write(f"portable={options['portable']}\n")
            f.write(f"local_save_path={options['local_save_path']}\n")
            f.write(f"saves_folder_name={options['saves_folder_name']}\n")
            f.write("\n")
            f.write("# ask=1 prompts you every time, ask=0 uses these settings silently\n")
            f.write(f"ask={options.get('ask', '1')}\n")
        print(f"Options saved to: {options_file}")
    except Exception as e:
        print(f"Warning: Could not save options.txt: {e}")


def prompt_user_options():
    options = load_user_options()
    
    if options.get('ask', '1') == '0':
        print()
        print(f"Using saved settings (username: {options['account_name']})")
        if options['portable'] == '1':
            print(f"Save location: PORTABLE (./{options['local_save_path']}/)")        
        else:
            print(f"Save location: AppData ({options['saves_folder_name']})")
        print("(To change settings, edit ask=0 to ask=1 in Resources/Tools/options.txt)")
        print()
        return options
    
    print()
    print("============================================")
    print("  User Settings Configuration")
    print("============================================")
    print()
    print(f"Current username: {options['account_name']}")
    if options['portable'] == '1':
        print(f"Save location: PORTABLE (game folder: {options['local_save_path']})")
    else:
        print(f"Save location: AppData ({options['saves_folder_name']})")
    print()
    
    change = _safe_input("Change username or save location? (Y/N): ").strip().upper()
    
    if change != 'Y':
        print("Keeping current settings.")
        print()
        print("--------------------------------------------")
        print("Don't want to be asked every time?")
        print("Add ask=0 to Resources/Tools/options.txt")
        print("--------------------------------------------")
        print()
        return options
    
    print()
    print("--------------------------------------------")
    print("  Username")
    print("--------------------------------------------")
    print(f"Currently set to: {options['account_name']}")
    new_username = _safe_input("Type new username or hit Enter to keep current: ").strip()
    if new_username:
        options['account_name'] = new_username
        print(f"Username changed to: {options['account_name']}")
    else:
        print(f"Keeping username: {options['account_name']}")
    
    print()
    print("--------------------------------------------")
    print("  Save Location")
    print("--------------------------------------------")
    print()
    print("Options:")
    print("  1. PORTABLE - saves in game folder (relative to DLL)")
    print("     WARNING: Saves stored with game files, not in AppData")
    print()
    print("  0. APPDATA - Saves in AppData folder (default, recommended)")
    print("     Saves persist even if game is deleted/moved")
    print()
    
    if options['portable'] == '1':
        print(f"Currently: PORTABLE (path: {options['local_save_path']})")
    else:
        print(f"Currently: APPDATA (folder: {options['saves_folder_name']})")
    print()
    
    save_choice = _safe_input("Choose save location (1=Portable, 0=AppData, Enter=keep current): ").strip()
    
    if save_choice == '1':
        options['portable'] = '1'
        print()
        print(f"Current portable path: {options['local_save_path']}")
        print("This path is relative to the game's steam_api DLL location.")
        new_path = _safe_input("Enter save folder name (or Enter for current): ").strip()
        if new_path:
            options['local_save_path'] = new_path
        print(f"Portable saves will be stored in: ./{options['local_save_path']}/")
        
    elif save_choice == '0':
        options['portable'] = '0'
        print()
        print(f"Current AppData folder name: {options['saves_folder_name']}")
        new_folder = _safe_input("Enter folder name (or Enter for 'GSE Saves'): ").strip()
        if new_folder:
            options['saves_folder_name'] = new_folder
        else:
            options['saves_folder_name'] = 'GSE Saves'
        print(f"Saves will be stored in: %AppData%/{options['saves_folder_name']}/")
    else:
        print("Keeping current save location setting.")
    
    print()
    print("--------------------------------------------")
    disable_ask = _safe_input("Stop asking every time? (Y/N): ").strip().upper()
    if disable_ask == 'Y':
        options['ask'] = '0'
        print("Got it! Will use these settings silently next time.")
        print("(Change ask=0 to ask=1 in options.txt to re-enable prompts)")
    else:
        options['ask'] = '1'
    
    save_user_options(options)
    
    print()
    print("Settings updated!")
    print()
    
    return options


def _read_owner_id_file(path):
    """Read Steam64 IDs (one per line) from a file, skipping blanks/#comments."""
    ids = []
    try:
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                try:
                    ids.append(int(line))
                except ValueError:
                    pass
    except OSError:
        pass
    return ids


def load_bundled_owner_ids():
    """Owner Steam IDs to query for game schemas, in priority order:
      1. your own IDs from Tools/my_steam_ids.txt (tried FIRST -- if you own
         the game it's an instant hit, and this file survives updates to the
         bundled list). Your Steam profile 'Game details' must be Public.
      2. the bundled ~250 top-owner list (Tools/top_owners_ids.txt)
      3. the small builtin fallback list
    Duplicates are dropped, keeping the first (highest-priority) occurrence."""
    my_ids_file = os.path.join(BASE_PATH, "Tools", "my_steam_ids.txt")
    my_ids = _read_owner_id_file(my_ids_file)
    bundled = _read_owner_id_file(TOP_OWNERS_FILE)
    if not bundled:
        print("Note: top_owners_ids.txt not found, using builtin fallback IDs.")
    if my_ids:
        print(f"Trying your {len(my_ids)} personal Steam ID(s) first.")

    ids = []
    for sid in my_ids + bundled + HARDCODED_STEAM_IDS:
        if sid not in ids:
            ids.append(sid)
    return ids


def download_and_merge_steam_ids():
    """Download and merge Steam IDs from GitHub with hardcoded list."""
    final_steam_ids = load_bundled_owner_ids()
    print(f"Starting with {len(final_steam_ids)} bundled top-owner Steam IDs...")
    
    try:
        print("Attempting to download Steam IDs from GitHub...")
        with urllib.request.urlopen(STEAM_IDS_URL, timeout=10) as response:
            content = response.read().decode('utf-8')
            
            with open(LOCAL_STEAM_IDS_FILE, 'w') as f:
                f.write(content)
            
            github_steam_ids = []
            for line in content.strip().split('\n'):
                line = line.strip()
                if line:
                    try:
                        github_steam_ids.append(int(line))
                    except ValueError:
                        pass
            
            for steam_id in github_steam_ids:
                if steam_id not in final_steam_ids:
                    final_steam_ids.append(steam_id)
                    
    except Exception as e:
        print(f"Error downloading Steam IDs: {e}")
        try:
            with open(LOCAL_STEAM_IDS_FILE, 'r') as f:
                content = f.read()
                for line in content.strip().split('\n'):
                    line = line.strip()
                    if line:
                        try:
                            steam_id = int(line)
                            if steam_id not in final_steam_ids:
                                final_steam_ids.append(steam_id)
                        except ValueError:
                            pass
        except:
            pass
    
    return final_steam_ids

TOP_OWNER_IDS = download_and_merge_steam_ids()

from stats_schema_achievement_gen import achievements_gen
from steam.client import SteamClient
from steam.enums.common import EResult
from steam.enums.emsg import EMsg
from steam.core.msg import MsgProto

if len(sys.argv) < 2:
    print("\nUsage: ARMGDDN.Steam.Settings.exe APPID\n\nExample: ARMGDDN.Steam.Settings.exe 480\n")
    sys.exit(1)

appids = []
for id in sys.argv[1:]:
    appids += [int(id)]

client = SteamClient()

# Anonymous login -- no account or password needed. Each game's stats schema
# is fetched from the top-owner accounts (TOP_OWNER_IDS) via ClientGetUserStats,
# which works fine on an anonymous session. (Real-account login via this library
# is broken by Steam's newer IAuthenticationService flow: it rejects the old CM
# password login with InvalidPassword even when the password is correct, and
# then loops asking for the password.)
print("Connecting to Steam (anonymous)...")
result = client.anonymous_login()
if result != EResult.OK:
    print(f"Steam connection failed: {result}")
    print("Check your internet connection and try again.")
    sys.exit(1)
print("Connected.")


def get_stats_schema(client, game_id, owner_id):
    message = MsgProto(EMsg.ClientGetUserStats)
    message.body.game_id = game_id
    message.body.schema_local_version = -1
    message.body.crc_stats = 0
    message.body.steam_id_for_user = owner_id
    client.send(message)
    # A 1s timeout was too aggressive: Steam's stats response often takes
    # longer than a second, so valid schemas were being dropped and games
    # ended up with no achievements. 3s is a safe balance of speed vs.
    # reliability (the loop still breaks as soon as a schema comes back).
    return client.wait_msg(EMsg.ClientGetUserStatsResponse, timeout=3)


def download_achievement_images(game_id, image_names, output_folder):
    q = queue.Queue()

    def downloader_thread():
        while True:
            name = q.get()
            if name is None:
                q.task_done()
                return
            succeeded = False
            for u in ["https://cdn.akamai.steamstatic.com/steamcommunity/public/images/apps/",
                      "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/"]:
                url = "{}{}/{}".format(u, game_id, name)
                try:
                    with urllib.request.urlopen(url) as response:
                        image_data = response.read()
                        with open(os.path.join(output_folder, name), "wb") as f:
                            f.write(image_data)
                        succeeded = True
                        break
                except urllib.error.HTTPError as e:
                    print(f"HTTPError downloading {url}: {e.code}")
                except urllib.error.URLError as e:
                    print(f"URLError downloading {url}: {e.reason}")
            if not succeeded:
                print(f"Error: could not download {name}")
            q.task_done()

    num_threads = 20
    for i in range(num_threads):
        threading.Thread(target=downloader_thread, daemon=True).start()

    for name in image_names:
        q.put(name)
    q.join()

    for i in range(num_threads):
        q.put(None)
    q.join()


def load_webapi_key():
    """Steam Web API key, from the STEAM_WEBAPI_KEY env var or
    Resources/Tools/steam_webapi_key.txt. With a key we can pull a game's
    achievement schema straight from Steam by AppID (GetSchemaForGame), with
    no dependence on any owner account -- the reliable path for niche games.
    Get a free key at https://steamcommunity.com/dev/apikey ."""
    key = os.environ.get("STEAM_WEBAPI_KEY", "").strip()
    if key:
        return key
    key_file = os.path.join(BASE_PATH, "Tools", "steam_webapi_key.txt")
    try:
        with open(key_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    return line
    except OSError:
        pass
    return ""


def game_has_achievements(game_id):
    """Keyless check: does this game expose ANY achievements?

    Steam's public store endpoint (appdetails) reports the achievement count
    with no API key and no owner account, so we can decide up front whether a
    schema fetch is even worth attempting -- and skip both the Web API call
    and the slow top-owner scan for the many niche/new games that have none.

    Returns:
      True  -- the store lists one or more achievements.
      False -- the store definitively lists none.
      None  -- inconclusive (request failed, or Steam returned no usable data,
               e.g. some age-gated or delisted titles). The caller should then
               proceed normally rather than skip, so this can never hide a
               game's achievements -- it only fast-paths the certain-zero case."""
    url = ("https://store.steampowered.com/api/appdetails"
           "?appids={}&l=english".format(game_id))
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None

    entry = data.get(str(game_id)) if isinstance(data, dict) else None
    if not isinstance(entry, dict) or not entry.get("success"):
        return None
    details = entry.get("data")
    if not isinstance(details, dict):
        return None
    ach = details.get("achievements")
    total = ach.get("total", 0) if isinstance(ach, dict) else 0
    try:
        return int(total) > 0
    except (TypeError, ValueError):
        return None


def _download_icon_urls(url_map, output_folder):
    """url_map: {filename: full_url}. Download each to output_folder/filename."""
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    q = queue.Queue()

    def worker():
        while True:
            item = q.get()
            if item is None:
                q.task_done()
                return
            fname, url = item
            try:
                with urllib.request.urlopen(url, timeout=15) as resp:
                    with open(os.path.join(output_folder, fname), "wb") as f:
                        f.write(resp.read())
            except Exception as e:
                print(f"Error downloading {fname}: {e}")
            q.task_done()

    threads = [threading.Thread(target=worker, daemon=True) for _ in range(20)]
    for t in threads:
        t.start()
    for fname, url in url_map.items():
        q.put((fname, url))
    q.join()
    for _ in threads:
        q.put(None)
    q.join()


def generate_from_webapi(game_id, api_key, output_directory):
    """Fetch the achievement/stat schema straight from Steam's Web API
    (ISteamUserStats/GetSchemaForGame). Owner-independent: works for any game
    by AppID. Writes achievements.json / stats.json (GBE format) and downloads
    the icons.

    Returns:
      "ok"  -- the Web API answered (HTTP 200). This is authoritative and
               owner-independent: any achievements/stats were written, and if
               it found none the game genuinely has none (the top-owner scan
               uses the exact same schema data and cannot do better).
      None  -- the request itself FAILED (network error / bad key). Only in
               this case should the caller fall back to the top-owner scan."""
    url = ("https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v2/"
           "?key={}&appid={}&l=english".format(api_key, game_id))
    try:
        with urllib.request.urlopen(url, timeout=20) as resp:
            data = json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        if e.code == 403:
            print("Web API key was rejected (403). Check Resources/Tools/steam_webapi_key.txt.")
        else:
            print(f"Web API error {e.code} fetching schema for {game_id}.")
        return None
    except Exception as e:
        print(f"Web API request failed: {e}")
        return None

    stats_block = data.get("game", {}).get("availableGameStats", {}) or {}
    ach_in = stats_block.get("achievements", []) or []
    stats_in = stats_block.get("stats", []) or []
    if not ach_in and not stats_in:
        # HTTP 200 but the game exposes no achievements or stats at all. This
        # is authoritative -- the top-owner scan queries the same underlying
        # UserGameStatsSchema and would also come back empty, so signal
        # success (no fallback) rather than burning minutes on a scan that
        # cannot find anything. Many niche/new games simply have no
        # achievements; that is not an error.
        print("Web API: this game has no achievements or stats.")
        return "ok"

    achievements_out = []
    icon_urls = {}
    for a in ach_in:
        entry = {
            "name": a.get("name", ""),
            "hidden": str(a.get("hidden", 0)),
            "displayName": a.get("displayName", ""),
            "description": a.get("description", ""),
        }
        for src_key, dst_key in (("icon", "icon"), ("icongray", "icon_gray")):
            u = a.get(src_key)
            if u:
                fname = u.rstrip("/").split("/")[-1]
                # Some games leave an achievement icon unset. The Web API then
                # returns a URL that ends at the app image directory with no
                # file, e.g. ".../images/apps/1311570/", so fname collapses to
                # the AppID. Requesting a directory makes Steam's CDN answer
                # 403 Forbidden, so skip anything without a real filename.
                if "." not in fname:
                    continue
                icon_urls[fname] = u
                entry[dst_key] = "images/" + fname
        achievements_out.append(entry)

    stats_out = []
    for s in stats_in:
        dv = s.get("defaultvalue", 0)
        stats_out.append({
            "name": s.get("name", ""),
            "type": "int",
            "default": str(int(dv)) if isinstance(dv, (int, float)) else "0",
            "global": "0",
        })

    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
    with open(os.path.join(output_directory, "achievements.json"), 'w', encoding='utf-8') as f:
        f.write(json.dumps(achievements_out, indent=4))
    if stats_out:
        with open(os.path.join(output_directory, "stats.json"), 'w', encoding='utf-8') as f:
            f.write(json.dumps(stats_out, indent=2))

    if icon_urls:
        print(f"Downloading {len(icon_urls)} achievement icons...")
        _download_icon_urls(icon_urls, os.path.join(output_directory, "images"))

    print(f"Web API: got {len(achievements_out)} achievements and {len(stats_out)} stats.")
    return "ok"


def generate_achievement_stats(client, game_id, output_directory):
    # Fast keyless pre-check: if Steam's public store data says this game has
    # no achievements at all, there is nothing for either the Web API or the
    # top-owner scan to find -- bail out immediately instead of grinding the
    # 250+ ID list. Works even without a Web API key. Only skips on a
    # definitive "none"; an inconclusive result (None) proceeds as normal.
    if game_has_achievements(game_id) is False:
        print("Steam reports this game has no achievements -- skipping schema fetch.")
        return False

    # Preferred path: Steam Web API (owner-independent, fast, reliable) when a
    # key is configured. Falls back to the top-owner client scan otherwise.
    api_key = load_webapi_key()
    if api_key:
        # The Web API is owner-independent and authoritative. If it ANSWERS
        # (even to say the game has no achievements), the top-owner scan uses
        # the same schema data and cannot do better -- so we're done and skip
        # the slow 250+ ID scan entirely. We only fall back when the request
        # itself failed (network error / rejected key).
        if generate_from_webapi(game_id, api_key, output_directory) is not None:
            return True
        print("Web API request failed; falling back to the top-owner scan...")

    images_dir = os.path.join(output_directory, "images")
    images_to_download = []

    if not TOP_OWNER_IDS:
        print("Warning: No Steam IDs available. Skipping achievement stats generation.")
        return False
    
    stats_generated = False
    steam_id_list = TOP_OWNER_IDS
    
    print(f"Fetching achievement schema (trying up to {len(steam_id_list)} Steam IDs)...")
    for i, x in enumerate(steam_id_list):
        out = get_stats_schema(client, game_id, x)
        if out is not None:
            if len(out.body.schema) > 0:
                try:
                    achievements, stats = achievements_gen.generate_stats_achievements(
                        out.body.schema, output_directory
                    )
                    
                    if stats and len(stats) > 0:
                        stats_generated = True
                        print(f"Generated stats.json with {len(stats)} stats")
                    
                    for ach in achievements:
                        for icon_key in ("icon", "icon_gray", "icongray"):
                            if icon_key not in ach:
                                continue
                            icon_name = ach[icon_key].replace("images/", "")
                            # Skip icons the game never uploaded: an empty or
                            # extension-less name resolves to the app image
                            # directory, which Steam's CDN answers with 403.
                            if "." not in icon_name:
                                continue
                            images_to_download.append(icon_name)
                    print(f"Got achievement schema from ID #{i+1} ({len(achievements)} achievements)")
                    break
                except ValueError as e:
                    print(f"Error generating stats for Steam ID {x}: {e}")
                    continue

    if not images_to_download:
        print("No achievements found for this game.")

    if len(images_to_download) > 0:
        if not os.path.exists(images_dir):
            os.makedirs(images_dir)
        download_achievement_images(game_id, images_to_download, images_dir)
        print(f"Downloaded {len(images_to_download)} achievement images to images/ folder")
    
    return stats_generated


def get_dlc(raw_infos):
    try:
        try:
            dlc_list = set(map(lambda a: int(a), raw_infos["extended"]["listofdlc"].split(",")))
        except:
            dlc_list = set()
        depot_app_list = set()
        if "depots" in raw_infos:
            depots = raw_infos["depots"]
            for dep in depots:
                depot_info = depots[dep]
                if "dlcappid" in depot_info:
                    dlc_list.add(int(depot_info["dlcappid"]))
                if "depotfromapp" in depot_info:
                    depot_app_list.add(int(depot_info["depotfromapp"]))
        return (dlc_list, depot_app_list)
    except:
        print("Could not get DLC infos, are there any DLCs?")
        return (set(), set())


def generate_configs_app_ini(output_directory, dlc_list=None):
    if dlc_list is None:
        dlc_list = []
    
    ini_path = os.path.join(output_directory, "configs.app.ini")
    
    lines = []
    
    lines.append("")
    lines.append("[app::general]")
    lines.append("# by default the emu will report a `non-beta` branch when the game calls `Steam_Apps::GetCurrentBetaName()`")
    lines.append("# 1=make the game/app think we're playing on a beta branch")
    lines.append("# default=0")
    lines.append("is_beta_branch=0")
    lines.append("# the name of the current branch, this must also exist in branches.json")
    lines.append("# otherwise will be ignored by the emu and the default 'public' branch will be used")
    lines.append("# default=public")
    lines.append("branch_name=public")
    
    lines.append("")
    lines.append("[app::dlcs]")
    lines.append("# 1=report all DLCs as unlocked")
    lines.append("# 0=report only the DLCs mentioned")
    lines.append("# some games check for \"hidden\" DLCs, hence this should be set to 1 in that case")
    lines.append("# but other games detect emus by querying for a fake/bad DLC, hence this should be set to 0 in that case")
    lines.append("# default=1")
    lines.append("unlock_all=1")
    lines.append("# format: ID=name")
    
    for dlc_id, dlc_name in dlc_list:
        if dlc_name is not None:
            lines.append(f"{dlc_id}={dlc_name}")
        else:
            lines.append(f"{dlc_id}=Unknown DLC")
    
    lines.append("")
    lines.append("[app::paths]")
    lines.append("# some rare games might need to be provided one or more paths to appids")
    lines.append("# for example the path to where a DLC is installed")
    lines.append("# this sets the paths returned by the Steam_Apps::GetAppInstallDir function")
    lines.append("#556760=../DLCRoot0")
    lines.append("#1234=./folder_where_steam_api_is")
    lines.append("#3456=../folder_one_level_above_where_steam_api_is")
    lines.append("#5678=../../folder_two_levels_above_where_steam_api_is")
    lines.append("# however some other games might expect this function to return empty paths to properly load DLCs")
    lines.append("# you can deliberately set the path to be empty to specify this behavior like lines below")
    lines.append("#1337=")
    
    lines.append("")
    lines.append("[app::cloud_save::general]")
    lines.append("# should the emu create the default directory for cloud saves on startup:")
    lines.append("#   [Steam Install]/userdata/{Steam3AccountID}/{AppID}/")
    lines.append("# default=1")
    lines.append("create_default_dir=0")
    lines.append("# should the emu create the directories specified in the cloud saves section of the current OS on startup")
    lines.append("# default=1")
    lines.append("create_specific_dirs=1")
    lines.append("# directories which should be created on startup, this is used for cloud saves")
    lines.append("# some games refuse to work unless these directories exist")
    lines.append("# there are reserved identifiers which are replaced at runtime")
    lines.append("# you can find a list of them here:")
    lines.append("#   https://partner.steamgames.com/doc/features/cloud#setup")
    lines.append("#")
    lines.append("# the identifiers must be wrapped with double colons \":::\" like this:")
    lines.append("#   original value: {SteamCloudDocuments}")
    lines.append("#   ini value:      {::SteamCloudDocuments::}")
    lines.append("# notice the braces \"{\" and \"}\", they are not changed")
    lines.append("# the double colons are added between them as shown above")
    lines.append("#")
    lines.append("# === known identifiers:")
    lines.append("# ---")
    lines.append("# --- general:")
    lines.append("# ---")
    lines.append("# Steam3AccountID=current account ID in Steam3 format")
    lines.append("# 64BitSteamID=current account ID in Steam64 format")
    lines.append("# gameinstall=[Steam Install]\\SteamApps\\common\\[Game Folder]\\")
    lines.append("# EmuSteamInstall=this is an emu specific variable, the value preference is as follows:")
    lines.append("#  - from environment variable: SteamPath")
    lines.append("#  - or from environment variable: InstallPath")
    lines.append("#  - or if using coldclientloader: directory of steamclient")
    lines.append("#  - or if NOT using coldclientloader: directory of steam_api")
    lines.append("#  - or directory of exe")
    lines.append("# ---")
    lines.append("# --- Windows only:")
    lines.append("# ---")
    lines.append("# WinMyDocuments=%USERPROFILE%\\My Documents\\")
    lines.append("# WinAppDataLocal=%USERPROFILE%\\AppData\\Local\\")
    lines.append("# WinAppDataLocalLow=%USERPROFILE%\\AppData\\LocalLow\\")
    lines.append("# WinAppDataRoaming=%USERPROFILE%\\AppData\\Roaming\\")
    lines.append("# WinSavedGames=%USERPROFILE%\\Saved Games\\")
    lines.append("# ---")
    lines.append("# --- Linux only:")
    lines.append("# ---")
    lines.append("# LinuxHome=~/")
    lines.append("# SteamCloudDocuments=")
    lines.append("#   - Linux:   ~/.SteamCloud/[username]/[Game Folder]/")
    lines.append("#   - Windows: X")
    lines.append("#   - MAcOS:   X")
    lines.append("# LinuxXdgDataHome=")
    lines.append("#   - if 'XDG_DATA_HOME' is defined: $XDG_DATA_HOME/")
    lines.append("#   - otherwise:                     $HOME/.local/share")
    
    lines.append("")
    lines.append("[app::cloud_save::win]")
    lines.append("#dir1={::WinAppDataRoaming::}/publisher_name/some_game")
    lines.append("#dir2={::WinMyDocuments::}/publisher_name/some_game/{::Steam3AccountID::}")
    
    lines.append("")
    lines.append("[app::cloud_save::linux]")
    lines.append("#dir1={::LinuxXdgDataHome::}/publisher_name/some_game")
    lines.append("#dir2={::LinuxHome::}/publisher_name/some_game/{::64BitSteamID::}")
    
    with open(ini_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    if len(dlc_list) > 0:
        print(f"Created configs.app.ini with {len(dlc_list)} DLC entries")
    else:
        print("Created configs.app.ini (no DLCs)")


def generate_configs_user_ini(output_directory, options):
    ini_path = os.path.join(output_directory, "configs.user.ini")
    
    lines = []
    
    lines.append("[user::general]")
    lines.append("# user account name")
    lines.append("# default=gse orca")
    lines.append(f"account_name={options['account_name']}")
    lines.append("# your account ID in Steam64 format")
    lines.append("# if the specified ID is invalid, the emu will ignore it and generate a proper one")
    lines.append("# default=randomly generated by the emu only once and saved in the global settings")
    lines.append("account_steamid=76561197960287930")
    lines.append("# Example Base64 Ticket.")
    lines.append("#ticket=SGVyZSBsYXlzIHlvdXIgQmFzZTY0IFRpY2tldCB5b3UgYmVhdXRpZnVsIGhhY2tlcg==")
    lines.append("# Alt SteamId for encrypted savegames.")
    lines.append("#alt_steamid=0")
    lines.append("# How many calls before swapping out the SteamId to Alt")
    lines.append("# IT WILL REPLACE AFTER THOSE CALLS BE AWARE!")
    lines.append("#alt_steamid_count=5")
    lines.append("# the language reported to the app/game")
    lines.append("# this must exist in 'supported_languages.txt', otherwise it will be ignored by the emu")
    lines.append("# look for the column 'API language code' here: https://partner.steamgames.com/doc/store/localization/languages")
    lines.append("# default=english")
    lines.append("language=english")
    lines.append("# report a country IP if the game queries it")
    lines.append("# ISO 3166-1-alpha-2 format, use this link to get the 'Alpha-2' country code: https://www.iban.com/country-codes")
    lines.append("# default=US")
    lines.append("ip_country=US")
    
    lines.append("")
    lines.append("[user::saves]")
    lines.append("# when this is set, it will force the emu to use the specified location instead of the default global location")
    lines.append("# path could be absolute, or relative to the location of the .dll/.so")
    lines.append("# leading and trailing whitespaces are trimmed")
    lines.append("# when this option is used, the global settings folder is completely ignored, allowing a full portable behavior")
    lines.append("# default=")
    
    if options['portable'] == '1':
        lines.append(f"local_save_path={options['local_save_path']}")
    else:
        lines.append("local_save_path=")
    
    lines.append("# name of the base folder used to store save data, leading and trailing whitespaces are trimmed")
    lines.append("# only useful if 'local_save_path' isn't used")
    lines.append("# default=GSE Saves")
    lines.append(f"saves_folder_name={options['saves_folder_name']}")
    
    with open(ini_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print("Created configs.user.ini")
    if options['portable'] == '1':
        print(f"  Save location: PORTABLE (./{options['local_save_path']}/)")    
    else:
        print(f"  Save location: AppData ({options['saves_folder_name']})")


def generate_configs_overlay_ini(output_directory):
    ini_path = os.path.join(output_directory, "configs.overlay.ini.disabled")
    
    content = """# ----------------------------
# XXXXXXXXXXXXXXXXXXXXXXXXXXXX
# XXX USE AT YOUR OWN RISK XXX
# XXXXXXXXXXXXXXXXXXXXXXXXXXXX
# ----------------------------
# 
# This feature might cause crashes or other problems
# RENAME THIS FILE TO configs.overlay.ini TO ENABLE
# 
# ############################################################################## #
# you do not have to specify everything, pick and choose the options you need only
# ############################################################################## #

[overlay::general]
# 1=enable the experimental overlay, might cause crashes
# default=0
enable_experimental_overlay=1
# amount of time to wait before attempting to detect and hook the renderer (DirectX, OpenGL, etc...)
# default=0
hook_delay_sec=0
# timeout for the renderer detector
# default=15
renderer_detector_timeout_sec=15
# 1=disable the achievements notifications
# default=0
disable_achievement_notification=0
# 1=disable friends invitations and messages notifications
# default=0
disable_friend_notification=0
# 1=disable showing notifications for achievements progress
# default=0
disable_achievement_progress=0
# 1=disable any warning in the overlay
# default=0
disable_warning_any=0
# 1=disable the bad app ID warning in the overlay
# default=0
disable_warning_bad_appid=0
# 1=disable the local_save warning in the overlay
# default=0
disable_warning_local_save=0
# by default the overlay will attempt to upload the achievements icons to the GPU
# so that they are displayed, in rare cases this might keep failing and cause FPS drop
# 0=prevent the overlay from attempting to upload the icons periodically,
#   in that case achievements icons win't be displayed
# default=1
upload_achievements_icons_to_gpu=1
# amount of frames to accumulate, to eventually calculate the average frametime (in milliseconds)
# lower values would result in instantaneous frametime/fps, but the FPS would be erratic
# higher values would result in a more stable frametime/fps, but will be inaccurate due to averaging over long time
# minimum allowed value = 1
# default=10
fps_averaging_window=10
# 1=always show user info in the overlay
# default=0
overlay_always_show_user_info=0
# 1=always show fps in the overlay
# default=0
overlay_always_show_fps=0
# 1=always show frametime in the overlay
# default=0
overlay_always_show_frametime=0
# 1=always show playtime in the overlay
# default=0
overlay_always_show_playtime=0

[overlay::appearance]
# load custom TrueType font from a path, it could be absolute, or relative
# relative paths will be looked up inside the local folder "steam_settings/fonts" first,
# if that wasn't found, it will be looked up inside the global folder "GSE Settings/settings/fonts"
# default=
Font_Override=Roboto-Medium.ttf
# global font size
# for built-in font, multiple of 16 is recommended. e.g. 16 32...
# default=16.0
Font_Size=20.0

# achievement icon size
Icon_Size=64.0

# spacing between characters
Font_Glyph_Extra_Spacing_x=1.0
Font_Glyph_Extra_Spacing_y=0.0

# background for all types of notifications
Notification_R=0.12
Notification_G=0.14
Notification_B=0.21
Notification_A=1.0

# notifications corners roundness
Notification_Rounding=10.0
# horizontal (x) and vertical (y) margins for the notifications
Notification_Margin_x=5.0
Notification_Margin_y=5.0

# duration/timing for various notification types (in seconds)
# duration of notification animation in seconds. Set to 0 to disable
Notification_Animation=0.35
# duration of achievement progress indication
Notification_Duration_Progress=6.0
# duration of achievement unlocked
Notification_Duration_Achievement=7.0
# duration of friend invitation
Notification_Duration_Invitation=8.0
# duration of chat message
Notification_Duration_Chat=4.0

# format for the achievement unlock date/time, limited to 79 characters
# if the output formatted string exceeded this limit, the builtin format will be used
# look for the format here: https://en.cppreference.com/w/cpp/chrono/c/strftime
# default=%Y/%m/%d - %H:%M:%S
Achievement_Unlock_Datetime_Format=%Y/%m/%d - %H:%M:%S

# main background when you press shift+tab
Background_R=0.12
Background_G=0.11
Background_B=0.11
Background_A=0.55

Element_R=0.30
Element_G=0.32
Element_B=0.40
Element_A=1.0

ElementHovered_R=0.278
ElementHovered_G=0.393
ElementHovered_B=0.602
ElementHovered_A=1.0

ElementActive_R=-1.0
ElementActive_G=-1.0
ElementActive_B=-1.0
ElementActive_A=-1.0

# ############################# #
# available options:
# top_left
# top_center
# top_right
# bot_left
# bot_center
# bot_right

# position of achievements
PosAchievement=bot_right
# position of invitations
PosInvitation=top_right
# position of chat messages
PosChatMsg=top_center
# ############################# #

# ############################# #
# FPS background color
Stats_Background_R=0.0
Stats_Background_G=0.0
Stats_Background_B=0.0
Stats_Background_A=0.6

# FPS text color
Stats_Text_R=0.8
Stats_Text_G=0.7
Stats_Text_B=0.0
Stats_Text_A=1.0

# FPS position in percentage [0.0, 1.0]
# X=0.0 : left
# X=1.0 : right
Stats_Pos_x=0.0

# Y=0.0 : up
# Y=1.0 : down
Stats_Pos_y=0.0
# ############################# #
"""
    
    with open(ini_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("Created configs.overlay.ini.disabled")


def _tools_file(name):
    return os.path.join(BASE_PATH, "Tools", name)


def _append_config_line(path, value):
    """Append a value on its own line to a config file (keeps the template/comments)."""
    try:
        existing = ""
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                existing = f.read()
        with open(path, 'a', encoding='utf-8') as f:
            if existing and not existing.endswith("\n"):
                f.write("\n")
            f.write(value + "\n")
        return True
    except OSError as e:
        print(f"Could not write {path}: {e}")
        return False


def prompt_first_run_setup():
    """First run only: if no Steam Web API key / personal Steam ID is set yet,
    offer to add them (with instructions), and explain how to add them later
    if skipped. A marker file makes this run only once."""
    marker = _tools_file(".setup_done")
    if os.path.exists(marker):
        return

    key_file = _tools_file("steam_webapi_key.txt")
    ids_file = _tools_file("my_steam_ids.txt")
    need_key = not load_webapi_key()
    need_id = not _read_owner_id_file(ids_file)
    if not need_key and not need_id:
        return

    print()
    print("============================================")
    print("  First-time setup (shown once)")
    print("============================================")

    if need_key:
        print()
        print("A Steam Web API key lets this tool grab achievements & stats for ANY")
        print("game directly by AppID -- the most reliable method. It's free:")
        print("  1. Open https://steamcommunity.com/dev/apikey  (sign in)")
        print("  2. Enter any domain (e.g. localhost) and agree")
        print("  3. Copy the key it shows you")
        print()
        answer = _safe_input("Paste your Steam Web API key now (or press Enter to skip): ").strip()
        if answer:
            if _append_config_line(key_file, answer):
                print("Saved! Reliable achievement fetching is now enabled.")
        else:
            print("No problem. To add it later, paste your key on a line in:")
            print(f"   {key_file}")

    if need_id:
        print()
        print("Optional: add your own SteamID64 so games you've PLAYED get looked up")
        print("first during the fallback owner scan (a small speed-up).")
        print("Find your 17-digit SteamID64 at steamid.io or steamdb.info/calculator.")
        print()
        answer = _safe_input("Enter your SteamID64 now (or press Enter to skip): ").strip()
        if answer.isdigit() and len(answer) >= 17:
            if _append_config_line(ids_file, answer):
                print("Saved!")
        elif answer:
            print("That doesn't look like a 17-digit SteamID64 -- skipping.")
            print(f"   Add it later (one per line) in: {ids_file}")
        else:
            print("No problem. To add it later, put it on a line (one per line) in:")
            print(f"   {ids_file}")

    try:
        with open(marker, 'w', encoding='utf-8') as f:
            f.write("first-run setup shown\n")
    except OSError:
        pass
    print()


# Main execution
prompt_first_run_setup()
user_options = prompt_user_options()

for appid in appids:
    print(f"\nProcessing AppID {appid}")

    out_dir = "steam_settings"

    try:
        os.makedirs(out_dir, exist_ok=True)
    except PermissionError:
        print()
        print("ERROR: Access denied creating the 'steam_settings' folder here:")
        print(f"   {os.path.abspath(out_dir)}")
        print()
        print("This means the destination isn't writable. Common causes:")
        print("  - the game folder (or a parent) is set to Read-only,")
        print("  - the game is under a protected path like Program Files, or")
        print("  - the tool was launched in a protected dir (e.g. System32).")
        print()
        print("Fix: clear Read-only on the game folder (right-click ->")
        print("Properties -> uncheck Read-only), or move the game somewhere")
        print("writable, then run this option again.")
        print()
        _safe_input("Press Enter to exit...")
        raise SystemExit(1)

    print(f"Outputting config to {os.path.abspath(out_dir)}")

    raw = client.get_product_info(apps=[appid])
    game_info = raw["apps"][appid]

    if "common" in game_info:
        game_name = game_info["common"].get("name")
        if game_name:
            print(f"Game: {game_name} ({appid})")
        try:
            generate_achievement_stats(client, appid, out_dir)
        except Exception as e:
            print(f"Unhandled exception during achievement stats generation for appid {appid}: {e}")

    with open(os.path.join(out_dir, "steam_appid.txt"), 'w') as f:
        f.write(str(appid))
    print(f"Created steam_appid.txt with appid {appid}")

    dlc_config_list = []
    dlc_list, depot_app_list = get_dlc(game_info)
    
    if len(dlc_list) > 0:
        print(f"Fetching info for {len(dlc_list)} DLCs...")
        dlc_raw = client.get_product_info(apps=dlc_list)["apps"]
        for dlc in dlc_raw:
            try:
                dlc_config_list.append((dlc, dlc_raw[dlc]["common"]["name"]))
            except:
                dlc_config_list.append((dlc, None))

    generate_configs_app_ini(out_dir, dlc_config_list)
    generate_configs_user_ini(out_dir, user_options)
    generate_configs_overlay_ini(out_dir)

    print(f"\nSteam settings generation complete for appid {appid}")
    print("Files created in steam_settings/ folder:")
    print("  - steam_appid.txt")
    print("  - achievements.json (if available)")
    print("  - stats.json (if available)")
    print("  - images/ folder (achievement icons)")
    print("  - configs.app.ini (DLC configuration)")
    print("  - configs.user.ini (user settings)")
    print("  - configs.overlay.ini.disabled (rename to enable overlay)")
