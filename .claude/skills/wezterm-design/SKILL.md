---
name: wezterm-design
description: Use when modifying WezTerm visual appearance in this config — colors and palette, accent color, light/dark theme switching, tab bar look, window decorations and padding, transparency, fonts, cursor styling. Triggers on any request that touches how the terminal *looks* (not behavior or keybindings, which are a separate concern). Examples include "change accent to blue", "switch to light theme", "make tabs flatter", "increase padding", "different font", "round corners", "less aggressive inactive pane dimming". Use this skill instead of guessing where colors live or inlining hex values into option modules.
---

# WezTerm Design

Modify the visual appearance of this WezTerm config without breaking its module pattern, theme registry discipline, or stylua formatting.

## Where things live

The config is modular. Each `config/<name>.lua` returns a flat options table; `wezterm.lua` chains them via `Config:append(...)`. Visual options are spread across several modules — pick the right file before editing:

| What you want to change | File |
|---|---|
| Active theme (which scheme + accents) | `colors/init.lua` — `ACTIVE` line |
| A custom theme's palette / scheme / accents | `colors/themes/<theme>.lua` |
| Add a new theme | New `colors/themes/<name>.lua` + add `require(...)` to `THEMES` in `colors/init.lua` |
| The accent contract (which roles exist) | `colors/init.lua` — `fallback_accents` block |
| Cursor, command palette, window padding, `window_frame`, inactive pane HSB, visual bell, scrollbar | `config/appearance.lua` |
| Tab bar layout (position, fancy vs. retro, max width, buttons, `format-tab-title`) | `config/tab.lua` |
| Font family, size, line height | `config/fonts.lua` |

If a visual concern doesn't fit any of the above, create a new module `config/<name>.lua` returning a flat options table and chain it in `wezterm.lua`:

```lua
:append(require('config.<name>'))
```

Place the new `:append` alphabetically among the existing ones. `Config:append` warns about duplicate keys — never set the same option in two modules.

## Theme contract

A theme file in `colors/themes/<name>.lua` returns one of two shapes.

**Type A — fully custom WezTerm scheme:**

```lua
return {
    name = 'Dracula+',
    scheme = { foreground = ..., ansi = { ... }, tab_bar = { ... }, ... },
    accents = { progress_ok = '#...', tab_active_fg = '#...', ... },
}
```

`scheme` follows WezTerm's [`colors`](https://wezterm.org/config/lua/config/colors.html) shape (`foreground`, `background`, `cursor_*`, `selection_*`, `ansi[1..8]`, `brights[1..8]`, `indexed[16..255]`, `tab_bar.*`, `scrollbar_thumb`, etc.). `name` is the key WezTerm sees in `color_schemes`. Inside the file, the author may keep a private named palette (a `local palette = { ... }` table with a `-- stylua: ignore` block above it because the columns are hand-aligned) to compose `scheme` and `accents` without inlining hex repeatedly.

**Type B — WezTerm built-in scheme with optional accents:**

```lua
return {
    builtin = 'Tokyo Night',
    accents = { progress_indeterminate = '#FFCB6B' },  -- optional
}
```

`builtin` must be a name returned by `wezterm.color.get_builtin_schemes()`. Browse names at https://wezterm.org/colorschemes/. `accents` is optional; missing keys fall back to values derived from the resolved scheme.

## The accent contract

`colors.accents.<role>` is a fixed, semantic set of keys consumed by app-specific UI affordances. The current contract lives in `colors/init.lua`'s `fallback_accents` block. The roles are:

| Role | Used by |
|---|---|
| `progress_indeterminate` / `progress_ok` / `progress_error` | `config/tab.lua` — OSC 9;4 progress icon |
| `tab_active_fg` / `tab_inactive_fg` | `config/tab.lua` — tab title text colour |
| `titlebar_bg` | `config/appearance.lua` — `window_frame.{active,inactive}_titlebar_bg` |
| `command_palette_bg` | `config/appearance.lua` — `command_palette_bg_color` |
| `launcher_separator` | `utils/domain_launcher.lua` — group separators and entry meta |

Each role has a fallback derived from the resolved scheme's `ansi`/`brights`/`tab_bar`/`foreground`/`background` so a type-B theme without explicit accents still renders coherently.

To **add a new role**: extend the `fallback_accents` block in `colors/init.lua` with the new key + a sensible fallback, then update each custom theme that should explicitly set it. Consumers reference `colors.accents.<new_role>` from then on.

## Switching themes

Edit the single `ACTIVE` line in `colors/init.lua`:

```lua
local ACTIVE = 'Dracula+'  -- or 'Tokyo Night', 'Builtin Solarized Dark', ...
```

Three valid values:

1. The `name` of a type-A theme registered in `THEMES` — uses the local custom scheme.
2. The `builtin` of a type-B theme registered in `THEMES` — uses WezTerm's built-in scheme by that name AND applies the local file's accents.
3. Any WezTerm built-in scheme name NOT declared locally — uses the built-in directly with fully derived accents.

If `ACTIVE` doesn't match any local theme and isn't a known built-in, `colors/init.lua` raises an explicit error.

## Light / dark switching

This config has no auto-switching by OS appearance — `ACTIVE` is a single hard-coded line. If the user wants OS-driven switching, the established WezTerm approach is a `window-config-reloaded` event handler that calls `set_config_overrides({ color_scheme = ... })`. Don't return such a handler from a `config/*.lua` data module — those files return option tables, not side-effecting code. The `wezterm.on(...)` registration must execute during config evaluation; place it in `wezterm.lua` after the config is built.

## Accent colour

There is no single `accent` key. "Accent" means whichever colour the user associates with focus, activity, and highlights. Surfaces typically driven by the accent:

- `accents.tab_active_fg` (active tab text — the most visible accent surface)
- `scheme.cursor_bg` / `scheme.cursor_border`
- `scheme.compose_cursor`
- `scheme.ansi[5]` (blue slot — many TUIs use it for accents and links)

When the user says "change the accent to X":

1. Confirm or infer which surfaces they mean. Default to **active tab text + cursor + compose_cursor** if unstated. Don't repaint every blue surface — that breaks ANSI compatibility for TUIs.
2. If the change should follow theme switches, update the role in the active theme's `accents` table (e.g. `accents.tab_active_fg`) and the corresponding `scheme.cursor_*` fields.
3. If the user wants the accent locked regardless of theme, add a new accent role in `colors/init.lua` and reference it from the consumer module.

Don't add a new top-level palette key unless a theme genuinely needs a new private hex literal — accents are the public API.

## Tab bar look

Two layers, two files:

**Layout — `config/tab.lua`:**
- `use_fancy_tab_bar` — `true` is the GUI-style bar with rounded corners and the `window_frame` font; `false` is the retro single-line bar that respects the `tab_bar` colour table more granularly.
- `tab_bar_at_bottom` — moves the bar to the bottom edge.
- `hide_tab_bar_if_only_one_tab` — hides the bar when there's a single tab.
- `tab_max_width`, `show_new_tab_button_in_tab_bar`, `show_tab_index_in_tab_bar`, `show_close_tab_button_in_tabs` — chrome toggles.

Tab titles are rendered by the `format-tab-title` handler in the same file. Process icons come from `process_icons` keyed by foreground process name; domain icons come from `wezterm.GLOBAL.domain_kinds` set up by `config/domains.lua`. Tab fg colour comes from `colors.accents.tab_active_fg` / `tab_inactive_fg`. Edit the `wezterm.format` calls to change layout (text, padding, separators, attributes).

**Colours — type-A theme's `scheme.tab_bar` (in `colors/themes/<theme>.lua`):**
- `active_tab.{bg_color, fg_color, underline, italic, strikethrough}`
- `inactive_tab.{bg_color, fg_color}` and `inactive_tab_hover`
- `new_tab.{bg_color, fg_color}` and `new_tab_hover`
- `inactive_tab_edge` — separator colour between tabs (retro bar only)

`use_fancy_tab_bar = true` ignores some of these in favour of `window_frame` colours. If the user wants a flat / minimal bar with full colour control, set it to `false`.

For type-B themes (built-in scheme), the WezTerm scheme's own `tab_bar` is used; override individual keys via the `accents` table only if the relevant role exists in the contract.

## Window decorations & padding

`window_decorations` in `config/appearance.lua` controls the title bar and resize handles:
- `'NONE'` — borderless, no resize handles (resize via OS gestures only).
- `'RESIZE'` — current setting; resize handles, no title bar.
- `'TITLE | RESIZE'` — full OS chrome.
- `'INTEGRATED_BUTTONS | RESIZE'` — WezTerm draws minimize/maximize/close inside its own tab bar. Requires `use_fancy_tab_bar = true`.

`window_padding` accepts `'<n>cell'`, `'<n>px'`, or numbers (px). Prefer cell units for horizontal padding so it scales with font size.

`window_frame` controls the integrated tab bar's font and titlebar background. Its `font_size` is independent from the terminal `font_size`. The titlebar bg is wired to `colors.accents.titlebar_bg` — change the colour by editing the active theme's accent, not by inlining hex here.

`inactive_pane_hsb` dims non-focused panes. `saturation` and `brightness` < 1 darken; > 1 brighten. The current values are aggressive — if the user complains about "washed-out" inactive panes, raise them toward 1.0.

## Transparency

WezTerm transparency is configured via top-level options on `config/appearance.lua`:

- `window_background_opacity = 0.9` (or similar, 0.0–1.0) for window-wide transparency.
- `win32_system_backdrop = 'Acrylic'` for the Windows blur effect (this config runs on Windows WezTerm).
- `text_background_opacity` for transparent text background while keeping the window opaque.

The `utils/backdrops.lua` module that used to layer per-image backdrops has been removed; if the user wants images, re-introduce a small util and consume it from `appearance.lua`.

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

In `config/appearance.lua`:
- `default_cursor_style` — `'BlinkingBlock' | 'SteadyBlock' | 'BlinkingUnderline' | 'SteadyUnderline' | 'BlinkingBar' | 'SteadyBar'`.
- `cursor_blink_rate` — milliseconds per blink.
- `cursor_blink_ease_in` / `_ease_out` — `'Linear' | 'Ease' | 'EaseIn' | 'EaseOut' | 'EaseInOut' | 'Constant'`.
- `cursor_thickness` — `'<n>cell'` or `'<n>px'`. Affects only `Bar` and `Underline` styles.

Cursor and selection colours live in the active theme's `scheme.{cursor_bg, cursor_border, cursor_fg, selection_bg}` (in `colors/themes/<theme>.lua` for type-A themes; for type-B these come from the WezTerm built-in scheme and aren't currently overridable through the accent contract).

## Style & formatting

- 4-space indentation (enforced by `.stylua.toml`). Single quotes for strings. `snake_case` for names.
- `stylua --check .` to verify; `stylua .` to fix.
- Never reformat blocks marked `-- stylua: ignore` — manual alignment in palettes, accent tables, and domain-kind tables is intentional.
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
