# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal WezTerm config. Lua only. Targets Windows WezTerm running with a WSL:Ubuntu domain (user `osddqd`).

## Code style

- **4-space indentation** — enforced by `.stylua.toml`. Run `stylua --check .` to verify; `stylua .` to fix.
- Single quotes for strings, `snake_case` for names.
- EmmyLua annotations (`---@class`, `---@return`) where types help.
- Never reformat blocks marked `-- stylua: ignore` — manual alignment in keytables and color palettes is intentional.

## Module pattern

`wezterm.lua` is a thin entry point that chains config modules via a fluent builder:

```lua
local config = Config:init()
    :append(require('config.appearance'))
    :append(require('config.bindings'))
    -- ...
    .options
```

Each `config/<name>.lua` returns a flat data table keyed by WezTerm option names. To add new options, create a new module (or edit an existing one) and chain it with `:append(require('config.<name>'))` in `wezterm.lua` — do not inline options in `wezterm.lua`. `Config:append()` warns on duplicate keys.

Third-party plugins are wired in `config/plugins.lua` (which exports `apply(config)`) and applied to the built config table at the end of `wezterm.lua`. Add new plugins inside `M.apply`, not in the entry point.

Color theming lives in `colors/`. Themes are files in `colors/themes/<name>.lua` returning either `{ name, scheme, accents }` (fully custom) or `{ builtin, accents? }` (any WezTerm built-in scheme). The active theme is picked by editing the single `ACTIVE` line in `colors/init.lua` — its value can be a `name` from a custom theme, the `builtin` of a registered theme, or any built-in WezTerm scheme name not declared locally. Modules consume colors only through `local colors = require('colors')` and read `colors.accents.<role>` (semantic, e.g. `progress_ok`, `tab_active_fg`), `colors.ansi.<name>` (e.g. `colors.ansi.blue`), or `colors.foreground`/`colors.background`; never reach into `colors.color_schemes` or any theme's internal palette. Don't inline hex values in `config/*.lua` — add the role to a theme's `accents` (or extend the accent contract in `colors/init.lua` if a new role is needed).

## Domain taxonomy

`config/domains.lua` is the single source of truth for everything spawnable. Two tables:

- `entries` — concrete spawnable items (`{ kind, name, ...kind-specific fields }`). One entry may carry `default = true`; that entry becomes WezTerm's default (`default_domain` for ssh/wsl/unix, `default_prog` for local).
- `kinds` — metadata per `kind`: `priority` (group order in launcher; smaller = higher), `icon` (Nerd Font glyph used in launcher and tab bar), `color` (palette ref for the group separator and the domain icon in tabs), `label` (group heading text).

Both are exposed as `wezterm.GLOBAL.domain_entries` / `wezterm.GLOBAL.domain_kinds`. The launcher (`utils/domain_launcher.lua`) and the tab title resolver (`config/tab.lua`) read these globals — no other modules depend on them.

Adding a new kind: register it in `kinds`, then make sure the projection block at the end of `config/domains.lua` knows how to map filtered entries of that kind into the appropriate native option (e.g., a new `unix` entry projects into `unix_domains`).

Adding a new entry: append to `entries`. Sort order in the launcher is automatic (group by `kind.priority`, alphabetical inside, default first).

Marking a different default: set `default = true` on exactly one entry; remove from the previous one.

## Reserved keybindings

Don't bind `Alt+Ctrl+D`, `Alt+Ctrl+V`, or `Alt+Ctrl+H` — the `quick_domains.wezterm` plugin (loaded via `config/plugins.lua`) claims them for domain attach / vsplit / hsplit.

## Verifying changes

No tests, no linter configured. Changes are validated by reloading the WezTerm config live (Ctrl+Shift+R) and watching for errors in the WezTerm log. Don't claim a change works without saying it hasn't been runtime-verified.
