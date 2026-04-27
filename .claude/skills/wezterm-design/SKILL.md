---
name: wezterm-design
description: Use when modifying WezTerm visual appearance in this config — colors and palette, accent color, light/dark theme switching, tab bar look, window decorations and padding, transparency, fonts, cursor styling, or backdrops. Triggers on any request that touches how the terminal *looks* (not behavior or keybindings, which are a separate concern). Examples include "change accent to blue", "switch to light theme", "make tabs flatter", "increase padding", "different font", "round corners", "less aggressive inactive pane dimming". Use this skill instead of guessing where colors live or inlining hex values into option modules.
---

# WezTerm Design

Modify the visual appearance of this WezTerm config without breaking its module pattern, palette discipline, or stylua formatting.

## Where things live

The config is modular. Each `config/<name>.lua` returns a flat options table; `wezterm.lua` chains them via `Config:append(...)`. Visual options are spread across several modules — pick the right file before editing:

| What you want to change | File |
|---|---|
| Color palette (hex literals) | `colors/custom.lua` — `Theme.colors` |
| Active colorscheme (which palette key fills which role) | `colors/custom.lua` — `colorscheme` |
| Cursor, command palette, window padding, `window_frame`, inactive pane HSB, visual bell, scrollbar | `config/appearance.lua` |
| Tab bar layout (position, fancy vs. retro, max width, buttons, `format-tab-title`) | `config/tab.lua` |
| Font family, size, line height | `config/fonts.lua` |
| Background images / focus mode | `utils/backdrops.lua` (consumed by `appearance.lua`) |

If a visual concern doesn't fit any of the above, create a new module `config/<name>.lua` returning a flat options table and chain it in `wezterm.lua`:

```lua
:append(require('config.<name>'))
```

Place the new `:append` alphabetically among the existing ones. `Config:append` warns about duplicate keys — never set the same option in two modules.

## Color rules

The palette is the source of truth. **Never inline hex values in `config/*.lua`.** When you need a new color:

1. Add it to `Theme.colors` in `colors/custom.lua` with a semantic name (`accent`, `selection_bg_alt`) — not a generic shade name like `pink2`.
2. Reference it from the consuming module via `Theme.colors.<name>` (after `local Theme = require('colors.custom')`).
3. If the new color replaces a role, update `colorscheme` so the role mapping stays the single source of truth.

The palette block has `-- stylua: ignore` above it because the columns are hand-aligned. Preserve that alignment when editing — don't reformat, don't drop the comment, don't let stylua touch it.

The shape of `colorscheme` mirrors WezTerm's `colors = ...` schema (`foreground`, `background`, `ansi[1..8]`, `brights[1..8]`, `tab_bar.{active_tab, inactive_tab, ...}`, `indexed[16..255]`, `cursor_*`, `selection_*`, `scrollbar_thumb`). Reference: https://wezterm.org/config/lua/config/colors.html. When in doubt, keep keys you don't recognise — removing them silently changes appearance.

## Light / dark theme switching

The current palette is dark (Dracula+ derivative). Three valid strategies depending on what the user wants:

**(a) Replace the palette in place.** Best when the user wants permanent light mode. Overwrite `Theme.colors` and `colorscheme` with light values, keeping the same key names so consumers don't break.

**(b) Use a built-in WezTerm scheme by name.** WezTerm ships hundreds of named schemes — no hand-rolling required:

```lua
-- in config/appearance.lua
color_scheme = 'Builtin Solarized Light',
```

You may set both `color_scheme` (a name) and `colors` (a table) — the table overrides individual keys on top of the named scheme. If the user is committing to a named scheme, drop `colors = Theme.colorscheme` to avoid two competing sources. Browse names at https://wezterm.org/colorschemes/ or via `wezterm.color.get_builtin_schemes()`.

**(c) Auto-switch by OS appearance** (only if the user explicitly asks for it). Add to `wezterm.lua` *after* the config is built (or in a small side-effecting module that `wezterm.lua` requires):

```lua
local function scheme_for_appearance(appearance)
   if appearance:find('Dark') then
      return 'Builtin Tango Dark'
   end
   return 'Builtin Solarized Light'
end

wezterm.on('window-config-reloaded', function(window)
   local overrides = window:get_config_overrides() or {}
   local scheme = scheme_for_appearance(window:get_appearance())
   if overrides.color_scheme ~= scheme then
      overrides.color_scheme = scheme
      window:set_config_overrides(overrides)
   end
end)
```

Don't try to return this handler from a `config/*.lua` data module — those modules return option tables, not side-effecting code. The `wezterm.on` registration must execute during config evaluation.

## Accent colour

There is no single `accent` key in this config. "Accent" is whichever colour the user associates with focus, activity, and highlights. Surfaces typically driven by the accent:

- `colorscheme.tab_bar.active_tab.fg_color` (active tab text — most visible)
- `colorscheme.cursor_bg` and `cursor_border`
- `colorscheme.compose_cursor`
- `colorscheme.ansi[5]` (blue slot — many TUIs use it for accents and links)

When the user says "change the accent to X":

1. Confirm or infer which surfaces they mean. Default to **active tab + cursor + compose_cursor** if unstated. Don't repaint every blue surface — that breaks ANSI compatibility for TUIs.
2. Add or update the colour in `Theme.colors` (e.g. set `Theme.colors.blue` or add `Theme.colors.accent`).
3. Point each affected `colorscheme` role at that palette key.

## Tab bar look

Two layers, two files:

**Layout — `config/tab.lua`:**
- `use_fancy_tab_bar` — `true` is the GUI-style bar with rounded corners and the `window_frame` font; `false` is the retro single-line bar that respects the `tab_bar` colour table more granularly.
- `tab_bar_at_bottom` — moves the bar to the bottom edge.
- `hide_tab_bar_if_only_one_tab` — hides the bar when there's a single tab.
- `tab_max_width`, `show_new_tab_button_in_tab_bar`, `show_tab_index_in_tab_bar`, `show_close_tab_button_in_tabs` — chrome toggles.

Tab titles are rendered by the `format-tab-title` handler in the same file. Icons come from `process_icons` keyed by foreground process name; the layout (text, padding, separators, attributes) lives in the `wezterm.format` calls. Edit those to change icons or layout.

**Colours — `colors/custom.lua` `colorscheme.tab_bar`:**
- `active_tab.{bg_color, fg_color, underline, italic, strikethrough}`
- `inactive_tab.{bg_color, fg_color}` and `inactive_tab_hover`
- `new_tab.{bg_color, fg_color}` and `new_tab_hover`
- `inactive_tab_edge` — separator colour between tabs (retro bar only)

`use_fancy_tab_bar = true` ignores some of these in favour of `window_frame` colours. If the user wants a flat / minimal bar with full colour control, set it to `false`.

## Window decorations & padding

`window_decorations` in `appearance.lua` controls the title bar and resize handles:
- `'NONE'` — borderless, no resize handles (resize via OS gestures only).
- `'RESIZE'` — current setting; resize handles, no title bar.
- `'TITLE | RESIZE'` — full OS chrome.
- `'INTEGRATED_BUTTONS | RESIZE'` — WezTerm draws minimize/maximize/close inside its own tab bar. Requires `use_fancy_tab_bar = true`.

`window_padding` accepts `'<n>cell'`, `'<n>px'`, or numbers (px). Prefer cell units for horizontal padding so it scales with font size.

`window_frame` controls the integrated tab bar's font and titlebar background. Its `font_size` is independent from the terminal `font_size`.

`inactive_pane_hsb` dims non-focused panes. `saturation` and `brightness` < 1 darken; > 1 brighten. The current values are aggressive — if the user complains about "washed-out" inactive panes, raise them toward 1.0.

## Transparency

WezTerm transparency is configured through the backdrop layer, not a single `window_background_opacity` (though that key works too). Two approaches:

- **Simple:** add `window_background_opacity = 0.9` (or similar, 0.0–1.0) to `appearance.lua`. Add `win32_system_backdrop = 'Acrylic'` for the Windows blur effect (this config runs on Windows WezTerm).
- **Per-image:** the `backdrops` util (`utils/backdrops.lua`) layers images with their own opacity. Edit there if the user wants a transparent backdrop image rather than blanket window transparency.

## Fonts

`config/fonts.lua` is intentionally minimal. To set a family:

```lua
local wezterm = require('wezterm')

return {
   font = wezterm.font_with_fallback({
      { family = 'JetBrainsMono Nerd Font', weight = 'Medium' },
      'Symbols Nerd Font',
   }),
   font_size = 12,
   line_height = 1.1,
}
```

Use `font_with_fallback` (not `font`) when the primary family lacks full glyph coverage — the Nerd Font fallback prevents missing tab bar glyphs. This config sets `warn_about_missing_glyphs = false` in `appearance.lua`, so missing glyphs render as boxes silently — eyeball the tab bar after font changes.

`line_height` is a multiplier (`1.0` = native). `font_size` is in points.

## Cursor

In `appearance.lua`:
- `default_cursor_style` — `'BlinkingBlock' | 'SteadyBlock' | 'BlinkingUnderline' | 'SteadyUnderline' | 'BlinkingBar' | 'SteadyBar'`.
- `cursor_blink_rate` — milliseconds per blink.
- `cursor_blink_ease_in` / `_ease_out` — `'Linear' | 'Ease' | 'EaseIn' | 'EaseOut' | 'EaseInOut' | 'Constant'`.
- `cursor_thickness` — `'<n>cell'` or `'<n>px'`. Affects only `Bar` and `Underline` styles.

Cursor colours live in `colorscheme.cursor_{bg,border,fg}` in `colors/custom.lua` (not in `appearance.lua`). Selection colours similarly: `colorscheme.selection_bg`.

## Style & formatting

- 3-space indentation. Single quotes for strings. `snake_case` for names.
- `stylua --check .` to verify; `stylua .` to fix.
- Never reformat blocks marked `-- stylua: ignore` — manual alignment in palettes is intentional.
- EmmyLua annotations (`---@class`, `---@return`) when introducing types or factory functions; not needed for plain option tables.

## Verification

There are no tests and no linter beyond stylua. After editing:

1. `stylua --check .` from the repo root.
2. Reload the running WezTerm with `Ctrl+Shift+R`.
3. Watch the WezTerm log and the on-screen error overlay for runtime errors — config errors only surface at runtime, syntax-clean Lua can still break WezTerm's option validation.
4. Visually confirm the change.

If you cannot trigger a reload yourself, **say so explicitly** rather than claim the change works. A passing stylua check is not proof of a working config.

## Out of scope

- Keybindings, leader keys, key tables — separate skill.
- Mouse, scrollback, default program, environment variables — behaviour, not visuals.
- The reserved `Alt+Ctrl+D/V/H` bindings (claimed by the `quick_domains.wezterm` plugin) — relevant only when touching keybindings.
