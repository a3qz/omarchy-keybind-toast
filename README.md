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

Both halves below are required — the plugin alone renders nothing without
the Lua file telling it when to fire, and neither half errors loudly if
you skip it (see Troubleshooting).

**1. Install and enable the plugin:**
```
omarchy plugin add https://github.com/a3qz/omarchy-keybind-toast.git --enable
omarchy restart shell
```
Verify it's running — this should print `ok`:
```
omarchy-shell keybindToast ping
```

**2. Wire up the Hyprland half.** Copy the companion Lua file into your
Hyprland config:
```
cp ~/.config/omarchy/plugins/io.github.a3qz.keybind-toast/hypr/keybind-toast.lua ~/.config/hypr/keybind-toast.lua
```
Add one line to `~/.config/hypr/hyprland.lua`, alongside your other
`require("hypr.*")` lines (position relative to them doesn't matter):
```lua
require("hypr.keybind-toast")
```
Reload, then verify it loaded with no errors — this should print nothing:
```
hyprctl reload
hyprctl configerrors
```

**3. Try it.** Press a bound key — `SUPER + RETURN` (opens your terminal)
is a good first one. You should see a small centered box at the bottom of
the screen reading "Terminal". If nothing appears but step 1 and step 2's
checks both passed, see Troubleshooting below.

## Customizing which keybinds toast

Open `~/.config/hypr/keybind-toast.lua` — the `toast_enabled` table near
the top lists every toastable description. Set any entry to `false` to
silence it without removing it. To add a binding that isn't in the list
yet, find it in `/usr/share/omarchy/default/hypr/bindings/*.lua`
(read-only, for reference), then copy its keys/description/dispatcher into
this file as an `hl.unbind(keys)` + `o.bind_toast(keys, description,
action)` pair (see the existing entries for the shapes `action` accepts).

## Limitations / Troubleshooting

**Nothing happens when I press a bound key.** Most likely one half of the
two-part install is missing, and neither half errors loudly when it's
alone:
- Plugin installed but no `require("hypr.keybind-toast")` in
  `hyprland.lua` (or the Lua file wasn't copied in) — the plugin sits
  there ready, nothing ever calls it.
- Lua file wired up but the plugin isn't installed/enabled —
  `hl.exec_cmd("omarchy-shell -q keybindToast show ...")` runs, but `-q`
  makes it fail silently if the IPC target doesn't exist. The keybind
  itself still works normally; only the toast is missing.

Check both: `omarchy plugin list --json | jq '.[] | select(.id=="io.github.a3qz.keybind-toast")'`
should show `"enabled": true`, and `grep keybind-toast ~/.config/hypr/hyprland.lua`
should show the `require` line.

**A keybind I customized myself stopped doing what I set it to.** If you'd
already rebound one of the ~145 keys this plugin re-declares (in your own
`bindings.lua` or elsewhere), whichever file Hyprland `require()`s *last*
wins — `hl.unbind` + rebind on the same key is a last-writer-wins
operation, not a merge. If `hypr.keybind-toast` is required after your own
override, it silently takes the key back. Either require your own
overrides after this file, or remove the specific `hl.unbind`/`o.bind_toast`
pair for that key from `keybind-toast.lua`.

**Descriptions/dispatchers might drift from Omarchy over time.** This
plugin doesn't call into Omarchy's live keybinding config — it re-declares
a hand-copied snapshot of it (both the ~145 bindings themselves and a
local mirror of Omarchy's private, unexported `command_from()` dispatcher
helper, since there's no public API to hook into instead). If a future
Omarchy release changes a default keybind, adds new dispatcher shorthand,
or changes existing dispatcher behavior, this plugin won't pick that up
automatically. If something toasts the wrong thing (or a binding you'd
expect to be here is missing) after an Omarchy update, compare against
the current `/usr/share/omarchy/default/hypr/bindings/*.lua` and
`helpers.lua`'s `command_from()`, and open an issue/PR.

## Removal

```
omarchy plugin remove io.github.a3qz.keybind-toast
```
Then remove the `require("hypr.keybind-toast")` line from `hyprland.lua`
and delete `~/.config/hypr/keybind-toast.lua`.

## License

MIT — see `LICENSE`. No external dependencies beyond Omarchy itself.
