#!/usr/bin/env python3
"""Battery / power pane for waybar's battery + power_mode modules.

  PowerPane.py          open/close the pane (see pane.py for the scaffold)

Shows: charge, time left, draw, health (charge_full vs design), CPU /
thermals, the Hyprland blur "power mode" (PowerMode.sh
auto/performance/powersave), and the TUXEDO Control Center profile +
charging profile via tccd's D-Bus API (com.tuxedocomputers.tccd, the same
calls scripts/powerprofiles.sh makes; SetTempProfileById -- SetTempProfile
returns true but does nothing on tccd 3.0.9). tuxedo-control-center itself
is the footer button.

Nothing here runs in the background: every reading is taken when the pane
opens (and every 10 s while it stays open). A 5-minute charge-history
sampler existed briefly (battery-log.timer) and was removed on request --
no measurements unless the bar is clicked.
"""

import json
import os
import subprocess
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pane import Pane, sh, spawn, poke_waybar, clean_env  # noqa: E402

BAT = "/sys/class/power_supply/BAT0"
AC = "/sys/class/power_supply/AC0"
SCRIPTS = os.path.expanduser("~/.config/hypr/scripts")
MODE_FILE = os.path.expanduser("~/.cache/.power_mode")   # PowerModeCommon.sh

TCC = ("com.tuxedocomputers.tccd", "/com/tuxedocomputers/tccd", "com.tuxedocomputers.tccd")
PRETTY_PROFILE = {   # tccd's built-in profiles carry internal ids as names
    "__profile_max_energy_save__": "Max Energy Save",
    "__profile_silent__": "Silent",
    "__office__": "Office",
}

# Nerd Font glyphs (names verified against the installed JetBrainsMono Nerd Font)
BAT_ICONS = ["\U000F008E", "\U000F007A", "\U000F007B", "\U000F007C", "\U000F007D", "\U000F007E",
             "\U000F007F", "\U000F0080", "\U000F0081", "\U000F0082", "\U000F0079"]  # md-battery_outline, md-battery_10..90, md-battery
BAT_CHARGING = "\U000F0084"   # md-battery_charging
PLUG = "\U000F06A5"           # md-power_plug
FLASH = "\U000F0241"          # md-flash
LEAF = "\U000F032A"           # md-leaf
AUTO = "\U000F006A"           # md-autorenew
CHIP = "\U000F061A"           # md-chip
FAN = "\U000F0210"            # md-fan
THERMO = "\U000F050F"         # md-thermometer
HEART = "\U000F02D1"          # md-heart
CLOCK = "\U000F0150"          # md-clock_outline
GAUGE = "\U000F029A"          # md-gauge


# ------------------------------------------------------------------ data --

def sysfs(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def battery():
    b = {k: sysfs(f"{BAT}/{k}") for k in ("status", "capacity", "charge_now", "charge_full", "charge_full_design",
                                          "current_now", "voltage_now", "cycle_count", "technology")}
    b["ac"] = sysfs(f"{AC}/online") == "1"
    v = int(b["voltage_now"] or 0) / 1e6
    i = int(b["current_now"] or 0) / 1e6
    b["watts"] = round(v * i, 1)
    full, design, now = (int(b[k] or 0) for k in ("charge_full", "charge_full_design", "charge_now"))
    b["health"] = round(100 * full / design) if design else None
    b["wh_full"] = round(full / 1e6 * v, 1) if full else None
    b["wh_design"] = round(design / 1e6 * v, 1) if design else None
    # time estimate from current draw (upower does the same, smoothed)
    b["time"] = None
    if i > 0:
        if b["status"] == "Discharging":
            b["time"] = now / 1e6 / i
        elif b["status"] == "Charging" and full > now:
            b["time"] = (full - now) / 1e6 / i
    return b


def fmt_hours(h):
    m = int(round(h * 60))
    return f"{m // 60} h {m % 60:02d} min" if m >= 60 else f"{m} min"


def cpu():
    base = "/sys/devices/system/cpu/cpu0/cpufreq"
    mhz = []
    try:
        with open("/proc/cpuinfo") as f:
            mhz = [float(l.split(":")[1]) for l in f if l.startswith("cpu MHz")]
    except OSError:
        pass
    return dict(governor=sysfs(f"{base}/scaling_governor", "?"),
                epp=sysfs(f"{base}/energy_performance_preference", "?").replace("_", " "),
                mhz=round(sum(mhz) / len(mhz)) if mhz else None,
                max_mhz=round(int(sysfs(f"{base}/scaling_max_freq", "0")) / 1000))


def tcc_call(method, *args):
    """busctl call -> parsed JSON payload (None if tccd is unreachable)."""
    out = sh(["busctl", "--system", "-j", "call", *TCC, method, *args], timeout=5)
    try:
        data = json.loads(out)["data"][0]
        return json.loads(data) if isinstance(data, str) and data[:1] in "[{" else data
    except (ValueError, KeyError, IndexError, TypeError):
        return None


def tcc():
    profiles = (tcc_call("GetDefaultProfilesJSON") or []) + (tcc_call("GetCustomProfilesJSON") or [])
    if not profiles:
        return None
    active = tcc_call("GetActiveProfileJSON") or {}
    fans = tcc_call("GetFanDataJSON") or {}
    settings = tcc_call("GetSettingsJSON") or {}
    return dict(
        profiles=[dict(id=p.get("id"), name=PRETTY_PROFILE.get(p.get("name"), p.get("name")),
                       fan=p.get("fan", {}).get("fanProfile"), maxf=p.get("cpu", {}).get("scalingMaxFrequency"),
                       tdp=p.get("odmPowerLimits", {}).get("tdpValues")) for p in profiles],
        active_id=active.get("id"), active_name=PRETTY_PROFILE.get(active.get("name"), active.get("name")),
        cpu_temp=fans.get("cpu", {}).get("temp", {}).get("data"),
        fan_speed=fans.get("cpu", {}).get("speed", {}).get("data"),
        charging_profiles=tcc_call("GetChargingProfilesAvailable") or [],
        charging_profile=tcc_call("GetCurrentChargingProfile"),
        ac_profile=settings.get("stateMap", {}).get("power_ac"),
        bat_profile=settings.get("stateMap", {}).get("power_bat"),
    )


def power_mode():
    m = sysfs(MODE_FILE, "auto")
    return m if m in ("performance", "powersave") else "auto"


# ------------------------------------------------------------------ pane --

def pane_main():
    css = """
    .hero-icon { font-size: 56px; margin-right: 4px; }
    .hero-pct  { font-size: 40px; font-weight: bold; }
    .stat-icon { font-size: 15px; min-width: 22px; }
    .profile-note { font-size: 10px; opacity: 0.75; }
    button.profile-row { padding: 4px 8px; border-radius: 8px; }
    button.profile-row.active { background-color: alpha(currentColor, 0.15); color: inherit; }
    """
    pn = Pane("hypr.power-pane", anchor="right", css=css, width=560)
    pending = {"id": None}

    def build(pn, root):
        Gtk, L = pn.Gtk, pn.label
        b, c, t, mode = battery(), cpu(), tcc(), power_mode()
        pct = int(b["capacity"] or 0)
        charging = b["status"] == "Charging"

        # -- header
        head = pn.box(spacing=20)
        icon = BAT_CHARGING if charging else BAT_ICONS[min(10, pct // 10)]
        cls = "good" if charging or pct > 30 else ("warm" if pct > 15 else "bad")
        head.append(L(icon, f"hero-icon {cls}", valign=Gtk.Align.CENTER))
        col = pn.box(vertical=True, valign=Gtk.Align.CENTER)
        col.append(L(f"{pct} %", "hero-pct"))
        if b["status"] == "Full" or (b["ac"] and not charging):
            state = "Plugged in" + (", fully charged" if pct >= 98 else "")
        elif charging:
            state = "Charging" + (f"  ·  {fmt_hours(b['time'])} to full" if b["time"] else "")
        else:
            state = "On battery" + (f"  ·  {fmt_hours(b['time'])} left" if b["time"] else "")
        col.append(L(state))
        col.append(L(f"{b['technology'] or 'Battery'}  ·  {b['wh_full'] or '?'} Wh of {b['wh_design'] or '?'} Wh design", "muted small"))
        head.append(col)
        grid = Gtk.Grid(column_spacing=10, row_spacing=4, halign=Gtk.Align.END, hexpand=True, valign=Gtk.Align.CENTER)
        stats = [
            (FLASH, "Draw", f"{b['watts']} W" + ("  (charging)" if charging else "")),
            (HEART, "Health", f"{b['health']} %" if b["health"] else "n/a"),
            (CLOCK, "Cycles", b["cycle_count"] if b["cycle_count"] not in (None, "0") else "not reported"),
        ]
        for r, (ic, key, val) in enumerate(stats):
            grid.attach(L(ic, "stat-icon accent2", xalign=0.5), 0, r, 1, 1)
            grid.attach(L(key, "muted"), 1, r, 1, 1)
            grid.attach(L(str(val)), 2, r, 1, 1)
        head.append(grid)
        root.append(head)

        # -- cpu / thermals
        root.append(pn.section("System"))
        sysc = pn.card(vertical=False, spacing=18)
        temp = t and t["cpu_temp"]
        fan = t and t["fan_speed"]
        for ic, key, val in [
            (CHIP, "CPU", f"{c['mhz']} MHz" + (f" / {c['max_mhz']} max" if c["max_mhz"] else "") if c["mhz"] else "?"),
            (GAUGE, "Governor", f"{c['governor']}, {c['epp']}"),
            (THERMO, "Temp", f"{temp} °C" if temp not in (None, -1) else "n/a"),
            (FAN, "Fan", f"{fan} %" if fan not in (None, -1) else "auto"),
        ]:
            cell = pn.box(vertical=True)
            cell.append(L(f"{ic}  {key}", "muted small"))
            cell.append(L(val))
            sysc.append(cell)
        root.append(sysc)

        # -- hyprland power mode (blur)
        root.append(pn.section("Desktop power mode  ·  blur"))
        tiles = pn.box(spacing=8, homogeneous=True)

        def set_mode(m):
            subprocess.run([f"{SCRIPTS}/PowerMode.sh", "--set", m], env=clean_env())
            pn.rebuild()
        for m, ic, name, sub in [("auto", AUTO, "Auto", "blur off on battery"),
                                 ("performance", FLASH, "Performance", "blur always on"),
                                 ("powersave", LEAF, "Power saver", "blur always off")]:
            tiles.append(pn.tile(ic, name, mode == m, lambda m=m: set_mode(m), sub))
        root.append(tiles)

        # -- tuxedo control center
        root.append(pn.section("TUXEDO profile"))
        if t is None:
            root.append(L("tccd not reachable (tuxedo-control-center installed? tccd.service running?)", "bad small"))
        else:
            lst = pn.box(vertical=True, spacing=2)
            scroller = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER, propagate_natural_height=True,
                                          max_content_height=190, child=lst)
            scroller.add_css_class("card")

            def set_profile(pid):
                # tccd applies asynchronously (a few seconds); poll until the
                # active profile changed, then redraw
                pending["id"] = pid
                tcc_call("SetTempProfileById", "s", pid)
                pn.rebuild()
                tries = [0]

                def poll():
                    tries[0] += 1
                    cur = tcc_call("GetActiveProfileJSON") or {}
                    if cur.get("id") == pid or tries[0] > 8:
                        pending["id"] = None
                        pn.rebuild()
                        return False
                    return True
                pn.GLib.timeout_add(1000, poll)
            for pr in t["profiles"]:
                active = pr["id"] == t["active_id"] or pr["name"] == t["active_name"]
                bits = []
                if pr["fan"]:
                    bits.append(f"fan {pr['fan'].lower()}")
                if pr["maxf"]:
                    bits.append(f"{pr['maxf'] / 1e6:.1f} GHz")
                if pr["tdp"]:
                    bits.append(f"{pr['tdp'][0]}–{pr['tdp'][-1]} W")
                tag = ""
                if pr["id"] == t["ac_profile"]:
                    tag = "AC default"
                elif pr["id"] == t["bat_profile"]:
                    tag = "battery default"
                row = Gtk.Button()
                row.add_css_class("flat")
                row.add_css_class("profile-row")
                if active:
                    row.add_css_class("active")
                inner = pn.box(spacing=10)
                inner.append(L(FLASH if active else " ", "accent2", xalign=0.5, width_chars=2, valign=Gtk.Align.CENTER))
                col = pn.box(vertical=True, hexpand=True)
                col.append(L(pr["name"] + ("  ·  switching…" if pending["id"] == pr["id"] else "")))
                col.append(L(" · ".join(bits), "profile-note"))
                row.set_child(inner)
                inner.append(col)
                if tag:
                    inner.append(L(tag, "muted small", valign=Gtk.Align.CENTER))
                row.connect("clicked", lambda _b, pid=pr["id"]: set_profile(pid))
                lst.append(row)
            root.append(scroller)
            root.append(L("Temporary override -- tccd goes back to its AC/battery default on the next power source change.", "muted small", margin_top=6))

            if t["charging_profiles"]:
                root.append(pn.section("Charging profile"))
                row = pn.box(spacing=8, homogeneous=True)

                def set_charging(cp):
                    tcc_call("SetChargingProfile", "s", cp)
                    pn.rebuild()
                for cp, sub in [("high_capacity", "charge to 100 %"), ("balanced", "stop around 90 %"), ("stationary", "stop around 80 %")]:
                    if cp in t["charging_profiles"]:
                        row.append(pn.tile(PLUG, cp.replace("_", " ").title(), t["charging_profile"] == cp,
                                           lambda cp=cp: set_charging(cp), sub))
                root.append(row)

        # -- footer
        foot = pn.box(spacing=8, cls="footer")
        foot.append(L(f"Updated {datetime.now():%H:%M:%S}", hexpand=True, valign=Gtk.Align.CENTER))
        foot.append(pn.button("Refresh", pn.rebuild))
        foot.append(pn.button("TUXEDO Control Center", lambda: (spawn(["tuxedo-control-center"]), pn.close())))
        root.append(foot)

        # live refresh while open (draw/temps change); armed once, not per rebuild
        if not getattr(pn, "_ticking", False):
            pn._ticking = True
            pn.every(10000, lambda: (pn.rebuild(), True)[1])

    pn.run(build)


if __name__ == "__main__":
    pane_main()
