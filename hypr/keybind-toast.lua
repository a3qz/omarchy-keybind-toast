--------------------------------------------------------------------------
-- Keybind toast: shows a small text box at the bottom of the screen naming
-- an action whenever one of the bindings below fires. Only the bindings
-- re-declared here toast; everything else is untouched.
--
-- Rendering is handled by a dedicated Quickshell plugin (not the shared
-- volume/brightness OSD, which truncates long text and reserves an icon
-- column even when there's no icon to show). See:
--   ~/.config/omarchy/plugins/io.github.a3qz.keybind-toast/
--
-- To add more later: find its line in
-- /usr/share/omarchy/default/hypr/bindings/*.lua (read-only, for reference
-- only), copy the keys/description/dispatcher into the list below, and add
-- an hl.unbind(keys) line above it so the default doesn't fire twice.
--
-- To silence one without removing it, flip its line to `false` below.
--------------------------------------------------------------------------

local toast_enabled = {
  -- Applications
  ["Terminal"] = true,
  ["Browser"] = true,
  ["Browser (private)"] = true,
  ["File manager"] = true,
  ["File manager (cwd)"] = true,
  ["Editor"] = true,
  -- Preinstalled app/webapp launchers
  ["Tmux"] = true,
  ["Herdr"] = true,
  ["Music"] = true,
  ["Music TUI"] = true,
  ["Docker"] = true,
  ["Signal"] = true,
  ["Obsidian"] = true,
  ["Omawrite"] = true,
  ["Passwords"] = true,
  ["ChatGPT"] = true,
  ["Grok"] = true,
  ["Calendar"] = true,
  ["Email"] = true,
  ["New email"] = true,
  ["YouTube"] = true,
  ["WhatsApp"] = true,
  ["Google Messages"] = true,
  ["Google Photos"] = true,
  ["Google Maps"] = true,
  ["X"] = true,
  ["X Post"] = true,
  -- Menus
  ["Omarchy menu"] = true,
  ["Apps menu"] = true,
  ["System menu"] = true,
  ["Theme menu"] = true,
  ["Background switcher"] = true,
  ["Keybindings"] = true,
  -- Window toggles
  ["Toggle window floating/tiling"] = true,
  ["Full screen"] = true,
  ["Full width"] = true,
  ["Pop window out (float & pin)"] = true,
  ["Toggle window transparency"] = true,
  ["Toggle window gaps"] = true,
  ["Toggle window grouping"] = true,
  -- Feature toggles
  ["Toggle top bar"] = true,
  ["Toggle nightlight"] = true,
  ["Toggle locking on idle"] = true,
  ["Toggle silencing notifications"] = true,
  -- Capture
  ["Screenshot"] = true,
  ["Screenrecording"] = true,
  ["Color picker"] = true,
  ["Extract text (OCR) from screenshot"] = true,
  -- System
  ["Lock system"] = true,
  ["Clipboard manager"] = true,
  ["Toggle scratchpad"] = true,
  ["Set reminder"] = true,
  -- Window movement & navigation
  ["Close window"] = true,
  ["Close all windows"] = true,
  ["Toggle window split"] = true,
  ["Pseudo window"] = true,
  ["Tiled full screen"] = true,
  ["Save window width"] = true,
  ["Restore window width"] = true,
  ["Toggle workspace layout"] = true,
  ["Focus on left window"] = true,
  ["Focus on right window"] = true,
  ["Focus on above window"] = true,
  ["Focus on below window"] = true,
  ["Move window to scratchpad"] = true,
  ["Next workspace"] = true,
  ["Previous workspace"] = true,
  ["Former workspace"] = true,
  ["Move workspace to left monitor"] = true,
  ["Move workspace to right monitor"] = true,
  ["Move workspace to up monitor"] = true,
  ["Move workspace to down monitor"] = true,
  ["Swap window to the left"] = true,
  ["Swap window to the right"] = true,
  ["Swap window up"] = true,
  ["Swap window down"] = true,
  ["Focus on next window"] = true,
  ["Focus on previous window"] = true,
  ["Focus on next monitor"] = true,
  ["Focus on previous monitor"] = true,
  ["Expand window left"] = true,
  ["Shrink window left"] = true,
  ["Shrink window up"] = true,
  ["Expand window down"] = true,
  ["Expand window left a little"] = true,
  ["Shrink window left a little"] = true,
  ["Shrink window up a little"] = true,
  ["Expand window down a little"] = true,
  ["Expand window left a lot"] = true,
  ["Shrink window left a lot"] = true,
  ["Shrink window up a lot"] = true,
  ["Expand window down a lot"] = true,
  ["Scroll active workspace forward"] = true,
  ["Scroll active workspace backward"] = true,
  ["Move window"] = true,
  ["Resize window"] = true,
  ["Move active window out of group"] = true,
  ["Move window to group on left"] = true,
  ["Move window to group on right"] = true,
  ["Move window to group on top"] = true,
  ["Move window to group on bottom"] = true,
  ["Next window in group"] = true,
  ["Previous window in group"] = true,
  ["Move grouped window focus left"] = true,
  ["Move grouped window focus right"] = true,
}

-- Loop-generated descriptions (workspace switch/move, group window select).
for i = 1, 10 do
  toast_enabled["Switch to workspace " .. i] = true
  toast_enabled["Move window to workspace " .. i] = true
  toast_enabled["Move window silently to workspace " .. i] = true
end
for i = 1, 5 do
  toast_enabled["Switch to group window " .. i] = true
end

-- Minimal JSON string escaper -- descriptions below are static strings we
-- control, but this keeps fire_toast safe regardless.
local function json_escape(s)
  return (s:gsub('[\\"\n\r\t]', {
    ["\\"] = "\\\\",
    ['"'] = '\\"',
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
  }))
end

local function fire_toast(description)
  if description and toast_enabled[description] then
    local payload = '{"message":"' .. json_escape(description) .. '"}'
    hl.exec_cmd("omarchy-shell -q keybindToast show " .. o.shell_quote(payload))
  end
end

-- Mirrors helpers.lua's private command_from() so the {omarchy=...}/{tui=...}/
-- {webapp=...}/{launch=...} table shorthand can still be used below.
local function resolve_dispatcher(value, description)
  if type(value) ~= "table" then
    return value
  end

  if value.omarchy then
    return "omarchy-launch-" .. value.omarchy
  elseif value.focus and value.launch then
    return o.launch_sole(value.focus, value.launch)
  elseif value.launch then
    return o.launch(value.launch)
  elseif value.webapp then
    if value.focus then
      return o.launch_webapp_sole(description, value.webapp)
    else
      return o.launch_webapp(value.webapp)
    end
  elseif value.tui then
    if value.focus then
      return "omarchy-launch-or-focus-tui " .. o.shell_quote(value.tui)
    else
      return "omarchy-launch-tui " .. o.shell_quote(value.tui)
    end
  end

  return value
end

-- Drop-in replacement for o.bind that also fires the toast above. `action`
-- accepts the same shapes o.bind's dispatcher does: a shell command string,
-- an HL.Dispatcher object (e.g. hl.dsp.window.close()), a plain Lua
-- function, or the {omarchy=...}/{tui=...}/{webapp=...}/{launch=...} table
-- shorthand.
function o.bind_toast(keys, description, action, options)
  local opts = options or {}
  if description then
    opts.description = description
  end

  action = resolve_dispatcher(action, description)

  local invoke
  if type(action) == "string" then
    invoke = function() hl.exec_cmd(action) end
  else
    invoke = function() hl.dispatch(action) end
  end

  hl.bind(keys, function()
    invoke()
    fire_toast(description)
  end, opts)
end

-- Applications
hl.unbind("SUPER + RETURN")
o.bind_toast("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
hl.unbind("SUPER + SHIFT + RETURN")
o.bind_toast("SUPER + SHIFT + RETURN", "Browser", { omarchy = "browser" })
hl.unbind("SUPER + SHIFT + F")
o.bind_toast("SUPER + SHIFT + F", "File manager", { omarchy = "nautilus" })
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind_toast("SUPER + ALT + SHIFT + F", "File manager (cwd)", { omarchy = "nautilus-cwd" })
hl.unbind("SUPER + SHIFT + ALT + B")
o.bind_toast("SUPER + SHIFT + ALT + B", "Browser (private)", { omarchy = "browser --private" })
hl.unbind("SUPER + SHIFT + N")
o.bind_toast("SUPER + SHIFT + N", "Editor", { omarchy = "editor" })
-- Note: SUPER+SHIFT+B is left untouched -- it's a second key for "Browser",
-- already toasted via SUPER+SHIFT+RETURN above.

-- Preinstalled app/webapp launchers
if o.preinstalled_bindings_enabled() then
  hl.unbind("SUPER + ALT + RETURN")
  o.bind_toast("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
  hl.unbind("SUPER + CTRL + RETURN")
  o.bind_toast("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
  hl.unbind("SUPER + SHIFT + M")
  o.bind_toast("SUPER + SHIFT + M", "Music", { omarchy = "spotify" })
  hl.unbind("SUPER + SHIFT + ALT + M")
  o.bind_toast("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
  hl.unbind("SUPER + SHIFT + D")
  o.bind_toast("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
  hl.unbind("SUPER + SHIFT + G")
  o.bind_toast("SUPER + SHIFT + G", "Signal", { omarchy = "signal" })
  hl.unbind("SUPER + SHIFT + O")
  o.bind_toast("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
  hl.unbind("SUPER + SHIFT + W")
  o.bind_toast("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })
  hl.unbind("SUPER + SHIFT + SLASH")
  o.bind_toast("SUPER + SHIFT + SLASH", "Passwords", { omarchy = "1password" })

  hl.unbind("SUPER + SHIFT + A")
  o.bind_toast("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
  hl.unbind("SUPER + SHIFT + ALT + A")
  o.bind_toast("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
  hl.unbind("SUPER + SHIFT + C")
  o.bind_toast("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
  hl.unbind("SUPER + SHIFT + E")
  o.bind_toast("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
  hl.unbind("SUPER + SHIFT + ALT + E")
  o.bind_toast("SUPER + SHIFT + ALT + E", "New email", { webapp = "https://app.hey.com/messages/new?display=standalone&new_window=true" })
  hl.unbind("SUPER + SHIFT + Y")
  o.bind_toast("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
  hl.unbind("SUPER + SHIFT + ALT + G")
  o.bind_toast("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
  hl.unbind("SUPER + SHIFT + CTRL + G")
  o.bind_toast("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
  hl.unbind("SUPER + SHIFT + P")
  o.bind_toast("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
  hl.unbind("SUPER + SHIFT + S")
  o.bind_toast("SUPER + SHIFT + S", "Google Maps", { webapp = "https://maps.google.com/", focus = true })
  hl.unbind("SUPER + SHIFT + X")
  o.bind_toast("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
  hl.unbind("SUPER + SHIFT + ALT + X")
  o.bind_toast("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })
end

-- Menus
hl.unbind("SUPER + SPACE")
o.bind_toast("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle")
hl.unbind("SUPER + ALT + SPACE")
o.bind_toast("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
hl.unbind("SUPER + ESCAPE")
o.bind_toast("SUPER + ESCAPE", "System menu", "omarchy-menu toggle system")
hl.unbind("SUPER + SHIFT + CTRL + SPACE")
o.bind_toast("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "omarchy-menu toggle theme")
hl.unbind("SUPER + CTRL + SPACE")
o.bind_toast("SUPER + CTRL + SPACE", "Background switcher", "omarchy-menu toggle background")
hl.unbind("SUPER + K")
o.bind_toast("SUPER + K", "Keybindings", "omarchy-menu-keybindings")

-- Window toggles
hl.unbind("SUPER + T")
o.bind_toast("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
hl.unbind("SUPER + F")
o.bind_toast("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.unbind("SUPER + ALT + F")
o.bind_toast("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.unbind("SUPER + O")
o.bind_toast("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
hl.unbind("SUPER + BACKSPACE")
o.bind_toast("SUPER + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")
hl.unbind("SUPER + SHIFT + BACKSPACE")
o.bind_toast("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
hl.unbind("SUPER + G")
o.bind_toast("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())

-- Feature toggles
hl.unbind("SUPER + SHIFT + SPACE")
o.bind_toast("SUPER + SHIFT + SPACE", "Toggle top bar", "omarchy-toggle-bar")
hl.unbind("SUPER + CTRL + N")
o.bind_toast("SUPER + CTRL + N", "Toggle nightlight", "omarchy-toggle-nightlight")
hl.unbind("SUPER + CTRL + I")
o.bind_toast("SUPER + CTRL + I", "Toggle locking on idle", "omarchy-toggle-idle")
hl.unbind("SUPER + CTRL + comma")
o.bind_toast("SUPER + CTRL + comma", "Toggle silencing notifications", "omarchy-toggle-notification-silencing")

-- Capture
hl.unbind("PRINT")
o.bind_toast("PRINT", "Screenshot", "omarchy-capture-screenshot")
hl.unbind("ALT + PRINT")
o.bind_toast("ALT + PRINT", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
hl.unbind("SUPER + PRINT")
o.bind_toast("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
hl.unbind("SUPER + CTRL + PRINT")
o.bind_toast("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "omarchy-capture-text")

-- System
hl.unbind("SUPER + CTRL + L")
o.bind_toast("SUPER + CTRL + L", "Lock system", "omarchy-system-lock")
hl.unbind("SUPER + CTRL + V")
o.bind_toast("SUPER + CTRL + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")
hl.unbind("SUPER + S")
o.bind_toast("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
hl.unbind("SUPER + CTRL + R")
o.bind_toast("SUPER + CTRL + R", "Set reminder", "omarchy-menu toggle reminder-set")

-- Window movement & navigation
hl.unbind("SUPER + W")
o.bind_toast("SUPER + W", "Close window", hl.dsp.window.close())
hl.unbind("CTRL + ALT + DELETE")
o.bind_toast("CTRL + ALT + DELETE", "Close all windows", "omarchy-hyprland-window-close-all")

hl.unbind("SUPER + J")
o.bind_toast("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
hl.unbind("SUPER + P")
o.bind_toast("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
hl.unbind("SUPER + CTRL + F")
o.bind_toast("SUPER + CTRL + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
hl.unbind("SUPER + ALT + Home")
o.bind_toast("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")
hl.unbind("SUPER + Home")
o.bind_toast("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")
hl.unbind("SUPER + L")
o.bind_toast("SUPER + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

hl.unbind("SUPER + LEFT")
o.bind_toast("SUPER + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
hl.unbind("SUPER + RIGHT")
o.bind_toast("SUPER + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
hl.unbind("SUPER + UP")
o.bind_toast("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
hl.unbind("SUPER + DOWN")
o.bind_toast("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + " .. key)
  o.bind_toast("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  hl.unbind("SUPER + SHIFT + " .. key)
  o.bind_toast("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  o.bind_toast("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

hl.unbind("SUPER + ALT + S")
o.bind_toast("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

hl.unbind("SUPER + TAB")
o.bind_toast("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
hl.unbind("SUPER + SHIFT + TAB")
o.bind_toast("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
hl.unbind("SUPER + CTRL + TAB")
o.bind_toast("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

hl.unbind("SUPER + SHIFT + ALT + LEFT")
o.bind_toast("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
hl.unbind("SUPER + SHIFT + ALT + RIGHT")
o.bind_toast("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
hl.unbind("SUPER + SHIFT + ALT + UP")
o.bind_toast("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
hl.unbind("SUPER + SHIFT + ALT + DOWN")
o.bind_toast("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

hl.unbind("SUPER + SHIFT + LEFT")
o.bind_toast("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
hl.unbind("SUPER + SHIFT + RIGHT")
o.bind_toast("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
hl.unbind("SUPER + SHIFT + UP")
o.bind_toast("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
hl.unbind("SUPER + SHIFT + DOWN")
o.bind_toast("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

-- ALT+TAB and ALT+SHIFT+TAB each fire two dispatchers by default (cycle
-- focus, then raise the window). unbind removes both, so both are replayed
-- here from a single wrapped function.
hl.unbind("ALT + TAB")
o.bind_toast("ALT + TAB", "Focus on next window", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.bring_to_top())
end)
hl.unbind("ALT + SHIFT + TAB")
o.bind_toast("ALT + SHIFT + TAB", "Focus on previous window", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

hl.unbind("CTRL + ALT + TAB")
o.bind_toast("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
hl.unbind("CTRL + ALT + SHIFT + TAB")
o.bind_toast("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

hl.unbind("SUPER + code:20")
o.bind_toast("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.unbind("SUPER + code:21")
o.bind_toast("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.unbind("SUPER + SHIFT + code:20")
o.bind_toast("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.unbind("SUPER + SHIFT + code:21")
o.bind_toast("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

hl.unbind("SUPER + ALT + code:20")
o.bind_toast("SUPER + ALT + code:20", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
hl.unbind("SUPER + ALT + code:21")
o.bind_toast("SUPER + ALT + code:21", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
hl.unbind("SUPER + SHIFT + ALT + code:20")
o.bind_toast("SUPER + SHIFT + ALT + code:20", "Shrink window up a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
hl.unbind("SUPER + SHIFT + ALT + code:21")
o.bind_toast("SUPER + SHIFT + ALT + code:21", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

hl.unbind("SUPER + CTRL + code:20")
o.bind_toast("SUPER + CTRL + code:20", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
hl.unbind("SUPER + CTRL + code:21")
o.bind_toast("SUPER + CTRL + code:21", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
hl.unbind("SUPER + CTRL + SHIFT + code:20")
o.bind_toast("SUPER + CTRL + SHIFT + code:20", "Shrink window up a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
hl.unbind("SUPER + CTRL + SHIFT + code:21")
o.bind_toast("SUPER + CTRL + SHIFT + code:21", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

hl.unbind("SUPER + mouse_down")
o.bind_toast("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
hl.unbind("SUPER + mouse_up")
o.bind_toast("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

hl.unbind("SUPER + mouse:272")
o.bind_toast("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
hl.unbind("SUPER + mouse:273")
o.bind_toast("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

hl.unbind("SUPER + ALT + G")
o.bind_toast("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))

hl.unbind("SUPER + ALT + LEFT")
o.bind_toast("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
hl.unbind("SUPER + ALT + RIGHT")
o.bind_toast("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
hl.unbind("SUPER + ALT + UP")
o.bind_toast("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
hl.unbind("SUPER + ALT + DOWN")
o.bind_toast("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

hl.unbind("SUPER + ALT + TAB")
o.bind_toast("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
hl.unbind("SUPER + ALT + SHIFT + TAB")
o.bind_toast("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

hl.unbind("SUPER + CTRL + LEFT")
o.bind_toast("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
hl.unbind("SUPER + CTRL + RIGHT")
o.bind_toast("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

hl.unbind("SUPER + ALT + mouse_down")
o.bind_toast("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
hl.unbind("SUPER + ALT + mouse_up")
o.bind_toast("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

for index = 1, 5 do
  hl.unbind("SUPER + ALT + code:" .. tostring(index + 9))
  o.bind_toast("SUPER + ALT + code:" .. tostring(index + 9), "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end
