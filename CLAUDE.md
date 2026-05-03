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

Third-party plugins are wired in `config/plugins.lua` (which exports `apply(config)`) and applied to the built config table at the end of `wezterm.lua`. Add new plugins inside `M.apply`, not in the entry point. When a plugin exposes a runtime API that other config modules need (e.g. `wezterm-attention`'s pane state), assign the plugin handle to `M.<name>` so consumers can `require('config.plugins').<name>` — that's the only sanctioned cross-module bridge.

## Color theming

`colors/` is the only place that knows about colors. Layout:

- `colors/init.lua` — registry. Lists every available theme in the `THEMES` table, picks the active one via `ACTIVE`, registers all type-A themes with WezTerm, and exports the consumer API.
- `colors/themes/<name>.lua` — one theme per file. Two shapes are accepted: type A `{ name, scheme, accents }` (a fully custom WezTerm colorscheme) or type B `{ builtin, accents? }` (a WezTerm built-in scheme by name with optional accent overrides). Inside the file the author may keep a private palette of named hex literals for composing `scheme` and `accents`; nothing outside the file references that palette.

To **switch** the active theme, edit the single `ACTIVE` line in `colors/init.lua`. The value is either a `name` from a registered theme, the `builtin` of a registered theme, or any built-in WezTerm scheme name not declared locally (in which case accents are auto-derived from the scheme's ansi/brights/tab_bar).

To **add** a new local theme, drop a file in `colors/themes/<name>.lua` AND add it to the `THEMES` list in `colors/init.lua` — the registry is explicit, not file-system-scanned. Wrap each `require('colors.themes.<file>')` in parens; Lua 5.4's `require()` returns two values (module + filepath) and the trailing call without parens injects the filepath as a stray third entry, which breaks the registry.

Modules consume colors only through `local colors = require('colors')` and read one of:
- `colors.accents.<role>` — semantic accent (e.g. `progress_ok`, `tab_active_fg`, `launcher_separator`). Used for app-specific UI affordances. The full key list lives in `colors/init.lua`'s `fallback_accents`.
- `colors.ansi.<name>` — one of the standard 8 ANSI hues (`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`). Use this for shade-driven choices that should track any theme (e.g. domain icon colors).
- `colors.foreground` / `colors.background` — the active scheme's text/background.

Never reach into `colors.color_schemes` or any theme's internal palette from a consumer module. Don't inline hex values in `config/*.lua` or `utils/*.lua` — extend a theme's `accents`, or add a new accent role to the contract in `colors/init.lua` if no existing role fits.

## Domain taxonomy

`config/domains.lua` is the single source of truth for everything spawnable. Two tables:

- `entries` — concrete spawnable items (`{ kind, name, ...kind-specific fields }`). One entry may carry `default = true`; that entry becomes WezTerm's default (`default_domain` for ssh/wsl/unix, `default_prog` for local).
- `kinds` — metadata per `kind`: `priority` (group order in launcher; smaller = higher), `icon` (Nerd Font glyph used in launcher and tab bar), `color` (palette ref for the group separator and the domain icon in tabs), `label` (group heading text).

Both are exposed as `wezterm.GLOBAL.domain_entries` / `wezterm.GLOBAL.domain_kinds`. The launcher (`utils/domain_launcher.lua`) and the tab title resolver (`config/tab.lua`) read these globals — no other modules depend on them.

Adding a new kind: register it in `kinds`, then make sure the projection block at the end of `config/domains.lua` knows how to map filtered entries of that kind into the appropriate native option (e.g., a new `unix` entry projects into `unix_domains`).

Adding a new entry: append to `entries`. Sort order in the launcher is automatic (group by `kind.priority`, alphabetical inside, default first).

Marking a different default: set `default = true` on exactly one entry; remove from the previous one.

## Reserved keybindings

Don't bind `Alt+B` — the `wezterm-attention` plugin (loaded via `config/plugins.lua`) claims it for the review-toggle action.

## wezterm-attention integration

`config/plugins.lua` loads `wezterm-attention` with `renderer = 'manual'` so `config/tab.lua` keeps control over `format-tab-title`. The plugin handle is re-exported as `M.attention`; `config/tab.lua` reads pane state through `attention.get_attention(pane_id)` and renders the indicator glyph + background tint itself (it deliberately bypasses `attention.wrap_title_formatter`, which would hard-prepend the tab index to every title).

Markers live in WSL at `$HOME/.local/state/wezterm-attention/$WEZTERM_PANE`. WezTerm runs on Windows and reads them via the UNC redirector `\\wsl.localhost\Ubuntu\...`; the path must be a long-bracket string (`[[...]]`) so the backslashes stay literal — the Windows CRT needs them to recognise the UNC prefix.

`config/tab.lua` keeps local copies of the plugin's `THINKING_FRAMES`, `ATTENTION_GLYPH`, `ATTENTION_TINT`, and `ATTENTION_PRIORITY` constants. If you change one side, keep the other in sync — there's no compile-time check.

## Verifying changes

No automated tests. Static checks: `stylua --check .` (format) and `selene .` (lint). The `/verify-wezterm` skill bundles those plus a headless `wezterm.exe` parse-check. For runtime verification, the user reloads the WezTerm config live (`Alt+F5`) and watches for errors in the WezTerm log — don't claim a change works without saying it hasn't been runtime-verified.
