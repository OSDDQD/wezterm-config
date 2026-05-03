# Color theming refactor — design

Date: 2026-05-03
Status: approved, pending implementation

## Goal

Make the WezTerm config able to (a) pick any built-in WezTerm scheme by name with no scaffolding, and (b) host arbitrary additional custom themes alongside the existing Dracula+, by switching a single line.

## Current problem

`colors/custom.lua` mixes two concepts under one module:

1. A **WezTerm color scheme** — the structure WezTerm understands (`foreground`, `ansi`, `tab_bar`, …), passed as `colors = …` in `config/appearance.lua`.
2. A **named palette** — Catppuccin/Dracula+-flavoured names (`peach`, `overlay1`, `surface0`, …) used by `config/tab.lua`, `config/appearance.lua`, `utils/domain_launcher.lua` for accents that aren't part of WezTerm's schema.

Consumers reach into the same module for both. The same hex value is reachable as `Theme.colors.green` (palette) AND `Theme.colorscheme.ansi[3]` (scheme). Switching theme means rewriting the file because the two concepts are entangled. Built-in WezTerm schemes can't be used at all without losing every accent.

## Architectural rule

Two concepts, two surfaces, no entanglement:

- **Scheme**: structural, dictated by WezTerm. Outside the `colors/` module nobody touches the scheme structure directly. It is handed to WezTerm as a name plus a registration table; that's all.
- **Accents**: a flat semantic palette of fixed keys. Modules consume accents by **role** (`progress_indeterminate`, `tab_active_fg`), never by shade name (`peach`, `mauve`).

A theme bundles both. Inside a theme file the author may use any internal naming convention to compose hex values; only `name`/`builtin`/`scheme`/`accents` leak outward.

## Module layout

```
colors/
   init.lua                  registry + active selector + accent fallback
   themes/
      dracula_plus.lua       migrated existing palette
      example_builtin.lua    minimal example: WezTerm built-in + accents
```

`colors/custom.lua` is removed.

## Theme contract

Each file in `colors/themes/` returns one of two shapes:

### A. Fully custom theme

```lua
return {
   name = 'Dracula+',
   scheme = { foreground = …, ansi = { … }, tab_bar = { … }, … },
   accents = { progress_indeterminate = '#…', tab_active_fg = '#…', … },
}
```

`scheme` is registered in WezTerm's `color_schemes` table under `name`; `name` is what `color_scheme` is set to when this theme is active.

### B. Built-in with accents

```lua
return {
   builtin = 'Tokyo Night',
   accents = { progress_indeterminate = '#…', tab_active_fg = '#…', … },
}
```

`builtin` must be a name returned by `wezterm.color.get_builtin_schemes()`. No registration; WezTerm uses its own scheme by that name.

### Accent keys

Fixed, exhaustive set:

| Key | Used by |
|---|---|
| `progress_indeterminate` | `config/tab.lua` |
| `progress_ok` | `config/tab.lua` |
| `progress_error` | `config/tab.lua` |
| `tab_active_fg` | `config/tab.lua` |
| `tab_inactive_fg` | `config/tab.lua` |
| `titlebar_bg` | `config/appearance.lua` |
| `command_palette_bg` | `config/appearance.lua` |
| `launcher_separator` | `utils/domain_launcher.lua` |

A theme may omit `accents` entirely or partially; missing keys are filled by the fallback (see below).

## `colors/init.lua` behaviour

```
THEMES   = { require('colors.themes.dracula_plus'), require('colors.themes.example_builtin'), … }
ACTIVE   = 'Dracula+'    -- single line; user edits to switch
```

`THEMES` is a list of theme tables. The registry keys them internally by `theme.name` (type A) or `theme.builtin` (type B). The local order in the list is irrelevant.

`ACTIVE` may be:
- A `name` of any type-A theme in `THEMES` → custom registered scheme is used.
- A `builtin` of any type-B theme in `THEMES` → WezTerm's built-in scheme is used, with the local file's accents.
- Any built-in WezTerm scheme name not declared in `THEMES` → used directly with fully derived accents.

Resolution:

1. Build an internal lookup `BY_NAME[theme.name or theme.builtin] = theme` from `THEMES`. On a duplicate key, raise.
2. If `BY_NAME[ACTIVE]` exists → that's the active local theme.
3. Else look up `wezterm.color.get_builtin_schemes()[ACTIVE]`. If absent, raise an explicit Lua error mentioning the missing name.

For fallback purposes, the resolved scheme is fetched once (from `theme.scheme` for type A, from `wezterm.color.get_builtin_schemes()[theme.builtin]` for type B, or from `get_builtin_schemes()[ACTIVE]` for the unregistered case). Lookups into nested fields like `scheme.tab_bar.inactive_tab.bg_color` are nil-safe — every step that may be missing falls through to the next fallback in the table below.

Exports:

- `color_scheme :: string` — the `ACTIVE` value (after validation), suitable for WezTerm's `color_scheme` option.
- `color_schemes :: table<string, scheme>` — every custom theme's `scheme` keyed by its `name`. Always registered, even non-active ones, so swapping `ACTIVE` doesn't require any other change.
- `accents :: { [accent_key]: string }` — the active theme's accents, with missing keys filled by fallback.

### Accent fallback

For a theme that omits an accent key (or for a built-in selected directly without any local file), values are derived from the resolved scheme:

| Accent | Fallback source |
|---|---|
| `progress_indeterminate` | `scheme.ansi[4]` (yellow slot) |
| `progress_ok` | `scheme.ansi[3]` (green slot) |
| `progress_error` | `scheme.ansi[2]` (red slot) |
| `tab_active_fg` | `scheme.tab_bar.active_tab.fg_color` if present, else `scheme.foreground` |
| `tab_inactive_fg` | `scheme.tab_bar.inactive_tab.fg_color` if present, else `scheme.foreground` |
| `titlebar_bg` | `scheme.tab_bar.inactive_tab.bg_color` if present, else `scheme.background` |
| `command_palette_bg` | `scheme.background` |
| `launcher_separator` | `scheme.brights[1]` |

The resolved scheme for fallback purposes:
- Custom theme → its own `scheme` table.
- Built-in → `wezterm.color.get_builtin_schemes()[name]`.

## Consumer migration

Single import everywhere: `local colors = require('colors')`.

| File | Before | After |
|---|---|---|
| `config/appearance.lua` | `colors = Theme.colorscheme`; `Theme.colors.surface0`; `Theme.colors.command_palette_bg` | `color_scheme = colors.color_scheme`; `color_schemes = colors.color_schemes`; `colors.accents.titlebar_bg`; `colors.accents.command_palette_bg` |
| `config/tab.lua` | `Theme.colors.peach/green/red`; `Theme.colorscheme.tab_bar.active_tab.fg_color`; same for `inactive_tab` | `colors.accents.progress_indeterminate/progress_ok/progress_error`; `colors.accents.tab_active_fg`; `colors.accents.tab_inactive_fg` |
| `utils/domain_launcher.lua` | `Theme.colors.overlay1` | `colors.accents.launcher_separator` |
| `colors/custom.lua` | exists | deleted |

`config/appearance.lua` no longer sets `colors = …` (the inline override). It sets `color_scheme` (a name) and `color_schemes` (a registration table) — both come from `colors/init.lua`.

## Out of scope

- OS-appearance-driven auto switching (light/dark by Windows mode).
- Runtime keybinding to swap themes.
- Domain icon colors in `config/domains.lua` — kept as-is; can be unified with accents in a separate refactor if needed.
- Adding more themes; only Dracula+ migrates and one minimal `example_builtin.lua` ships as a working template.

## CLAUDE.md update

Replace the "Color literals belong in `colors/custom.lua`" guidance with the new layout: themes live in `colors/themes/<name>.lua`; consumers import `require('colors')` and read from `accents`; switching themes is editing `ACTIVE` in `colors/init.lua`.

## Verification

No tests, no linter beyond stylua. After implementation:

1. `stylua --check .` from the repo root.
2. Reload WezTerm with `Ctrl+Shift+R`. Confirm Dracula+ looks identical to before.
3. Edit `ACTIVE` to a built-in (e.g. `'Builtin Solarized Dark'`). Reload. Confirm tabs/titlebar/launcher still render coherently with derived accents.
4. Edit `ACTIVE` to `'Dracula+'`. Reload. Confirm restored.
5. Watch the WezTerm log for runtime errors. Report unverified items explicitly.
