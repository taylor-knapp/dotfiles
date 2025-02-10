local appStateWindowPosition = {} -- Table to track app state and window positions

-- This recreates the hide/un-hide behavior of iTerm, but keeps the window position.
-- Note that apps do not show in the Stage Manager panel on the left.
function toggleAppWithHide(bundleId)
    local frontApp = hs.application.frontmostApplication()

    if frontApp and frontApp:bundleID() == bundleId then
        -- If app is frontmost, hide it and save window positions
        local allWindows = frontApp:allWindows()
        appStateWindowPosition[bundleId] = {}

        for _, window in ipairs(allWindows) do
            if window:isVisible() then
                table.insert(appStateWindowPosition[bundleId], {window = window, frame = window:frame()})
            end
        end

        frontApp:hide()
    else
        -- Restore the app and its window positions
        local app = hs.application.get(bundleId)
        
        if app and appStateWindowPosition[bundleId] then
            -- Set window positions while still hidden
            for _, winData in ipairs(appStateWindowPosition[bundleId]) do
                local window = winData.window
                local frame = winData.frame
                
                if window:isStandard() then
                    window:setFrame(frame)
                end
            end
            
            -- Clear the saved state
            appStateWindowPosition[bundleId] = nil
            
            -- Now unhide and activate
            app:unhide()
            hs.timer.doAfter(0.01, function()
                app:activate()
            end)
        else
            -- Launch or focus the app if not already running
            hs.application.launchOrFocusByBundleID(bundleId)
        end
    end
end

local appStateMinimizeStatus = {} -- Table to track app state by Space ID and bundleId

function getCurrentSpaceID()
    -- Retrieve the current Space ID using hs.spaces
    return hs.spaces.focusedSpace()
end

--- I'm not using this currently because it doesn't work perfectly, but it is pretty close.
function toggleAppWithMinimize(bundleId)
    local currentSpace = getCurrentSpaceID()
    local spaceKey = tostring(currentSpace) .. "_" .. bundleId -- Unique key for Space and app
    local frontApp = hs.application.frontmostApplication()

    if frontApp and frontApp:bundleID() == bundleId then
        local allWindows = frontApp:allWindows()

        if not appStateMinimizeStatus[spaceKey] then
            -- If not minimized, minimize all visible windows
            appStateMinimizeStatus[spaceKey] = "minimized"

            for _, window in ipairs(allWindows) do
                if window:isVisible() then
                    window:minimize()
                end
            end
        else
            -- If minimized, restore all windows
            appStateMinimizeStatus[spaceKey] = nil -- Clear the minimized state

            for _, window in ipairs(allWindows) do
                if window:isMinimized() then
                    window:unminimize()
                end
                window:focus() -- Bring back focus to the restored windows
            end
        end
    else
        -- Launch or focus the app if it's not already frontmost
        hs.application.launchOrFocusByBundleID(bundleId)
        appStateMinimizeStatus[spaceKey] = nil -- Reset state for the app on this Space
    end
end

-- Constants
-- Use control, command, option, and shift as the modifiers
MODIFIERS = {"ctrl", "cmd", "alt", "shift"}

-- App configuration
APPS = {
  {shortcut = "b", name = "Brave Browser", id = "com.brave.Browser"},
  {shortcut = "w", name = "VSCode", id = "com.microsoft.VSCode"},
  {shortcut = "s", name = "Slack", id = "com.tinyspeck.slackmacgap"},
  {shortcut = "a", name = "Obsidian", id = "md.obsidian"},
  {shortcut = "x", name = "Toggl", id = "com.toggl.daneel"},
}

-- Bind application shortcuts
for _, app in ipairs(APPS) do
  hs.hotkey.bind(MODIFIERS, app.shortcut, function()
    hs.application.launchOrFocusByBundleID(app.id)
  end)
end

-- Add shortcut for iTerm2
hs.hotkey.bind({"alt"}, "space", function()
	toggleAppWithHide("com.googlecode.iterm2")
end)

-- Add shortcut to reload hammerspoon configuration
hs.hotkey.bind(MODIFIERS, "r", function()
	hs.reload()
end)
