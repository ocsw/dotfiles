--
-- See
-- https://github.com/ocsw/system-setup/blob/main/macos/macos.md#hammerspoon
-- and hammers/references.md
--
-- NOTE: KEEP GLOBAL HOTKEYS IN SYNC WITH
-- https://github.com/ocsw/system-setup/blob/main/macos/hotkeys.md
--


-- ########################
-- ##  Config Reloading  ##
-- ########################

configDirs = {
    hs.configdir,
    os.getenv("HOME") .. "/repos/dotfiles/hammerspoon",
    os.getenv("HOME") .. "/.to_back_up/.hammerspoon"
}

-- From https://www.hammerspoon.org/go/#fancyreload, tweaked
function reloadConfig(files)
    local doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
            break
        end
    end
    if doReload then
        hs.reload()
    end
end

configWatchers = {}
for _,dir in pairs(configDirs) do
    configWatchers[dir] = hs.pathwatcher.new(dir, reloadConfig):start()
end

--[[
-- From https://www.hammerspoon.org/go/#simplereload, tweaked
hs.hotkey.bind({"ctrl", "option", "cmd"}, "R", function()
    hs.reload()
end)
--]]

-- hs.alert.show("Config loaded")


-- #######################
-- ##  Global Settings  ##
-- #######################

package.path =
    hs.configdir .. "/hammers/?.lua;" ..
    hs.configdir .. "/hammers/?/init.lua;" ..
    package.path
require("init-local")

--[[
consoleCommandColor():
    Text in input box; default is black
consolePrintColor():
    Text in output box from system and print(); default is a medium magenta
consoleResultColor():
    Text in output box in response to input box; default is a medium cyan
inputBackgroundColor():
    Default is white - but looks medium gray???
outputBackgroundColor():
    Default is white
windowBackgroundColor():
    Default is a light gray
--]]

hs.console.consolePrintColor({white = 0, alpha = 1})


-- #########################
-- ##  Utility Functions  ##
-- #########################

function indent(s)
    s = string.gsub(s, "^", "    ")
    s = string.gsub(s, "\n", "\n    ")
    return s
end


-- ###################################
-- ##  Window & Screen Information  ##
-- ###################################

--
-- ### Calculations ###
--

-- This exists in hs.geometry, but it's handled oddly
function aspectRatio(geom)  -- rect or size -> float
    return geom.w / geom.h
end

function aspectRatioCategory(r)  -- float (ratio) -> string
    -- op, value, result; must be handled in order
    local ratioCategoryDefs = {
        {">", 2.99, "superultrawide"},  -- 3 minus rounding error
        {">", 1.99, "ultrawide"},  -- 2 minus rounding error
        {">", 1.35, "wide"},  -- 4/3 plus rounding error
        {">", 1, "horizontal"},
        {"=", 1, "square"},
        {"<", (1 / 2.99), "superultratall"},
        {"<", (1 / 1.99), "ultratall"},
        {"<", (1 / 1.35), "tall"}
        -- else "vertical"
    }
    local ops = {
        [">"] = function(a, b) return a > b end,
        ["="] = function(a, b) return a == b end,
        ["<"] = function(a, b) return a < b end
    }
    for _,def in ipairs(ratioCategoryDefs) do
        if ops[def[1]](r, def[2]) then return def[3] end
    end
    return "vertical"
end

--
-- ### uBar ###
--

--[[

The goal here is to do the same thing as a screen's frame attribute, relative
to fullFrame - exclude unusable area - but to count the uBar task bar as
unusable, if it's present.

Below is some relevant information, as of macOS 14 (Sonoma) and uBar 4.2.2.

The Dock:

- The Dock has no window, whether it's always shown, hidden, or hidden and
  hovered
- The Dock's width is only counted as unusable when it's always shown (although
  the HS docs say there can be a bit of unusable space when it's hidden)
- (These are also true of the menu bar)

uBar's main window (the taskbar):

- uBar has no taskbar window when it's hidden
- The taskbar window has the same properties when it's visible, whether it's
  always shown or hidden and hovered:
    isMaximizable: nil; isStandard: false
    role: AXWindow; subrole: AXSystemDialog
    title: <screen_id>
- The title matches the screen the window was first created on, not necessarily
  the screen it's currently on (e.g. if Display is set to Main)
- If the taskbar isn't pinned, the window will be 12 pixels away from the
  screen edge it's positioned next to (counting the bottom of the menu bar as
  the top edge of the screen if it's always shown)

uBar's other windows:

- uBar's icon menu has no window
- Hovering over a uBar item can pop up a small label; it shows up as a window
  with these properties:
    isMaximizable: nil; isStandard: false
    role: AXWindow; subrole: AXUnknown
    title: Tooltip
- uBar's Preferences window has these properties:
    isMaximizable: false; isStandard: true
    role: AXWindow; subrole: AXStandardWindow
    title: Preferences

The Dock and uBar together:

- uBar will prevent you from setting the taskbar and the Dock to the same edge
  of the screen, even if both are hidden, unless you check 'Allow the Dock to
  overlap' in the Advanced preferences
- If the Dock is on different edge than the taskbar, we don't need to worry
  about it
- Just in case they actually overlap, we'll make sure that we reduce the usable
  area by whichever is taller/wider, the taskbar or the unusable area reported
  by the system

--]]

-- local P = {}
-- pack = P
-- -- Import Section:
-- -- declare everything this package needs from outside
-- local sqrt = math.sqrt
-- local io = io
-- -- no more external access after this point
-- setfenv(1, P)

ubar = {}

ubar.floatMargin = 20  -- leave some extra room in case it ever changes from 12

function ubar.taskbarForScreen(screen)  -- screen -> window
    local app = hs.application.get("ca.brawer.uBar")
    if not app then
        return nil
    end

    local taskbar = nil
    for _,w in ipairs(app:allWindows()) do
        if w:screen():id() == screen:id() and
            w:isStandard() == false and
            w:role() == "AXWindow" and
            w:subrole() == "AXSystemDialog" and
            string.match(w:title(), "^%d+$") and
            w:isFullScreen() == false and
            w:isVisible() == true then
                taskbar = w
                break  -- there should only ever be one match
        end
    end

    return taskbar
end

-- Returns 'top', 'bottom', 'left', 'right', or 'unknown'
function ubar.screenEdgeOfTaskbar(taskbar)  -- window -> string
    local winFrame = taskbar:frame()
    local winRatio = winFrame.w / winFrame.h  -- avoid circ dep

    if winRatio == 1 then
        return "unknown"
    end

    local screenFrame = taskbar:screen():frame()

    local winEdge1
    local winEdge2
    local screenEdge1
    local screenEdge2

    if winRatio > 1 then
        -- Top / bottom
        winEdge1 = winFrame.y1
        winEdge2 = winFrame.y2
        screenEdge1 = screenFrame.y1
        screenEdge2 = screenFrame.y2
    else
        -- Left / right
        winEdge1 = winFrame.x1
        winEdge2 = winFrame.x2
        screenEdge1 = screenFrame.x1
        screenEdge2 = screenFrame.x2
    end

    local isEdge1 = false
    local isEdge2 = false

    -- Attached to an edge?
    if winEdge1 <= screenEdge1 and winEdge2 >= screenEdge2 then
        return "unknown"
    end
    if winEdge1 <= screenEdge1 then isEdge1 = true end
    if winEdge2 >= screenEdge2 then isEdge2 = true end

    if not isEdge1 and not isEdge2 then
        -- Floating?
        local edge1Dist = winEdge1 - screenEdge1
        local edge2Dist = screenEdge2 - winEdge2
        if edge1Dist <= ubar.floatMargin and edge2Dist <= ubar.floatMargin then
            return "unknown"
        end
        if edge1Dist <= ubar.floatMargin then isEdge1 = true end
        if edge2Dist <= ubar.floatMargin then isEdge2 = true end
    end

    if winRatio > 1 then
        -- Top / bottom
        if isEdge1 then return "top" end
        if isEdge2 then return "bottom" end
    else
        -- Left / right
        if isEdge1 then return "left" end
        if isEdge2 then return "right" end
    end

    return "unknown"
end

--[[
Caveats:

- If Display is set to 'Main' in uBar, whether the taskbar will be subtracted
  from the usable area depends on which screen is currently focused (i.e. which
  screen the taskbar is currently on)

- If uBar is set to autohide, it will be subtracted from the usable area while
  it's hovered (and therefore visible) and ignored while it's not
--]]
function ubar.usableScreenFrame(screen)  -- screen -> rect
    local taskbar = ubar.taskbarForScreen(screen)
    if not taskbar then
        return screen:frame()
    end

    local taskbarEdge = ubar.screenEdgeOfTaskbar(taskbar)
    if taskbarEdge == "unknown" then
        return screen:frame()
    end

    local taskbarFrame = taskbar:frame()
    local screenFrame = taskbar:screen():frame()

    if taskbarEdge == "top" then
        return hs.geometry({
            x1 = screenFrame.x1,
            x2 = screenFrame.x2,
            -- macOS won't actually let you put the Dock on the top edge, so
            -- the max() isn't strictly necessary, but we might as well be safe
            y1 = math.max(taskbarFrame.y2, screenFrame.y1),
            y2 = screenFrame.y2
        })
    end

    if taskbarEdge == "bottom" then
        return hs.geometry({
            x1 = screenFrame.x1,
            x2 = screenFrame.x2,
            y1 = screenFrame.y1,
            y2 = math.min(taskbarFrame.y1, screenFrame.y2)
        })
    end

    if taskbarEdge == "left" then
        return hs.geometry({
            x1 = math.max(taskbarFrame.x2, screenFrame.x1),
            x2 = screenFrame.x2,
            y1 = screenFrame.y1,
            y2 = screenFrame.y2
        })
    end

    if taskbarEdge == "right" then
        return hs.geometry({
            x1 = screenFrame.x1,
            x2 = math.min(taskbarFrame.x1, screenFrame.x2),
            y1 = screenFrame.y1,
            y2 = screenFrame.y2
        })
    end

    -- Should be unreachable
    return screen:frame()
end

--
-- ### Printing ###
--

function pointStringWithLabels(point)
    return "X: " .. point.x .. ", Y: " .. point.y
end

function sizeStringWithLabels(size)
    return "W: " .. size.w .. ", H: " .. size.h
end

function rectStringWithLabels(rect)
    return "X: " .. rect.x .. ", Y: " .. rect.y ..
        ", W: " .. rect.w .. ", H: " .. rect.h
end

function screenStringWithLabelsShort(sc)
    return "name: " .. sc:name() .. ", id: " .. sc:id()
end

function screenStringWithLabelsShortAR(sc)
    return
        "name: " .. sc:name() .. ", id: " .. sc:id() ..
        ", aspectRatio: " ..
            string.format("%.3f", aspectRatio(sc:fullFrame())) ..
        ", category: " ..
            aspectRatioCategory(aspectRatio(sc:fullFrame()))
end

--[[
Some notes:

- On macOS 14 (Sonoma) on Intel:
    - The built-in screen has no serial number (the field is missing)
    - The screen IDs are large random-seeming numbers
    - The ID for a screen can change without a reboot; they seem to be
      specific to both a screen and a set of attached screens
    - IDs seem to stay the same across reboots?

- On macOS 15 (Sequoia) on Apple Silicon:
    - getInfo() returns nil for all screens, so serial numbers are unavailable
    - The screen IDs seem to be a count starting with 1, which is the built-in
      display
    - IDs may not be continuous
    - Switching attached screens can cause IDs to be reused
    - IDs may change across reboots

- On both:
    - The UUID for a monitor differs between machines, but stays the same
      across reboots
--]]
function screenStringWithLabels(sc)
    local serial = "n/a"
    local screenInfo = sc:getInfo()
    if screenInfo and screenInfo.DisplaySerialNumber then
        serial = screenInfo.DisplaySerialNumber
    end
    return
        "aspectRatio: " ..
            string.format("%.3f", aspectRatio(sc:fullFrame())) .. "\n" ..
        "aspectRatioCategory: " ..
            aspectRatioCategory(aspectRatio(sc:fullFrame())) .. "\n" ..
        "frame: " .. rectStringWithLabels(sc:frame()) .. "\n" ..
        "fullFrame: " .. rectStringWithLabels(sc:fullFrame()) .. "\n" ..
        "id: " .. sc:id() .. "\n" ..
        "name: " .. sc:name() .. "\n" ..
        "serial: " .. serial .. "\n" ..
        "usable (uBar): " ..
            rectStringWithLabels(ubar.usableScreenFrame(sc)) .. "\n" ..
        "uuid: " .. sc:getUUID()
end

function applicationStringWithLabels(app)
    return "name: " .. app:name() .. ", bundleID: " .. app:bundleID()
end

function windowStringWithLabels(w)
    return
        "application: " ..
            applicationStringWithLabels(w:application()) .. "\n" ..
        "aspectRatio: " ..
            string.format("%.3f", aspectRatio(w:size())) .. "\n" ..
        "frame: " .. rectStringWithLabels(w:frame()) .. "\n" ..
        "id: " .. w:id() .. "\n" ..
        "isFullScreen: " .. tostring(w:isFullScreen()) .. "\n" ..
        "isMaximizable: " .. tostring(w:isMaximizable()) .. "\n" ..
        "isMinimized: " .. tostring(w:isMinimized()) .. "\n" ..
        "isStandard: " .. tostring(w:isStandard()) .. "\n" ..
        "isVisible: " .. tostring(w:isVisible()) .. "\n" ..
        "role: " .. w:role() .. "\n" ..
        "screen: " .. screenStringWithLabelsShort(w:screen()) .. "\n" ..
        "size: " .. sizeStringWithLabels(w:size()) .. "\n" ..
        "subrole: " .. w:subrole() .. "\n" ..
        "tabCount: " .. w:tabCount() .. "\n" ..
        "title: " .. w:title() .. "\n" ..
        "topLeft: " .. pointStringWithLabels(w:topLeft())
end

hs.hotkey.bind({"ctrl", "option", "cmd"}, "I", function()
    -- printFrontmostWindowWithScreen
    local w = hs.window.frontmostWindow()
    hs.openConsole()
    print(
        "\n\nOn screen:\n\n" ..
        indent(screenStringWithLabels(w:screen())) ..
        "\n\nFrontmost window:\n\n" ..
        indent(windowStringWithLabels(w)) ..
        "\n")
end)

hs.hotkey.bind({"shift", "ctrl", "option", "cmd"}, "I", function()
    -- printAllScreensAndWindows
    local allScreens = hs.screen.allScreens()
    local allWindows = hs.window.allWindows()

    table.sort(allScreens, function(a, b)
        return a:id() < b:id()
    end)
    table.sort(allWindows, function(a, b)
        local aAppName = a:application():name()
        local bAppName = b:application():name()
        if aAppName ~= bAppName then
            return string.lower(aAppName) < string.lower(bAppName)
        else
            return a:id() < b:id()
        end
    end)

    local allString = "\n\nAll screens:"
    for i,sc in ipairs(allScreens) do
        allString = allString .. "\n\n" .. i .. ":\n"
        allString = allString .. indent(screenStringWithLabels(sc))
    end
    allString = allString .. "\n\nAll windows:"
    for i,w in ipairs(allWindows) do
        allString = allString .. "\n\n" .. i .. ":\n"
        allString = allString .. indent(windowStringWithLabels(w))
    end

    hs.openConsole()
    print(allString .. "\n")
end)


-- #####################
-- ##  Window Layout  ##
-- #####################

currentPrimaryScreen = hs.screen.primaryScreen()

function screenChangeHandler()
    local newPrimaryScreen = hs.screen.primaryScreen()
    if newPrimaryScreen:id() ~= currentPrimaryScreen:id() then
        print("Primary screen has changed; " ..
            screenStringWithLabelsShortAR(newPrimaryScreen))
        currentPrimaryScreen = newPrimaryScreen
        arrangeWindowsForScreenArrangement()
    end
end
screenWatcher = hs.screen.watcher.new(screenChangeHandler):start()

hs.hotkey.bind({"ctrl", "option", "cmd"}, "0", function()
    arrangeWindowsForScreenArrangement()
end)

function arrangeWindowsForScreenArrangement()
    print(screenStringWithLabelsShortAR(currentPrimaryScreen))
end

--[[

func ultrawide, widelarge, widesmall
Chrome role: AXHelpTag
AXWindow
AXStandardWindow
ubar

hs.layout.apply(table[, windowTitleComparator])
table - A table describing your desired layout. Each element in the table should be another table describing a set of windows to match, and their desired size/position. The fields in each of these tables are:
A string containing an application name, or an hs.application object, or nil
A string containing a window title, or an hs.window object, or a function, or nil
A string containing a screen name, or an hs.screen object, or a function that accepts no parameters and returns an hs.screen object, or nil to select the first available screen
A Unit rect, or a function which is called for each window and returns a unit rect (see hs.window.moveToUnit()). The function should accept one parameter, which is the window object.
A Frame rect, or a function which is called for each window and returns a frame rect (see hs.screen:frame()). The function should accept one parameter, which is the window object.
A Full-frame rect, of a function which is called for each window and returns a
full-frame rect (see hs.screen:fullFrame()). The function should accept one
parameter, which is the window object.

https://www.hammerspoon.org/go/#pasteblock
https://www.hammerspoon.org/go/#winfilters
https://www.hammerspoon.org/Spoons/AppWindowSwitcher.html
https://www.hammerspoon.org/Spoons/EjectMenu.html
https://github.com/Hammerspoon/Spoons/blob/master/Source/EjectMenu.spoon/init.lua
https://www.hammerspoon.org/docs/hs.notify.html#withdrawAll
home/end in console, chrome

"Snapshot Screens" => [ 0 => "{{0, 0}, {1512, 982}}" ]
"Screen Frame" => "{{0, 0}, {1512, 982}}"
"Available Screen Frame" => "{{0, 34}, {1512, 910}}"
"Snapshot" => [
  1 => {
    "Application Name" => "Finder"
    "Bundle Identifier" => "com.apple.finder"
    "Window Frame" => "{{565, 424}, {920, 436}}"
    "Window Title" => "Downloads"
  }
  2 => {
    "Application Name" => "Spotify"
    "Bundle Identifier" => "com.spotify.client"
    "Window Frame" => "{{8, 31}, {1271, 753}}"
  }
  3 => {
    "Application Name" => "Slack"
    "Bundle Identifier" => "com.tinyspeck.slackmacgap"
    "Window Frame" => "{{0, 32}, {1024, 793}}"
  }
  4 => {
    "Application Name" => "Microsoft OneNote"
    "Bundle Identifier" => "com.microsoft.onenote.mac"
    "Window Frame" => "{{600, 34}, {912, 910}}"
  }
  5 => {
    "Application Name" => "Google Chrome"
    "Bundle Identifier" => "com.google.chrome"
    "Window Frame" => "{{46, 34}, {1435, 910}}"
    "Window Frame" => "{{46, 34}, {1436, 910}}"
    "Window Frame" => "{{47, 34}, {1435, 910}}"
  }
  6 => {
    "Application Name" => "Code"
    "Bundle Identifier" => "com.microsoft.vscode"
    "Window Frame" => "{{8, 34}, {1491, 867}}"
  }
  7 => {
    "Application Name" => "iTerm2"
    "Bundle Identifier" => "com.googlecode.iterm2"
    "Window Frame" => "{{27, 44}, {724, 900}}"
    "Window Title" => "-bash"
    "Window Frame" => "{{752, 44}, {724, 900}}"
    "Window Title" => "-bash"
  }
]

"Snapshot Screens" => [ 0 => "{{0, 0}, {3440, 1440}}" ]
"Screen Frame" => "{{0, 0}, {3440, 1440}}"
"Available Screen Frame" => "{{0, 46}, {3440, 1369}}"
"Snapshot" => [
  1 => {
    "Application Name" => "Finder"
    "Bundle Identifier" => "com.apple.finder"
    "Window Frame" => "{{2308, 818}, {920, 436}}"
    "Window Title" => "Downloads"
  }
  2 => {
    "Application Name" => "Spotify"
    "Bundle Identifier" => "com.spotify.client"
    "Window Frame" => "{{55, 88}, {1354, 848}}"
    "Window Frame" => "{{68, 99}, {1354, 848}}"
  }
  3 => {
    "Application Name" => "Slack"
    "Bundle Identifier" => "com.tinyspeck.slackmacgap"
    "Window Frame" => "{{0, 44}, {1238, 851}}"
  }
  4 => {
    "Application Name" => "Microsoft OneNote"
    "Bundle Identifier" => "com.microsoft.onenote.mac"
    "Window Frame" => "{{2517, 108}, {915, 1030}}"
  }
  5 => {
    "Application Name" => "Google Chrome"
    "Bundle Identifier" => "com.google.chrome"
    "Window Frame" => "{{809, 76}, {1812, 1158}}"
    "Window Frame" => "{{809, 77}, {1813, 1155}}"
    "Window Frame" => "{{809, 77}, {1813, 1156}}"
    "Window Frame" => "{{810, 75}, {1809, 1157}}"
    "Window Frame" => "{{810, 76}, {1809, 1157}}"
    "Window Frame" => "{{812, 76}, {1809, 1158}}"
    "Window Frame" => "{{813, 88}, {1809, 1145}}"
  }
  6 => {
    "Application Name" => "Code"
    "Bundle Identifier" => "com.microsoft.vscode"
    "Window Frame" => "{{948, 51}, {1701, 1120}}"
  }
  7 => {
    "Application Name" => "iTerm2"
    "Bundle Identifier" => "com.googlecode.iterm2"
    "Window Frame" => "{{1133, 152}, {893, 1189}}"
    "Window Title" => "-bash"
    "Window Frame" => "{{239, 152}, {893, 1189}}"
    "Window Title" => "-bash"
  }
]

--]]
