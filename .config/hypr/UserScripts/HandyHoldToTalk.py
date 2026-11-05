#!/usr/bin/env python3
"""Hold to talk for Handy: start now, stop once every key of the combo is released.

Hyprland's release binds can't do this: they don't fire reliably if Ctrl or Super
comes up before the main key. So read the real key state from evdev instead
(needs membership of the `input` group).

Wait for all the keys, not just the first: Handy pastes right after stopping, and
a paste with Ctrl or Super still down would reach Hyprland's binds, not the window.
"""
import fcntl
import os
import re
import subprocess
import sys
import time

TOGGLE = [os.path.expanduser("~/AppImages/handy.appimage"), "--toggle-transcription"]
CTRL = {29, 97}     # KEY_LEFTCTRL, KEY_RIGHTCTRL
SUPER = {125, 126}  # KEY_LEFTMETA, KEY_RIGHTMETA
Y = {21, 44}        # KEY_Y, KEY_Z: the letter Y is on KEY_Z on a German layout
EVIOCGKEY = 0x80000000 | (96 << 16) | (ord("E") << 8) | 0x18  # 768 key bits
MAX_HOLD_SECONDS = 600  # stop anyway if key state is ever misread


def keyboards():
    with open("/proc/bus/input/devices") as f:
        blocks = f.read().split("\n\n")
    names = [m for b in blocks if "kbd" in b for m in re.findall(r"event\d+", b)]
    fds = []
    for name in names:
        try:
            fds.append(os.open(f"/dev/input/{name}", os.O_RDONLY | os.O_NONBLOCK))
        except OSError:
            pass
    return fds


def held(fds):
    keys = set()
    for fd in fds:
        buf = bytearray(96)
        try:
            fcntl.ioctl(fd, EVIOCGKEY, buf)
        except OSError:
            continue  # keyboard unplugged mid-hold
        keys |= {i for i in range(768) if buf[i // 8] >> (i % 8) & 1}
    return keys


def main():
    # Only one hold at a time; a second copy would toggle out of step.
    lock = os.open(f"{os.environ['XDG_RUNTIME_DIR']}/handy-hold.lock", os.O_CREAT | os.O_WRONLY)
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return

    fds = keyboards()
    subprocess.run(TOGGLE)
    deadline = time.monotonic() + MAX_HOLD_SECONDS
    while time.monotonic() < deadline:
        if not held(fds) & (CTRL | SUPER | Y):
            break
        time.sleep(0.02)
    subprocess.run(TOGGLE)


if __name__ == "__main__":
    sys.exit(main())
