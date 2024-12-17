-- I'm not using this currently, but the goal was to show/hide an app like iTerm2 used to do.
function toggleApp(bundleId)
    local frontApp = hs.application.frontmostApplication()
    if frontApp and frontApp:bundleID() == bundleId then
        hs.window.desktop().focus()
    else
        hs.application.launchOrFocusByBundleID(bundleId)
    end
end

-- Constants
-- Use control, command, option, and shift as the modifiers
MODIFIERS = {"ctrl", "cmd", "alt", "shift"}

-- App configuration
APPS = {
  {shortcut = "space", name = "iTerm", id = "com.googlecode.iterm2", modifiers = {"alt"}},
  {shortcut = "b", name = "Brave Browser", id = "com.brave.Browser"},
  {shortcut = "w", name = "Webstorm", id = "com.jetbrains.WebStorm"},
  {shortcut = "s", name = "Slack", id = "com.tinyspeck.slackmacgap"},
  {shortcut = "a", name = "Obsidian", id = "md.obsidian"},
  {shortcut = "x", name = "Toggl", id = "com.toggl.daneel"},
}

-- Bind application shortcuts
for _, app in ipairs(APPS) do
  hs.hotkey.bind(app.modifiers or MODIFIERS, app.shortcut, function()
    hs.application.launchOrFocusByBundleID(app.id)
  end)
end
