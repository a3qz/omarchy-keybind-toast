# Keybind Toast

A small text-only box at the bottom of the screen that names the Omarchy
keybind you just triggered ("Terminal", "Toggle window floating/tiling",
"Focus on next window", ...). Unlike the built-in volume/brightness OSD,
it's centered on the text with no icon column, and wraps long descriptions
onto a second line instead of truncating them.

## How it works

This is two parts, because Hyprland's keybinding config (Lua, a separate
process) and Omarchy's shell (Quickshell, this plugin) are different
systems — a shell plugin can't install or edit Hyprland config on its own.

1. **This plugin** — a Quickshell panel that renders the toast box and
   listens for `omarchy-shell -q keybindToast show '{"message":"..."}'`.
2. **`hypr/keybind-toast.lua`** — a Hyprland Lua file you copy into
   `~/.config/hypr/`. It re-declares the Omarchy default keybindings you
   want to toast (a curated list to start, easy to add to) and fires the
   IPC call above whenever one of them runs.

## Install

1. Install and enable the plugin:
   ```
   omarchy plugin add https://github.com/a3qz/omarchy-keybind-toast.git --enable
   omarchy restart shell
   ```
2. Copy the companion Lua file into your Hyprland config:
   ```
   cp ~/.config/omarchy/plugins/io.github.a3qz.keybind-toast/hypr/keybind-toast.lua ~/.config/hypr/keybind-toast.lua
   ```
3. Require it from `~/.config/hypr/hyprland.lua`, near your other
   `require("hypr.*")` lines:
   ```lua
   require("hypr.keybind-toast")
   ```
4. `hyprctl reload`.

## Customizing which keybinds toast

Open `~/.config/hypr/keybind-toast.lua` — the `toast_enabled` table near
the top lists every toastable description. Set any entry to `false` to
silence it without removing it. To add a binding that isn't in the list
yet, find it in `/usr/share/omarchy/default/hypr/bindings/*.lua`
(read-only, for reference), then copy its keys/description/dispatcher into
this file as an `hl.unbind(keys)` + `o.bind_toast(keys, description,
action)` pair (see the existing entries for the shapes `action` accepts).

## Removal

```
omarchy plugin remove io.github.a3qz.keybind-toast
```
Then remove the `require("hypr.keybind-toast")` line from `hyprland.lua`
and delete `~/.config/hypr/keybind-toast.lua`.

## License

MIT — see `LICENSE`. No external dependencies beyond Omarchy itself.
