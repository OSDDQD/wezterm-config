---
name: verify-wezterm
description: Run all available checks on this WezTerm config — stylua format check, selene lint, and a headless WezTerm parse-check that loads the config without opening a GUI window. Use before claiming a config change works, or when the user asks to "verify the wezterm config", "validate the config", or finishes a refactor and wants confidence the config still loads.
---

# verify-wezterm

Runs the three static checks available in this repo. Report each as `✅`/`❌` with a one-line note. If any fail, do NOT claim the config is verified — fix or surface the failures first.

This is a **static** check. It catches Lua syntax errors, lint warnings, formatting drift, and option-validation errors that WezTerm rejects at config load. It does NOT catch runtime issues like font fallbacks at first use, plugin race conditions, or visual regressions — those still require a real reload (the user has rebound reload to `Alt+F5`).

## Run from repo root

```bash
cd /mnt/c/Users/grind/.config/wezterm
```

## 1. Format check

```bash
stylua --check .
```

Pass = silent, exit 0. Fail = lists files with formatting drift. The format-on-edit hook in `.claude/settings.json` should keep this clean automatically; a failure here means a file was edited outside Claude (vim, IDE, etc.) without running stylua.

To auto-fix:
```bash
stylua .
```

## 2. Lint

```bash
selene .
```

Pass = no findings (exit 0). Fail = exit 1 with warnings/errors at `file:line` locations. Configured via `selene.toml` at repo root (`std = "lua51"` — WezTerm embeds Lua 5.4 but selene 0.30's `cargo install` build can't resolve `lua54`; the lints we use here don't depend on the language version).

If selene isn't installed:
```bash
brew install selene          # macOS / linuxbrew
cargo install selene         # any platform with Rust toolchain
```

## 3. WezTerm parse-check (headless)

Loads the config in a real `wezterm.exe` invocation without opening a GUI window. Uses `show-keys --lua` because it forces full config evaluation (every option, every plugin `apply_to_config`) and dumps to stdout where we can discard it.

```bash
/mnt/c/Program\ Files/WezTerm/wezterm.exe \
  --config-file "$(wslpath -w "$(pwd)/wezterm.lua")" \
  show-keys --lua > /dev/null 2>&1
```

`wslpath -w` converts the WSL path `/mnt/c/Users/grind/.config/wezterm/wezterm.lua` to the Windows form `C:\Users\grind\.config\wezterm\wezterm.lua` that `wezterm.exe` (a Windows binary) needs.

- Exit 0 = config parses, all `require()`s resolve, no Lua errors, all options validated.
- Non-zero = something broke. Re-run without `> /dev/null 2>&1` to see the actual error message.

## Reporting

After running all three, summarise like:

```
✅ stylua — clean
✅ selene — clean
✅ wezterm parse — exit 0
```

Or, on failure:

```
✅ stylua — clean
❌ selene — config/tab.lua:47 unused variable `foo`
✅ wezterm parse — exit 0
```

Never claim the config is verified if any check failed.
