#!/usr/bin/env python3
"""Keybindings cheat sheet pane (SUPER + K). Replaces scripts/KeyHints.sh,
a yad table with a hand-maintained copy of the binds that drifted from the
real config.

The truth is read from hypr/keybinds.lua + keybinds_laptop.lua: the files
are executed with `lua` against a stub `hl` object that records every
hl.bind() call (key, dispatcher path, args, source line). `hyprctl binds`
can't be used instead -- with the Lua config every bind reports its
dispatcher as "__lua". The source is then read for the `---- SECTION ----`
headers and the trailing `-- comment` on a bind line, which becomes the
description when present.

  KeybindsPane.py           open/close the pane (see pane.py)
  KeybindsPane.py --dump    print the parsed binds as text (debugging)
"""

import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pane import Pane  # noqa: E402

HYPR = os.path.expanduser("~/.config/hypr")
FILES = [f"{HYPR}/keybinds.lua", f"{HYPR}/keybinds_laptop.lua"]

STUB = r'''
local out = {}
local function ser(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "table" and depth < 3 then
        if v.__path then return string.format("%q", "<" .. v.__path .. ">") end
        local parts = {}
        if #v > 0 then
            for _, x in ipairs(v) do parts[#parts + 1] = ser(x, depth + 1) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for k, x in pairs(v) do parts[#parts + 1] = string.format("%q", tostring(k)) .. ":" .. ser(x, depth + 1) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return string.format("%q", "<" .. t .. ">")
end
local function proxy(path)
    return setmetatable({ __path = path }, {
        __index = function(_, k) if k == "__path" then return path end return proxy(path .. "." .. k) end,
        __call = function(_, ...) return { __path = path, __args = { ... } } end,
    })
end
hl = { dsp = proxy("dsp") }
function hl.bind(key, action, opts)
    local info = debug.getinfo(2, "Sl")
    local path, args = "?", {}
    if type(action) == "table" then path, args = action.__path or "?", action.__args or {}
    elseif type(action) == "function" then path = "function" end
    out[#out + 1] = string.format('{"key":%s,"path":%s,"args":%s,"file":%s,"line":%d}',
        ser(key), ser(path), "[" .. (function() local p = {} for i, a in ipairs(args) do p[i] = ser(a) end return table.concat(p, ",") end)() .. "]",
        ser(info.short_src), info.currentline)
end
setmetatable(hl, { __index = function() return function() end end })
for i = 1, #arg do dofile(arg[i]) end
print(table.concat(out, "\n"))
'''

MOD_NAMES = {"SUPER": "\U000F05B3 Super", "SHIFT": "Shift", "CTRL": "Ctrl", "ALT": "Alt"}  # md-microsoft_windows
KEY_NAMES = {
    "left": "←", "right": "→", "up": "↑", "down": "↓", "Return": "Enter", "Space": "Space", "Tab": "Tab",
    "Escape": "Esc", "Print": "PrtSc", "period": ".", "comma": ",", "bracketleft": "[", "bracketright": "]",
    "mouse_down": "Scroll ↓", "mouse_up": "Scroll ↑", "mouse:272": "LMB", "mouse:273": "RMB",
    "XF86AudioRaiseVolume": "Vol +", "XF86AudioLowerVolume": "Vol −", "XF86AudioMute": "Mute",
    "XF86AudioMicMute": "Mic mute", "XF86AudioPlay": "Play", "XF86AudioPause": "Pause", "XF86AudioNext": "Next",
    "XF86AudioPrev": "Prev", "XF86AudioStop": "Stop", "XF86Sleep": "Sleep", "XF86RFKill": "Airplane",
    "XF86MonBrightnessUp": "Brightness +", "XF86MonBrightnessDown": "Brightness −",
    "XF86KbdBrightnessUp": "Kbd light +", "XF86KbdBrightnessDown": "Kbd light −", "XF86TouchpadToggle": "Touchpad",
}
DIRS = {"l": "left", "r": "right", "u": "up", "d": "down"}

# exec_cmd commands -> readable text (after stripping the scripts dir)
CMD_DESC = {
    "hyprctl reload": "Reload Hyprland config", "kitty": "Terminal (kitty)", "zeditor": "Editor (Zed)",
    "brave": "Browser (Brave)", "thunderbird": "Mail (Thunderbird)", "obsidian": "Obsidian",
    "KdeApp.sh dolphin": "Files (Dolphin)", "stacer": "Stacer", "exit 0": "Exit Hyprland",
    "LockScreen.sh": "Lock screen", "Wlogout.sh": "Logout menu", "workspaceopt allfloat": "Toggle all-floating workspace",
    "splitratio 0.3": "Split ratio 0.3", "systemctl suspend": "Suspend", "AirplaneMode.sh": "Airplane mode",
    "Volume.sh --inc": "Volume up", "Volume.sh --dec": "Volume down", "Volume.sh --toggle": "Mute",
    "Volume.sh --toggle-mic": "Mute microphone", "MediaCtrl.sh --pause": "Play / pause",
    "MediaCtrl.sh --nxt": "Next track", "MediaCtrl.sh --prv": "Previous track", "MediaCtrl.sh --stop": "Stop playback",
    "ScreenShot.sh --now": "Screenshot", "ScreenShot.sh --area": "Screenshot area", "ScreenShot.sh --in5": "Screenshot in 5 s",
    "ScreenShot.sh --in10": "Screenshot in 10 s", "ScreenShot.sh --active": "Screenshot active window",
    'grim -g "$(slurp)" - | swappy -f -': "Screenshot area → swappy", "Brightness.sh --inc": "Brightness up",
    "Brightness.sh --dec": "Brightness down", "BrightnessKbd.sh --inc": "Keyboard light up",
    "BrightnessKbd.sh --dec": "Keyboard light down", "TouchPad.sh": "Toggle touchpad",
    "WallpaperSelect.sh": "Wallpaper picker", "WallpaperRandom.sh": "Random wallpaper",
    "KeybindsPane.py": "This cheat sheet", "PowerPane.py": "Power pane", "QuickSettings.py": "Quick settings",
}


def parse():
    stub = os.path.expanduser("~/.cache/rbn/keybinds_stub.lua")
    os.makedirs(os.path.dirname(stub), exist_ok=True)
    with open(stub, "w") as f:
        f.write(STUB)
    out = subprocess.run(["lua", stub] + [f for f in FILES if os.path.exists(f)],
                         capture_output=True, text=True, timeout=10)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or "lua failed")
    binds = []
    for line in out.stdout.splitlines():
        if line.strip():
            # lua %q escapes newlines as "\<newline>" -- not valid JSON
            binds.append(json.loads(line.replace("\\\n", "\\n")))
    sources = {}
    for b in binds:
        src = b["file"]
        if src not in sources:
            try:
                with open(src) as f:
                    sources[src] = f.read().splitlines()
            except OSError:
                sources[src] = []
        lines = sources[src]
        # section = nearest "---- NAME ----" header above the bind
        b["section"] = "Laptop" if src.endswith("keybinds_laptop.lua") else "Other"
        for i in range(b["line"] - 1, -1, -1):
            m = re.match(r"\s*---- (.+?) ----\s*$", lines[i]) if i < len(lines) else None
            if m:
                b["section"] = m.group(1).title().replace("/", " / ")
                break
        # trailing comment on the bind line
        text = lines[b["line"] - 1] if b["line"] - 1 < len(lines) else ""
        m = re.search(r"\)\s*--\s*(.+?)\s*$", text)
        b["comment"] = m.group(1) if m else ""
    return binds


def describe(b):
    if b["comment"]:
        return b["comment"][0].upper() + b["comment"][1:]
    path, args = b["path"], b["args"]
    a = args[0] if args else None
    d = a if isinstance(a, dict) else {}
    ws = d.get("workspace")
    if path == "dsp.exec_cmd":
        cmd = str(a)
        cmd = re.sub(r"^\S*/(?:scripts|UserScripts)/", "", cmd)
        cmd = re.sub(r"^hyprctl dispatch ", "", cmd)
        if cmd.startswith("pkill rofi || rofi -show drun"):
            return "App launcher (rofi)"
        m = re.match(r"^resizeactive (-?\d+) (-?\d+)$", cmd)
        if m:
            x, y = int(m.group(1)), int(m.group(2))
            return "Resize window " + ("←" if x < 0 else "→" if x > 0 else "↑" if y < 0 else "↓")
        return CMD_DESC.get(cmd, cmd)
    if path == "dsp.window.float":
        return "Toggle floating"
    if path == "dsp.window.fullscreen":
        return "Fullscreen"
    if path == "dsp.window.kill":
        return "Kill window"
    if path == "dsp.window.close":
        return "Close window"
    if path == "dsp.window.pseudo":
        return "Pseudo-tile (dwindle)"
    if path == "dsp.window.move":
        if "direction" in d:
            return f"Move window {DIRS.get(d['direction'], d['direction'])}"
        if ws == "special":
            return "Move window to scratchpad"
        silent = "  (stay)" if d.get("follow") is False else ""
        return f"Move window to workspace {ws}{silent}"
    if path == "dsp.window.drag":
        return "Drag window"
    if path == "dsp.window.resize":
        return "Resize window"
    if path == "dsp.group.toggle":
        return "Toggle window group"
    if path == "dsp.group.next":
        return "Next window in group"
    if path == "dsp.layout":
        return f"Layout: {a}"
    if path == "dsp.focus":
        if "direction" in d:
            return f"Focus {DIRS.get(d['direction'], d['direction'])}"
        if isinstance(ws, str) and ws.startswith("m"):
            return "Next workspace (monitor)" if "+" in ws else "Previous workspace (monitor)"
        if isinstance(ws, str) and ws.startswith("e"):
            return "Next workspace" if "+" in ws else "Previous workspace"
        return f"Go to workspace {ws}"
    if path == "dsp.workspace.toggle_special":
        return "Toggle scratchpad"
    return path.replace("dsp.", "") + (f" {a}" if a is not None else "")


def key_parts(key):
    parts = [k.strip() for k in key.split("+")]
    return [MOD_NAMES.get(p, KEY_NAMES.get(p, p)) for p in parts]


def collapse(rows):
    """Fold 'SUPER + 1' .. 'SUPER + 0' style runs into one row."""
    out, seen = [], {}
    for r in rows:
        m = re.match(r"^(.*?)(\d)$", r["key"])
        n = re.sub(r"\d+", "N", r["desc"]) if m else None
        sig = (m.group(1), n) if m else None
        if sig and sig in seen:
            seen[sig]["keys"].append(m.group(2))
            continue
        if sig:
            r = dict(r, keys=[m.group(2)], prefix=m.group(1), tmpl=n)
            seen[sig] = r
        out.append(r)
    for r in out:
        if r.get("keys") and len(r["keys"]) > 2:
            r["key"] = f"{r['prefix']}{r['keys'][0]} … {r['keys'][-1]}"
            r["desc"] = r["tmpl"].replace("N", f"{r['keys'][0]}–{r['keys'][-1]}")
    return out


def load():
    binds = parse()
    sections = {}
    for b in binds:
        sections.setdefault(b["section"], []).append(dict(key=b["key"], desc=describe(b),
                                                          cmd=str(b["args"][0]) if b["path"] == "dsp.exec_cmd" else ""))
    return {name: collapse(rows) for name, rows in sections.items()}


def pane_main():
    css = """
    .kbd { font-size: 11px; }
    .kbd.mod { font-weight: bold; }
    .desc { font-size: 12px; }
    .sec-title { font-size: 11px; font-weight: bold; letter-spacing: 1px; margin-bottom: 4px; }
    """
    pn = Pane("hypr.keybinds-pane", anchor="center", css=css)

    try:
        sections = load()
        error = None
    except Exception as e:  # noqa: BLE001
        sections, error = {}, str(e)

    def build(pn, root):
        Gtk, L = pn.Gtk, pn.label
        head = pn.box(spacing=12)
        head.append(L("Keybindings", "title", valign=Gtk.Align.CENTER))
        head.append(L("from keybinds.lua · keybinds_laptop.lua", "muted small", valign=Gtk.Align.CENTER, hexpand=True))
        entry = Gtk.SearchEntry(placeholder_text="filter…", width_chars=24)
        head.append(entry)
        root.append(head)
        if error:
            root.append(L(f"Could not parse keybinds: {error}", "bad", margin_top=10))
            return

        scroller = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER, propagate_natural_height=True,
                                      propagate_natural_width=True, max_content_height=900, margin_top=10)
        cols = pn.box(spacing=14, valign=Gtk.Align.START)
        scroller.set_child(cols)
        root.append(scroller)

        def render(filter_text=""):
            pn.clear(cols)
            q = filter_text.lower().strip()
            # two columns, balanced by row count, sections kept whole
            visible = []
            for name, rows in sections.items():
                rows = [r for r in rows if not q or q in r["key"].lower() or q in r["desc"].lower() or q in r["cmd"].lower()]
                if rows:
                    visible.append((name, rows))
            columns = [pn.box(vertical=True, spacing=10, hexpand=True, valign=Gtk.Align.START) for _ in range(2)]
            heights = [0, 0]
            for name, rows in visible:
                ci = 0 if heights[0] <= heights[1] else 1     # shorter column takes the next section
                heights[ci] += len(rows) + 2
                card = pn.card(spacing=3)
                card.append(L(name.upper(), "sec-title muted"))
                grid = Gtk.Grid(column_spacing=12, row_spacing=3)
                for i, r in enumerate(rows):
                    chips = pn.box(spacing=3, valign=Gtk.Align.CENTER)
                    for part in key_parts(r["key"]):
                        c = L(part, "kbd", xalign=0.5)
                        if part in MOD_NAMES.values():
                            c.add_css_class("mod")
                        chips.append(c)
                    grid.attach(chips, 0, i, 1, 1)
                    desc = L(r["desc"], "desc", hexpand=True, ellipsize=3, max_width_chars=44)
                    if r["cmd"]:
                        desc.set_tooltip_text(r["cmd"])
                    grid.attach(desc, 1, i, 1, 1)
                card.append(grid)
                columns[ci].append(card)
            for c in columns:
                if c.get_first_child() is not None:
                    cols.append(c)
            if not visible:
                cols.append(L("nothing matches", "muted"))

        render()
        entry.connect("search-changed", lambda e: render(e.get_text()))
        entry.grab_focus()

    pn.run(build)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--dump":
        for name, rows in load().items():
            print(f"== {name}")
            for r in rows:
                print(f"  {r['key']:28} {r['desc']}")
    else:
        pane_main()
