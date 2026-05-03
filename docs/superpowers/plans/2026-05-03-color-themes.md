# Color theming refactor — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the monolithic `colors/custom.lua` into a theme registry that supports both fully custom themes and any WezTerm built-in scheme, switchable via a single line.

**Architecture:** Two-layer module under `colors/`. Theme files in `colors/themes/<name>.lua` declare a `name` (custom) or `builtin` (WezTerm built-in) plus optional `scheme` and `accents` tables. `colors/init.lua` is the registry: it lists all themes, picks the active one via `ACTIVE`, registers custom schemes with WezTerm, derives missing accent fallbacks from the resolved scheme, and exports a flat API (`color_scheme`, `color_schemes`, `accents`, `ansi`).

**Tech Stack:** Lua, WezTerm (Windows). Verification: `stylua --check .` and a manual `Ctrl+Shift+R` reload by the user — there are no tests in this repo.

**Spec:** `docs/superpowers/specs/2026-05-03-color-themes-design.md`

---

## File structure

| Path | Action | Responsibility |
|---|---|---|
| `colors/themes/dracula_plus.lua` | Create | Carries the existing Dracula+ palette, scheme, and accents. Internal palette is a private table inside this file. |
| `colors/themes/example_builtin.lua` | Create | Working template showing how to use any WezTerm built-in scheme by name. Two lines. |
| `colors/init.lua` | Create | Theme registry, `ACTIVE` selector, accent/ansi resolution. Sole external entry point — every other module does `require('colors')`. |
| `colors/custom.lua` | Delete | Replaced by the registry + theme file. |
| `config/appearance.lua` | Modify | Switch from `colors = Theme.colorscheme` to `color_scheme + color_schemes`. Read accents via `colors.accents`. Absorb WIP: scrollbar/font/HSB/visual_bell/command_palette tweaks; remove `backdrops` import and the dangling comment. |
| `config/tab.lua` | Modify | Replace `Theme.colors.peach/green/red` and `Theme.colorscheme.tab_bar.*.fg_color` with `colors.accents.*`. |
| `utils/domain_launcher.lua` | Modify | Replace `Theme.colors.overlay1` with `colors.accents.launcher_separator`. |
| `config/domains.lua` | Modify | Replace `Theme.colors.{blue,yellow,green,mauve}` with `colors.ansi.{blue,yellow,green,magenta}`. Keep WIP priority shuffle. |
| `utils/backdrops.lua` | Delete (already removed on disk) | Stage the deletion together with this refactor. |
| `CLAUDE.md` | Modify | Replace the `colors/custom.lua` guidance with the new registry layout. |

`config/bindings.lua` is intentionally **not** part of this plan — its WIP changes are unrelated to colors and stay in the working tree for the user to commit separately.

---

## Notes on commits

The repo's commit style: short Russian subject with conventional prefix (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`). Sign-off: `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.

Each task ends with one commit. Intermediate commits leave the WezTerm config in a working state — old `colors/custom.lua` keeps existing alongside the new `colors/init.lua` until Task 8 deletes it.

---

## Task 1: Create `colors/themes/dracula_plus.lua`

**Files:**
- Create: `/mnt/c/Users/grind/.config/wezterm/colors/themes/dracula_plus.lua`

- [ ] **Step 1: Create the file with the migrated content**

Migration source: existing `colors/custom.lua`. The internal palette stays Catppuccin/Dracula-flavoured (private to this file). The `scheme` table inlines `palette.X` exactly where the old `Theme.colors.X` references stood. The `accents` table picks 8 semantic roles from the palette. WIP cosmetic tweaks for the active tab are folded in: `underline` removed (was `'Single'`), `strikethrough = false` (was `true`).

```lua
-- Dracula+ theme
-- stylua: ignore
local palette = {
    rosewater          = '#FF92DF',
    flamingo           = '#FF79C6',
    pink               = '#FF92DF',
    mauve              = '#C792EA',
    red                = '#FF5555',
    maroon             = '#FF6E6E',
    peach              = '#FFCB6B',
    yellow             = '#FFCB6B',
    green              = '#50FA7B',
    teal               = '#8BE9FD',
    sky                = '#A4FFFF',
    blue               = '#82AAFF',
    lavender           = '#D6ACFF',
    text               = '#F8F8F2',
    subtext1           = '#E0E0E0',
    subtext0           = '#BFBFBF',
    overlay2           = '#9A9A9A',
    overlay1           = '#7A7A7A',
    overlay0           = '#636363',
    surface2           = '#545454',
    surface1           = '#3B3B3B',
    surface0           = '#21222C',
    base               = '#000000',
    mantle             = '#ffffff',
    crust              = '#121212',
    command_palette_fg = '#b4befe',
    command_palette_bg = '#11111b',
    bright_green       = '#69FF94',
}

local scheme = {
    split = palette.subtext1,
    foreground = palette.text,
    background = palette.base,
    cursor_bg = '#ECEFF4',
    cursor_border = '#ECEFF4',
    cursor_fg = palette.base,
    selection_bg = '#44475A',
    visual_bell = palette.surface0,
    indexed = {
        [16] = palette.peach,
        [17] = palette.rosewater,
    },
    scrollbar_thumb = palette.overlay0,
    compose_cursor = palette.flamingo,
    ansi = {
        palette.surface0,
        palette.red,
        palette.green,
        palette.yellow,
        palette.blue,
        palette.mauve,
        palette.teal,
        palette.text,
    },
    brights = {
        palette.surface2,
        palette.maroon,
        palette.bright_green,
        palette.yellow,
        palette.lavender,
        palette.pink,
        palette.sky,
        palette.text,
    },
    tab_bar = {
        active_tab = {
            bg_color = palette.base,
            fg_color = palette.blue,
            italic = false,
            strikethrough = false,
        },
        inactive_tab = {
            bg_color = palette.surface0,
            fg_color = palette.overlay1,
        },
        inactive_tab_hover = {
            bg_color = palette.surface0,
            fg_color = palette.subtext1,
        },
        new_tab = {
            bg_color = palette.crust,
            fg_color = palette.overlay0,
        },
        new_tab_hover = {
            bg_color = palette.surface0,
            fg_color = palette.subtext1,
        },
        inactive_tab_edge = palette.base,
    },
}

local accents = {
    progress_indeterminate = palette.peach,
    progress_ok            = palette.green,
    progress_error         = palette.red,
    tab_active_fg          = palette.blue,
    tab_inactive_fg        = palette.overlay1,
    titlebar_bg            = palette.surface0,
    command_palette_bg     = palette.command_palette_bg,
    launcher_separator     = palette.overlay1,
}

return {
    name = 'Dracula+',
    scheme = scheme,
    accents = accents,
}
```

Notes on the migration:
- The bright `#69FF94` literal in `colorscheme.brights[3]` of the old file was the only hex inlined inside the colorscheme. It's promoted to `palette.bright_green` so the scheme refers to a named entry only.
- `accents` is the public API; `palette` is private and not returned.
- `-- stylua: ignore` is preserved on the palette block only — its hand-aligned columns must not be reformatted.

- [ ] **Step 2: Verify Lua loads and stylua passes**

Run from `/mnt/c/Users/grind/.config/wezterm/`:

```bash
stylua --check .
```

Expected: no diagnostics. If diagnostics appear in the new file, fix and re-run.

The file is not yet wired into `wezterm.lua`, so a runtime reload is not meaningful here.

- [ ] **Step 3: Commit**

```bash
git add colors/themes/dracula_plus.lua
git commit -m "$(cat <<'EOF'
refactor(colors): извлечь Dracula+ в colors/themes/dracula_plus.lua

Палитра, scheme и accents переезжают в отдельный файл по новому
контракту: palette приватная, наружу торчат только { name, scheme,
accents }. Поглощены WIP-правки активного таба (без underline,
strikethrough = false).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create `colors/themes/example_builtin.lua`

**Files:**
- Create: `/mnt/c/Users/grind/.config/wezterm/colors/themes/example_builtin.lua`

- [ ] **Step 1: Create the file**

A minimal type-B theme: just a `builtin` field, accents fully derived by `colors/init.lua`'s fallback. Serves as a working template for adding more built-ins later.

```lua
-- Example: any WezTerm built-in scheme can be activated by setting
-- ACTIVE in colors/init.lua to the value of `builtin` below.
-- Optionally add an `accents = { ... }` table to override individual
-- accent keys; missing keys fall back to values derived from the scheme's
-- ansi/brights/tab_bar.
return {
    builtin = 'Builtin Solarized Dark',
}
```

- [ ] **Step 2: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add colors/themes/example_builtin.lua
git commit -m "$(cat <<'EOF'
feat(colors): шаблон themes/example_builtin для built-in схем WezTerm

Минимальный пример темы типа B (built-in + опциональные accents).
Демонстрирует, что для подключения встроенной схемы достаточно
двух строк; accents автоматически выводятся из ansi/brights.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Create `colors/init.lua`

**Files:**
- Create: `/mnt/c/Users/grind/.config/wezterm/colors/init.lua`

- [ ] **Step 1: Create the registry**

```lua
local wezterm = require('wezterm')

local THEMES = {
    require('colors.themes.dracula_plus'),
    require('colors.themes.example_builtin'),
}

-- Active theme. Either a `name` from one of the THEMES entries (e.g. 'Dracula+'),
-- or any built-in WezTerm scheme name not declared in THEMES (e.g. 'Tokyo Night').
local ACTIVE = 'Dracula+'

local function nilsafe(t, ...)
    for _, k in ipairs({ ... }) do
        if type(t) ~= 'table' then
            return nil
        end
        t = t[k]
    end
    return t
end

-- Index THEMES by name (type A) or builtin (type B). Errors on missing key or duplicate.
local by_name = {}
for _, theme in ipairs(THEMES) do
    local key = theme.name or theme.builtin
    if not key then
        error('colors: theme is missing both `name` and `builtin`')
    end
    if by_name[key] then
        error("colors: duplicate theme key '" .. key .. "'")
    end
    by_name[key] = theme
end

-- Resolve the active theme into a concrete WezTerm scheme table.
local active = by_name[ACTIVE]
local resolved
if active then
    if active.scheme then
        resolved = active.scheme
    else
        local builtins = wezterm.color.get_builtin_schemes()
        resolved = builtins[active.builtin]
        if not resolved then
            error("colors: built-in scheme '" .. tostring(active.builtin) .. "' not found")
        end
    end
else
    local builtins = wezterm.color.get_builtin_schemes()
    resolved = builtins[ACTIVE]
    if not resolved then
        error(
            "colors: theme '"
                .. tostring(ACTIVE)
                .. "' is not registered locally and is not a built-in WezTerm scheme"
        )
    end
end

-- Register every type-A scheme so swapping ACTIVE never requires touching color_schemes.
local color_schemes = {}
for _, theme in ipairs(THEMES) do
    if theme.name and theme.scheme then
        color_schemes[theme.name] = theme.scheme
    end
end

-- Accent fallback derived from the resolved scheme; theme-provided accents win.
local fallback_accents = {
    progress_indeterminate = resolved.ansi[4],
    progress_ok            = resolved.ansi[3],
    progress_error         = resolved.ansi[2],
    tab_active_fg          = nilsafe(resolved, 'tab_bar', 'active_tab', 'fg_color') or resolved.foreground,
    tab_inactive_fg        = nilsafe(resolved, 'tab_bar', 'inactive_tab', 'fg_color') or resolved.foreground,
    titlebar_bg            = nilsafe(resolved, 'tab_bar', 'inactive_tab', 'bg_color') or resolved.background,
    command_palette_bg     = resolved.background,
    launcher_separator     = resolved.brights[1],
}

local accents = {}
local theme_accents = (active and active.accents) or {}
for k, v in pairs(fallback_accents) do
    accents[k] = theme_accents[k] or v
end

-- ANSI map: index 1..8 plus standard names.
local ansi_names = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' }
local ansi = {}
for i, color in ipairs(resolved.ansi) do
    ansi[i] = color
    ansi[ansi_names[i]] = color
end

return {
    color_scheme = ACTIVE,
    color_schemes = color_schemes,
    accents = accents,
    ansi = ansi,
}
```

- [ ] **Step 2: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add colors/init.lua
git commit -m "$(cat <<'EOF'
feat(colors): добавить colors/init.lua — реестр тем и активный селектор

Регистрирует все локальные темы из colors/themes/, разрешает активную
тему (кастомную или built-in) одной строкой ACTIVE, выводит fallback
accents из ansi/brights/tab_bar и экспортирует плоский API:
{ color_scheme, color_schemes, accents, ansi }.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Migrate `config/appearance.lua` (and absorb WIP)

**Files:**
- Modify: `/mnt/c/Users/grind/.config/wezterm/config/appearance.lua`

The file currently has uncommitted WIP. The end state combines the WIP intent with the new colors API.

- [ ] **Step 1: Replace the entire file content**

Final content (a single rewrite is simpler than tracking each delta — current state is short and entirely visible below):

```lua
local wezterm = require('wezterm')
local colors = require('colors')

return {
    -- cursor
    cursor_blink_ease_in = 'EaseOut',
    cursor_blink_ease_out = 'EaseOut',
    cursor_thickness = '0.1cell',
    default_cursor_style = 'BlinkingBar',
    cursor_blink_rate = 600,

    -- color scheme
    color_scheme = colors.color_scheme,
    color_schemes = colors.color_schemes,

    -- scrollbar
    enable_scroll_bar = true,

    -- command palette
    command_palette_bg_color = colors.accents.command_palette_bg,
    command_palette_font_size = 14,
    command_palette_rows = 10,

    window_decorations = 'RESIZE',

    initial_cols = 100,
    initial_rows = 20,
    window_padding = {
        left = '1pt',
        right = '1pt',
        top = '0',
        bottom = '0',
    },
    adjust_window_size_when_changing_font_size = false,
    window_close_confirmation = 'NeverPrompt',
    window_frame = {
        font = wezterm.font_with_fallback({ 'Segoe UI', 'Symbols Nerd Font Mono' }),
        font_size = 12,
        inactive_titlebar_bg = colors.accents.titlebar_bg,
        active_titlebar_bg = colors.accents.titlebar_bg,
    },
    inactive_pane_hsb = {
        saturation = 0.1,
        brightness = 0.2,
        hue = 0.7,
    },
    visual_bell = {
        fade_in_function = 'EaseIn',
        fade_in_duration_ms = 400,
        fade_out_function = 'EaseOut',
        fade_out_duration_ms = 250,
        target = 'CursorColor',
    },
    warn_about_missing_glyphs = false,
}
```

What changed from the WIP-on-disk version:
- `local backdrops = require('utils.backdrops')` and the `-- background = backdrops:initial_options(true),` comment are both gone (`backdrops` module no longer exists).
- `local Theme = require('colors.custom')` → `local colors = require('colors')`.
- `colors = Theme.colorscheme` → `color_scheme = colors.color_scheme`, plus a new `color_schemes = colors.color_schemes` line for registering custom schemes.
- `Theme.colors.command_palette_bg` → `colors.accents.command_palette_bg`.
- `Theme.colors.surface0` (used twice in `window_frame`) → `colors.accents.titlebar_bg`.

- [ ] **Step 2: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add config/appearance.lua
git commit -m "$(cat <<'EOF'
refactor(appearance): перевести на colors registry, поглотить WIP

Импорт сменился с colors.custom на colors. Вместо inline-таблицы
colors = Theme.colorscheme задаются color_scheme + color_schemes.
Цвета titlebar и command palette берутся из colors.accents.

Поглощены WIP: scroll bar включён, font_size 12, inactive_pane_hsb
brightness/hue, visual_bell fade_in_duration_ms 400, command palette
bg раскомментирован. Удалён мёртвый импорт utils.backdrops и висячий
комментарий, ссылающийся на удалённый модуль.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Migrate `config/tab.lua`

**Files:**
- Modify: `/mnt/c/Users/grind/.config/wezterm/config/tab.lua`

Two kinds of edits in this file:
1. The import: `local Theme = require('colors.custom')` → `local colors = require('colors')`.
2. Five reads of `Theme.colors.X` / `Theme.colorscheme.tab_bar.*.fg_color` → `colors.accents.X`.

- [ ] **Step 1: Swap the import**

Change line 3 of `config/tab.lua`:

```lua
local Theme = require('colors.custom')
```

to:

```lua
local colors = require('colors')
```

- [ ] **Step 2: Replace the three progress-icon color references**

In `format_progress` (currently around lines 55–75), replace:

```lua
return { icon = nf.md_dots_horizontal, color = Theme.colors.peach }
```

with:

```lua
return { icon = nf.md_dots_horizontal, color = colors.accents.progress_indeterminate }
```

Replace:

```lua
return { icon = pct_glyph(progress.Percentage), color = Theme.colors.green }
```

with:

```lua
return { icon = pct_glyph(progress.Percentage), color = colors.accents.progress_ok }
```

Replace:

```lua
return { icon = pct_glyph(progress.Error), color = Theme.colors.red }
```

with:

```lua
return { icon = pct_glyph(progress.Error), color = colors.accents.progress_error }
```

- [ ] **Step 3: Replace the two tab fg references**

Inside the `format-tab-title` handler, replace:

```lua
local tab_fg = tab.is_active and Theme.colorscheme.tab_bar.active_tab.fg_color
    or Theme.colorscheme.tab_bar.inactive_tab.fg_color
```

with:

```lua
local tab_fg = tab.is_active and colors.accents.tab_active_fg
    or colors.accents.tab_inactive_fg
```

- [ ] **Step 4: Verify no `Theme.` references remain in this file**

```bash
grep -n 'Theme\.' /mnt/c/Users/grind/.config/wezterm/config/tab.lua
```

Expected: no output.

- [ ] **Step 5: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 6: Commit**

```bash
git add config/tab.lua
git commit -m "$(cat <<'EOF'
refactor(tab): перейти на colors.accents вместо Theme.colors/colorscheme

Иконки прогресса (peach/green/red) и цвета текста таба заменены
на семантические accents: progress_indeterminate/ok/error,
tab_active_fg/inactive_fg.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Migrate `utils/domain_launcher.lua`

**Files:**
- Modify: `/mnt/c/Users/grind/.config/wezterm/utils/domain_launcher.lua`

- [ ] **Step 1: Swap the import**

Change:

```lua
local Theme = require('colors.custom')
```

to:

```lua
local colors = require('colors')
```

- [ ] **Step 2: Replace both `Theme.colors.overlay1` references**

There are two occurrences inside `build_choices`, both inside `wezterm.format` calls that wrap a separator label. Replace each:

```lua
{ Foreground = { Color = Theme.colors.overlay1 } },
```

with:

```lua
{ Foreground = { Color = colors.accents.launcher_separator } },
```

(`replace_all` is appropriate here.)

- [ ] **Step 3: Verify no `Theme.` references remain**

```bash
grep -n 'Theme\.' /mnt/c/Users/grind/.config/wezterm/utils/domain_launcher.lua
```

Expected: no output.

- [ ] **Step 4: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add utils/domain_launcher.lua
git commit -m "$(cat <<'EOF'
refactor(launcher): использовать colors.accents.launcher_separator

Замена Theme.colors.overlay1 на семантический accent — разделитель
групп в launcher не привязан к шейдовому имени палитры темы.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Migrate `config/domains.lua` (and absorb WIP priority shuffle)

**Files:**
- Modify: `/mnt/c/Users/grind/.config/wezterm/config/domains.lua`

WIP priority shuffle is already on disk. After the import swap and the four color references migrate, both changes ship together.

- [ ] **Step 1: Swap the import**

Change line 4:

```lua
local Theme = require('colors.custom')
```

to:

```lua
local colors = require('colors')
```

- [ ] **Step 2: Replace the kind colors**

Replace the `kinds` block (currently around lines 14–19, with WIP priority shuffle already applied) so it reads:

```lua
---@type table<DomainKind, DomainKindMeta>
-- stylua: ignore
local kinds = {
    ssh       = { priority = 30, icon = nf.cod_remote,             color = colors.ansi.blue,    label = 'SSH'   },
    wsl       = { priority = 10, icon = nf.cod_terminal_ubuntu,    color = colors.ansi.yellow,  label = 'WSL'   },
    ['local'] = { priority = 20, icon = nf.cod_terminal,           color = colors.ansi.green,   label = 'LOCAL' },
    unix      = { priority = 40, icon = nf.cod_server_environment, color = colors.ansi.magenta, label = 'UNIX'  },
}
```

Mapping rationale: domain icon colors were previously `Theme.colors.{blue, yellow, green, mauve}` — pure shade names. They map naturally to ANSI: `blue`→`ansi.blue`, `yellow`→`ansi.yellow`, `green`→`ansi.green`, `mauve`→`ansi.magenta` (slot 6 in the WezTerm ANSI standard). The hand-aligned columns are preserved (`-- stylua: ignore` already covers this block).

- [ ] **Step 3: Verify no `Theme.` references remain**

```bash
grep -n 'Theme\.' /mnt/c/Users/grind/.config/wezterm/config/domains.lua
```

Expected: no output.

- [ ] **Step 4: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add config/domains.lua
git commit -m "$(cat <<'EOF'
refactor(domains): иконки доменов через colors.ansi, поглотить WIP

Theme.colors.{blue,yellow,green,mauve} заменены на colors.ansi.X.
ANSI-имена стабильны во всех WezTerm-схемах — иконки доменов
автоматически адаптируются под активную тему.

Поглощена WIP-перестановка priorities: wsl=10, local=20, ssh=30.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Delete `colors/custom.lua` and stage `utils/backdrops.lua` deletion

**Files:**
- Delete: `/mnt/c/Users/grind/.config/wezterm/colors/custom.lua`
- Delete (already removed on disk): `/mnt/c/Users/grind/.config/wezterm/utils/backdrops.lua`

- [ ] **Step 1: Verify no consumer of `colors.custom` remains**

```bash
grep -rn "require.*colors\.custom\|require.*'colors/custom'" /mnt/c/Users/grind/.config/wezterm --include='*.lua'
```

Expected: no output. If anything matches, stop and migrate it before continuing.

- [ ] **Step 2: Delete the file**

```bash
rm /mnt/c/Users/grind/.config/wezterm/colors/custom.lua
```

- [ ] **Step 3: stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 4: Commit both deletions together**

`utils/backdrops.lua` was already deleted from the filesystem before this refactor began; staging it here keeps the cleanup in one logical commit.

```bash
git add -u colors/custom.lua utils/backdrops.lua
git status --short
```

Expected: `D colors/custom.lua` and `D utils/backdrops.lua` staged.

```bash
git commit -m "$(cat <<'EOF'
refactor(colors): удалить colors/custom.lua и utils/backdrops.lua

После миграции всех потребителей на colors registry монолитный
custom.lua больше никто не подключает. utils/backdrops.lua
давно не используется (последняя ссылка ушла из appearance.lua).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Update `CLAUDE.md`

**Files:**
- Modify: `/mnt/c/Users/grind/.config/wezterm/CLAUDE.md`

The "Module pattern" section currently ends with:

> Color literals belong in `colors/custom.lua` (`Theme.colors`) — the colorscheme and other modules reference them by name. Don't inline new hex values in `config/*.lua`; add a named entry to the palette and reference it.

Replace this paragraph with guidance for the new layout.

- [ ] **Step 1: Read the file to confirm current wording**

```bash
grep -n "colors/custom\|Theme.colors" /mnt/c/Users/grind/.config/wezterm/CLAUDE.md
```

Expected: matches the paragraph above.

- [ ] **Step 2: Replace the paragraph**

Replace exactly the paragraph quoted above with:

```markdown
Color theming lives in `colors/`. Themes are files in `colors/themes/<name>.lua` returning either `{ name, scheme, accents }` (fully custom) or `{ builtin, accents? }` (any WezTerm built-in scheme). The active theme is picked by editing the single `ACTIVE` line in `colors/init.lua` — its value can be a `name` from a custom theme, the `builtin` of a registered theme, or any built-in WezTerm scheme name not declared locally. Modules consume colors only through `local colors = require('colors')` and read `colors.accents.<role>` (semantic, e.g. `progress_ok`, `tab_active_fg`) or `colors.ansi.<name>` (e.g. `colors.ansi.blue`); never reach into `colors.color_schemes` or any theme's internal palette. Don't inline hex values in `config/*.lua` — add the role to a theme's `accents` (or extend the accent contract in `colors/init.lua` if a new role is needed).
```

- [ ] **Step 3: Verify no stale `colors/custom.lua` reference remains**

```bash
grep -n "colors/custom\|Theme\.colors" /mnt/c/Users/grind/.config/wezterm/CLAUDE.md
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs(claude): описать новую структуру цветовых тем

Раздел про colors/custom.lua заменён описанием реестра тем:
файлы в colors/themes/, активная тема одной строкой ACTIVE
в colors/init.lua, потребители читают colors.accents/colors.ansi.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Final verification

This task does not produce a commit. It collects the final smoke-checks and hands runtime validation back to the user.

- [ ] **Step 1: Repo-wide search for stale references**

```bash
grep -rn "colors\.custom\|require.*'colors/custom'\|Theme\.colors\|Theme\.colorscheme" /mnt/c/Users/grind/.config/wezterm --include='*.lua'
```

Expected: no output. Anything that matches is a missed migration.

```bash
grep -rn "backdrops" /mnt/c/Users/grind/.config/wezterm --include='*.lua'
```

Expected: no output.

- [ ] **Step 2: Final stylua check**

```bash
stylua --check .
```

Expected: clean.

- [ ] **Step 3: Hand off runtime verification to the user**

The agent cannot reload WezTerm. Tell the user explicitly that the change is **not runtime-verified**, and that they should:

1. Reload the running WezTerm with `Ctrl+Shift+R`. Confirm Dracula+ looks identical to before.
2. Edit `colors/init.lua`'s `ACTIVE` line to `'Builtin Solarized Dark'`. Reload. Confirm tabs/titlebar/launcher all render with derived accents (no nil errors in the WezTerm log overlay).
3. Edit `ACTIVE` back to `'Dracula+'`. Reload.

If any reload surfaces an error, capture the WezTerm log message — it points at the exact field that failed.

- [ ] **Step 4: Mark task #4 in the tracker complete**

Update task #4 ("Implementation plan + execution") to `completed` once the user reports a clean reload, or as the agent's final step if the user opts to verify later.
