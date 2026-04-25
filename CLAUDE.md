# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal WezTerm config. Lua only. Targets Windows WezTerm running with a WSL:Ubuntu domain (user `osddqd`).

## Code style

- **3-space indentation** (not 2 or 4) — enforced by `.stylua.toml`. Some legacy files still use 4 spaces; run `stylua .` to normalize when convenient.
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

## Reserved keybindings

Don't bind `Alt+Ctrl+D`, `Alt+Ctrl+V`, or `Alt+Ctrl+H` — the `quick_domains.wezterm` plugin (loaded in `wezterm.lua`) claims them for domain attach / vsplit / hsplit.

## Verifying changes

No tests, no linter configured. Changes are validated by reloading the WezTerm config live (Ctrl+Shift+R) and watching for errors in the WezTerm log. Don't claim a change works without saying it hasn't been runtime-verified.
