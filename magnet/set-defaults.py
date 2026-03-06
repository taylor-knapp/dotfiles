#!/usr/bin/env python3
"""Patch Magnet's horizontalCommands with custom overrides."""

import json
import plistlib
import subprocess
import sys

DOMAIN = "com.crowdcafe.windowmagnet"
KEY = "horizontalCommands"

# --- Custom overrides ---
# Each key matches a command "name" field. Values are patched into the
# matching command's targetArea.area.segments[0]. If the command doesn't
# exist, it's skipped with a warning (add new custom commands separately).
FRAME_OVERRIDES = {
    "command:default.name.rightTwoThirds": [[5, 0], [19, 12]],
    "iTerm": [[5, 0], [19, 8]],
}


def read_plist():
    """Read full Magnet plist."""
    raw = subprocess.check_output(["defaults", "export", DOMAIN, "-"])
    return plistlib.loads(raw)


def write_plist(plist):
    """Write full plist back to Magnet's domain."""
    data = plistlib.dumps(plist, fmt=plistlib.FMT_XML)
    subprocess.run(["defaults", "import", DOMAIN, "-"], input=data, check=True)


def main():
    plist = read_plist()
    raw_commands = plist.get(KEY)
    if not raw_commands:
        print(f"No {KEY} found in {DOMAIN}. Is Magnet installed?", file=sys.stderr)
        sys.exit(1)

    commands = json.loads(raw_commands)
    name_index = {cmd.get("name"): i for i, cmd in enumerate(commands)}

    for name, frame in FRAME_OVERRIDES.items():
        if name not in name_index:
            print(f"Warning: '{name}' not found, skipping", file=sys.stderr)
            continue
        cmd = commands[name_index[name]]
        segments = cmd.get("targetArea", {}).get("area", {}).get("segments", [])
        if segments:
            segments[0]["frame"] = frame
            print(f"Patched: {name} -> {frame}")
        else:
            print(f"Warning: '{name}' has no segments, skipping", file=sys.stderr)

    plist[KEY] = json.dumps(commands).encode()
    write_plist(plist)
    print("Done. Restart Magnet to apply changes.")


if __name__ == "__main__":
    main()
