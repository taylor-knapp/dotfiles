---
name: macos-defaults
description: Find and set macOS app preferences with `defaults read/write`. Use when changing a macOS or app setting via `defaults`, finding a preference key, or when a `defaults write` change doesn't stick.
---

# macOS defaults

- Keys are case-sensitive. Don't guess — find the exact key by diffing the plist around a UI toggle:
  ```sh
  defaults export com.app.id /tmp/before.plist && plutil -convert xml1 /tmp/before.plist
  # toggle the setting in the app's UI
  defaults export com.app.id /tmp/after.plist && plutil -convert xml1 /tmp/after.plist
  diff /tmp/before.plist /tmp/after.plist
  ```
- A running app holds prefs in memory and overwrites `defaults write` changes on quit. Quit the app, write, then relaunch.
