# Refactor: better category split, dedup, simpler entry point

## Context

The config has grown into a few overlapping buckets. An audit found:
- A semantic duplicate (`hyperlink_rules` lives in `general.lua`, but a dedicated `hyperlinks.lua` already exists).
- Performance/render keys (`max_fps`, `front_end`, `webgpu_*`) buried in `appearance.lua`, mixed with truly visual options.
- A "general.lua" bucket holding 3 unrelated concerns.
- Hardcoded color hex literals in `appearance.lua` that bypass the palette in `colors/custom.lua`.
- Plugin loading + apply directly in the entry point.
- Several blocks of commented-out dead code.

Goal: cleaner module boundaries, no duplication, palette as single source of truth for colors. No behavior change for the user — wezterm should look and act identically after the refactor.

## Out of scope

- Adding EmmyLua annotations to all 10 missing files — busywork; doesn't affect behavior or comprehension.
- Replacing the `Config:append()` metatable builder with a flat merge — works, well-tested, not a blocker.
- Lazy-loading `math.randomseed` in `utils/backdrops.lua` — backdrops are gated off by `focus_mode = true`; not exercised.

## Changes

### 1. Move `hyperlink_rules` to `config/hyperlinks.lua`
- `config/general.lua:13` calls `wezterm.default_hyperlink_rules()` and assigns to `hyperlink_rules`. Move that line into the table returned by `config/hyperlinks.lua` (which currently returns `{}`).
- Drop the `local wezterm = require('wezterm')` from `general.lua` if nothing else uses it after the move.

### 2. Extract render performance keys → new `config/performance.lua`
- Pull from `config/appearance.lua:8-10`: `max_fps`, `front_end`, `webgpu_power_preference`, `webgpu_preferred_adapter` (and `animation_fps` if present).
- New module `config/performance.lua` returns those keys as a flat table.
- Wire into `wezterm.lua` via `:append(require('config.performance'))`.
- Note: `scrollback_lines` and `status_update_interval` stay with behavior — they're not GPU/render-tier perf knobs.

### 3. Rename `config/general.lua` → `config/behavior.lua`
- After step 1, the file holds only behavior options (`automatically_reload_config`, `exit_behavior`, `exit_behavior_messaging`, `audible_bell`, `status_update_interval`, `scrollback_lines`). Rename the file and update the require in `wezterm.lua`.
- Delete `config/general.lua` (the rename is `git mv`-equivalent: new file written, old file removed).

### 4. Replace inline color hex with palette refs in `config/appearance.lua`
- Add `local Theme = require('colors.custom')` at the top.
- Map current literals (lines 32-33, 47):
  - `'#b4befe'`, `'#11111b'`, `'#000'` → `Theme.colors.<name>`.
  - **Verification step before swapping**: read `colors/custom.lua` and confirm a matching key exists. If a literal isn't in the palette, add it to `Theme.colors` with a descriptive name rather than leaving it inline.
- This makes the palette the single source of truth and lets future theme tweaks happen in one place.

### 5. Extract plugin loading → new `config/plugins.lua`
- Move `wezterm.plugin.require('https://github.com/DavidRR-F/quick_domains.wezterm')` and its `apply_to_config(config, { keys = ... })` call out of `wezterm.lua:16-21`.
- New module exports a function `apply(config)` that takes the built config table and runs all plugin `apply_to_config` calls on it.
- `wezterm.lua` becomes:
  ```lua
  local Config = require('config')
  local plugins = require('config.plugins')

  local config = Config:init()
     :append(require('config.appearance'))
     :append(require('config.behavior'))
     :append(require('config.bindings'))
     :append(require('config.domains'))
     :append(require('config.fonts'))
     :append(require('config.hyperlinks'))
     :append(require('config.launch'))
     :append(require('config.performance'))
     :append(require('config.tab'))
     .options

  plugins.apply(config)
  return config
  ```
- Future plugins go through the same `plugins.apply` step instead of accreting in the entry point.

### 6. Delete commented-out dead code
- `config/bindings.lua:62-65` — 4 commented tab-number key entries.
- `config/bindings.lua:70-73` — 1 commented secondary mouse binding.
- `config/tab.lua:50, 56` — 2 commented color overrides in the tab title formatter.
- `colors/custom.lua:74` — commented `background = Theme.colors.crust`.

## Files touched

- **NEW**: `config/behavior.lua`, `config/performance.lua`, `config/plugins.lua`
- **DELETE**: `config/general.lua`
- **MODIFY**: `config/hyperlinks.lua`, `config/appearance.lua`, `config/bindings.lua`, `config/tab.lua`, `colors/custom.lua`, `wezterm.lua`

## Verification

1. `stylua --check .` exits 0 (no formatting drift introduced).
2. `grep -r "config\.general" .` returns nothing (no orphan require).
3. `grep -r "wezterm.plugin" wezterm.lua` returns nothing (plugin moved out).
4. User reloads WezTerm in-place (Ctrl+Shift+R) and confirms:
   - No log warnings (`Config:append()` would log on key collisions).
   - Tab bar styling unchanged.
   - Hyperlinks still clickable in panes.
   - `Alt+Ctrl+D/V/H` still attach/vsplit/hsplit via quick_domains.
   - GPU backend selection still works (no rendering glitches).
5. `git diff --stat` should show roughly: 3 files added, 1 deleted, ~6 modified, with line counts that reflect moves rather than rewrites.
