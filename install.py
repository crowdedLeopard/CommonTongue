#!/usr/bin/env python3
r"""
Install the chat translator into World of Warcraft.

  python install.py                 install into the default Forever folder
  python install.py --wow "D:\Games\World of Warcraft\_forever_"
  python install.py --slots 0       addon only, without live translation slots
  python install.py --uninstall     remove the addon and its slots again

What it does
  1. Copies the addon folder (next to this script) into  <wow>\Interface\AddOns.
     An existing Learned.lua (the translation memory written by the companion)
     is kept. The copy goes to a temporary folder first and is swapped in only
     when complete, so a failed copy never leaves a half-installed addon.
  2. Creates the live translation "slot" addons beside it. Each is a tiny
     load-on-demand addon the companion program writes translations into; the
     main addon loads one whenever it needs a fresh translation. They do
     nothing by themselves and are grouped under the main addon in the game's
     AddOn list. Their interface number is read from the addon's own TOC.

Start the game (or type /reload) afterwards so it sees the new addons.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_WOW = r"C:\Program Files (x86)\World of Warcraft\_forever_"
DEFAULT_SLOTS = 200
MAX_SLOTS = 999


def find_addon() -> tuple[str, str]:
    """Return (name, path) of the addon folder next to this script: the
    folder whose name matches its .toc file."""
    for name in sorted(os.listdir(HERE)):
        path = os.path.join(HERE, name)
        if os.path.isdir(path) and os.path.isfile(os.path.join(path, name + ".toc")):
            return name, path
    raise SystemExit("No addon folder found next to install.py")


def toc_interface(toc_path: str) -> str:
    """The ## Interface number of a TOC file."""
    with open(toc_path, encoding="utf-8") as fh:
        m = re.search(r"^## Interface:\s*(\d+)", fh.read(), re.M)
    if not m:
        raise SystemExit(f"{toc_path} has no ## Interface line")
    return m.group(1)


def slot_name(addon: str, index: int) -> str:
    return f"{addon}_Slot_{index:03d}"


def remove_slots(addons_dir: str, addon: str) -> int:
    """Delete every slot addon of this addon. Returns how many were removed."""
    removed = 0
    prefix = addon + "_Slot_"
    for name in os.listdir(addons_dir):
        if name.startswith(prefix) and name[len(prefix):].isdigit():
            shutil.rmtree(os.path.join(addons_dir, name), ignore_errors=True)
            removed += 1
    return removed


def install_addon(source: str, target: str, addon: str) -> int:
    """Copy the addon folder into place, keeping an existing translation
    memory. Returns the number of files installed."""
    learned = None
    learned_path = os.path.join(target, "Learned.lua")
    if os.path.isfile(learned_path):
        with open(learned_path, encoding="utf-8") as fh:
            learned = fh.read()

    staging = target + ".new"
    if os.path.isdir(staging):
        shutil.rmtree(staging)
    shutil.copytree(source, staging, ignore=shutil.ignore_patterns("*.tmp", "*.bak", "__pycache__", "Thumbs.db"))
    if learned and ":Learn(" in learned:
        with open(os.path.join(staging, "Learned.lua"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(learned)

    # the file list may name languages that are not shipped (yet): drop those lines
    toc = os.path.join(staging, addon + ".toc")
    with open(toc, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    kept = []
    for line in lines:
        entry = line.strip()
        if entry and not entry.startswith("#") and not os.path.isfile(os.path.join(staging, entry.replace("\\", os.sep))):
            continue
        kept.append(line)
    with open(toc, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(kept) + "\n")

    # swap: the old copy disappears only once the new one is complete
    old = target + ".old"
    if os.path.isdir(old):
        shutil.rmtree(old)
    if os.path.isdir(target):
        os.rename(target, old)
    os.rename(staging, target)
    if os.path.isdir(old):
        shutil.rmtree(old, ignore_errors=True)
    return sum(len(f) for _, _, f in os.walk(target))


def create_slots(addons_dir: str, addon: str, count: int, interface: str) -> int:
    """Create the live translation slot addons. Returns how many old ones were replaced."""
    old = remove_slots(addons_dir, addon)
    for i in range(count):
        name = slot_name(addon, i)
        folder = os.path.join(addons_dir, name)
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, name + ".toc"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(
                f"## Interface: {interface}\n"
                f"## Title: {addon} live slot {i:03d}\n"
                f"## Notes: Carries live translations from the {addon} companion into the game. Loaded on demand; does nothing by itself.\n"
                "## LoadOnDemand: 1\n"
                f"## Dependencies: {addon}\n"
                f"## Group: {addon}\n"
                f"## Category: {addon} live translation\n"
                "\n"
                "data.lua\n")
        with open(os.path.join(folder, "data.lua"), "w", encoding="utf-8", newline="\n") as fh:
            fh.write("-- empty until the companion writes a translation here\n")
    return old


def main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(description="Install the chat translator addon")
    ap.add_argument("--wow", default=DEFAULT_WOW, help="WoW flavour folder (default: %(default)s)")
    ap.add_argument("--slots", type=int, default=DEFAULT_SLOTS,
                    help=f"number of live translation slots (default {DEFAULT_SLOTS}; 0 = none)")
    ap.add_argument("--uninstall", action="store_true",
                    help="remove the addon and its slots from the game folder (the companion's "
                         "translation memory in %%APPDATA%% is kept)")
    args = ap.parse_args(argv)

    addon, source = find_addon()
    addons_dir = os.path.join(args.wow, "Interface", "AddOns")
    if not os.path.isdir(args.wow):
        raise SystemExit(f"WoW folder not found: {args.wow}\nPass the right one with --wow")
    os.makedirs(addons_dir, exist_ok=True)
    target = os.path.join(addons_dir, addon)

    if args.uninstall:
        n = remove_slots(addons_dir, addon)
        if os.path.isdir(target):
            shutil.rmtree(target)
        print(f"Removed {addon} and {n} slot addons from {addons_dir}")
        return

    if not 0 <= args.slots <= MAX_SLOTS:
        raise SystemExit(f"--slots must be between 0 and {MAX_SLOTS}")

    files = install_addon(source, target, addon)
    print(f"Installed {addon} ({files} files) into {target}")

    interface = toc_interface(os.path.join(source, addon + ".toc"))
    old = create_slots(addons_dir, addon, args.slots, interface)
    if args.slots:
        print(f"Created {args.slots} live translation slots" + (f" (replaced {old})" if old else ""))
    print("\nDone. Start the game, or type /reload if it is already running.")
    print("For live machine translation, start the companion as well (see README).")


if __name__ == "__main__":
    try:
        main()
    except PermissionError as exc:
        print(f"Could not write to the game folder: {exc}\nClose the game or run this from an administrator prompt.")
        sys.exit(1)
