#!/usr/bin/env python3
"""Set iTerm2 tab title to show only session name (no job suffix).

Uses the iterm2 PyPI package via gw-layout's venv (WebSocket connection).
Requires EnableAPIServer = true in iTerm preferences.
"""
import os
import subprocess
import sys

VENV_DIR = os.path.expanduser("~/.local/venvs/gw-layout")
VENV_PYTHON = os.path.join(VENV_DIR, "bin", "python3")

def ensure_venv():
    if sys.prefix != sys.base_prefix:
        return
    if not os.path.isfile(VENV_PYTHON):
        print("iterm: creating venv and installing iterm2 package...", file=sys.stderr)
        subprocess.check_call([sys.executable, "-m", "venv", VENV_DIR])
        subprocess.check_call([VENV_PYTHON, "-m", "pip", "install", "-q", "iterm2"])
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv)

ensure_venv()

import asyncio
import iterm2

async def main():
    connection = await iterm2.Connection.async_create()
    app = await iterm2.async_get_app(connection)
    for profile in await iterm2.PartialProfile.async_query(connection):
        full = await profile.async_get_full_profile()
        await full.async_set_title_components([iterm2.TitleComponents.SESSION_NAME])

asyncio.run(main())
