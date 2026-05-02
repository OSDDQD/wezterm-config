# Domain Launcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Привести `utils/domain_launcher.lua` к стилю «rich TUI», добавить детерминированную сортировку (kind по priority, entries по алфавиту), поддержать default-домен на уровне entry и наследовать иконку kind во вкладку после спавна.

**Architecture:** Метаданные kind (priority/icon/color/label) и filter'ы остаются в `config/domains.lua`, который экспортирует две глобальные таблицы (`wezterm.GLOBAL.domain_entries`, `wezterm.GLOBAL.domain_kinds`) и проецирует default-entry в нативные `default_domain` / `default_prog`. Лаунчер и `format-tab-title` в `config/tab.lua` читают эти глобалы — никаких новых модулей не вводится.

**Tech Stack:** WezTerm Lua API (`wezterm.format`, `wezterm.GLOBAL`, `wezterm.nerdfonts`, `InputSelector`), stylua для форматирования, Hack Nerd Font Mono для иконок.

**Spec:** [`docs/superpowers/specs/2026-05-02-domain-launcher-design.md`](../specs/2026-05-02-domain-launcher-design.md)

**Verification model:** Тестов в проекте нет (CLAUDE.md: «No tests, no linter configured»). Каждая задача завершается **`stylua --check .`** + **live reload `Ctrl+Shift+R`** + явная проверка наблюдаемого поведения. TDD-шаги «write failing test» заменены на «manual verification».

---

## Preconditions

**P0. Зафиксировать текущее состояние ветки**

В рабочей копии есть несвязанные uncommitted изменения (`config/*.lua`, `wezterm.lua`, удалённые `general.lua`/`launch.lua`, untracked `utils/domain_launcher.lua`). Каждая задача ниже коммитит **только** свои файлы — но если вы не зафиксируете остальное сначала, изменения накопятся в рабочей копии. Перед стартом:

```bash
cd /mnt/c/Users/grind/.config/wezterm
git status                 # посмотреть что лежит
git add -p                 # отобрать что закомитить отдельно
git commit -m '...'        # зафиксировать unrelated work
# или: git stash push -m 'pre-domain-launcher work-in-progress'
```

Финальное состояние перед Task 1: `git status` чист либо содержит только не относящееся к нашему рефакторингу. Все Task'и ниже добавляют **только конкретно перечисленные в них файлы**.

---

## File Structure

| Файл | Ответственность | Действие |
|---|---|---|
| `config/domains.lua` | Источник entries + kind metadata + проекция default | Modify |
| `utils/domain_launcher.lua` | UI лаунчера: stage 1 / stage 2, sort, format | Modify (rewrite logic; сохранить сигнатуру `M.action`) |
| `config/tab.lua` | format-tab-title: progress → domain → process | Modify (новая step domain icon) |
| `CLAUDE.md` | Описание domain taxonomy | Modify (новый параграф) |

Никаких новых файлов не создаётся.

---

## Task 1: Объявить kind metadata и экспонировать через GLOBAL

**Files:**
- Modify: `config/domains.lua`

**Цель:** Появляется `wezterm.GLOBAL.domain_kinds` с полным набором метаданных. Поведение лаунчера и табов не меняется (читателей пока нет).

- [ ] **Step 1.1: Импортировать `wezterm.nerdfonts` и палитру**

В `config/domains.lua` под существующей строкой `local wezterm = require('wezterm')` добавить:

```lua
local nf = wezterm.nerdfonts
local Theme = require('colors.custom')
```

- [ ] **Step 1.2: Объявить таблицу `kinds`**

Сразу после блока `---@alias DomainKind ...` (между строками 3 и 13 текущего файла) вставить:

```lua
---@class DomainKind
---@field priority integer    -- меньше = выше в меню
---@field icon string         -- Nerd Font glyph
---@field color string        -- цвет заголовка группы и иконки
---@field label string        -- надпись в заголовке группы

-- stylua: ignore
local kinds = {
    ssh       = { priority = 10, icon = nf.cod_remote,             color = Theme.colors.blue,   label = 'SSH'   },
    wsl       = { priority = 20, icon = nf.cod_terminal_ubuntu,    color = Theme.colors.yellow, label = 'WSL'   },
    ['local'] = { priority = 30, icon = nf.cod_terminal,           color = Theme.colors.green,  label = 'LOCAL' },
    unix      = { priority = 40, icon = nf.cod_server_environment, color = Theme.colors.mauve,  label = 'UNIX'  },
}
```

> Ключ `local` — зарезервированное слово Lua, обязательно `['local']`. Блок отмечен `-- stylua: ignore` — выравнивание колонок руками.

- [ ] **Step 1.3: Экспонировать через GLOBAL**

После строки `wezterm.GLOBAL.domain_entries = filtered` (текущая строка 64) добавить:

```lua
wezterm.GLOBAL.domain_kinds = kinds
```

- [ ] **Step 1.4: Stylua check**

```bash
stylua --check .
```

Ожидание: тихий выход (код 0).

- [ ] **Step 1.5: Live reload + проверка глобала**

В WezTerm: `Ctrl+Shift+R`. Открыть debug overlay `Ctrl+Alt+L` (mod.SUPER_REV+F6 в текущем биндинге — `act.ShowDebugOverlay`), в Lua REPL внутри overlay набрать:

```lua
return wezterm.GLOBAL.domain_kinds.ssh.label
```

Ожидание: `SSH`.

- [ ] **Step 1.6: Commit**

```bash
git add config/domains.lua
git commit -m "feat(domains): добавить kind metadata (priority/icon/color/label)"
```

---

## Task 2: Default-флаг на entry + проекция в нативный конфиг

**Files:**
- Modify: `config/domains.lua`

**Цель:** Одна entry помечена `default = true`. После reload `Ctrl+Shift+T` (`SpawnTab('DefaultDomain')`) открывает её. Если несколько — `wezterm.log_error` и берётся первая.

- [ ] **Step 2.1: Пометить WSL:Ubuntu как default**

В блоке статичных entries (строки 16–22 текущего файла) дописать `default = true` к WSL-записи:

```lua
{ kind = 'wsl', name = 'WSL:Ubuntu', distribution = 'Ubuntu', username = 'osddqd', default_cwd = '/home/osddqd', default = true },
```

- [ ] **Step 2.2: Найти default после фильтрации**

После цикла, заполняющего `filtered` (строки 56–61), и перед проекцией в native domain tables добавить блок:

```lua
local default_entry = nil
for _, e in ipairs(filtered) do
    if e.default then
        if default_entry then
            wezterm.log_error(
                ('multiple default domains; keeping %s, ignoring %s'):format(default_entry.name, e.name)
            )
        else
            default_entry = e
        end
    end
end
```

- [ ] **Step 2.3: Спроецировать default в нативные ключи**

В конце файла, в блоке `return { ... }` (текущие строки 102–107), добавить вычисление `default_domain` / `default_prog` перед `return`:

```lua
local result = {
    ssh_domains = ssh_domains,
    wsl_domains = wsl_domains,
    unix_domains = unix_domains,
    launch_menu = launch_menu,
}

if default_entry then
    if default_entry.kind == 'local' then
        result.default_prog = default_entry.args
    else
        result.default_domain = default_entry.name
    end
end

return result
```

(Старая прямая `return { ... }` удаляется.)

- [ ] **Step 2.4: Stylua check**

```bash
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 2.5: Live reload + проверка default**

`Ctrl+Shift+R`, затем:

1. `Ctrl+Shift+T` — должна открыться вкладка с WSL:Ubuntu (PS1/`$` shell, домен `WSL:Ubuntu` в debug overlay через `wezterm.mux.get_active_workspace()` или просто визуально по приглашению).
2. Запуск нового окна WezTerm — первая вкладка тоже WSL:Ubuntu.

- [ ] **Step 2.6: Commit**

```bash
git add config/domains.lua
git commit -m "feat(domains): default-флаг на entry, проекция в default_domain/default_prog"
```

---

## Task 3: Сортировка в `utils/domain_launcher.lua`

**Files:**
- Modify: `utils/domain_launcher.lua`

**Цель:** Группы выводятся по `priority` ASC, записи внутри — alphabetical (case-insensitive); запись с `default = true` всплывает первой в группе. Визуальное оформление пока **не** меняется (пока обычный текст, как сейчас) — только порядок.

- [ ] **Step 3.1: Удалить хардкод `kind_order` и `kind_label`**

Строки 6–12 текущего файла:

```lua
local kind_order = { 'ssh', 'wsl', 'local', 'unix' }
local kind_label = {
    ssh = 'SSH',
    wsl = 'WSL',
    ['local'] = 'LOCAL',
    unix = 'UNIX',
}
```

Удалить целиком — теперь источник правды `wezterm.GLOBAL.domain_kinds`.

- [ ] **Step 3.2: Переписать `build_choices` с использованием kind metadata + сортировкой**

Заменить функцию `build_choices` (текущие строки 30–54) на:

```lua
local function build_choices(entries, kinds)
    -- группировка
    local groups = {}
    for _, e in ipairs(entries) do
        groups[e.kind] = groups[e.kind] or {}
        table.insert(groups[e.kind], e)
    end

    -- упорядочиваем kind по priority (отбрасываем kind, у которых нет metadata)
    local kind_order = {}
    for kind, _ in pairs(groups) do
        if kinds[kind] then
            table.insert(kind_order, kind)
        else
            wezterm.log_error('domain_launcher: unknown kind ' .. tostring(kind))
        end
    end
    table.sort(kind_order, function(a, b)
        return kinds[a].priority < kinds[b].priority
    end)

    -- внутри группы: default первый, остальные по name:lower()
    local function sort_group(group)
        table.sort(group, function(a, b)
            if a.default and not b.default then
                return true
            end
            if b.default and not a.default then
                return false
            end
            return a.name:lower() < b.name:lower()
        end)
    end

    local choices = {}
    for _, kind in ipairs(kind_order) do
        local group = groups[kind]
        sort_group(group)
        local meta = kinds[kind]
        table.insert(choices, {
            id = '__sep_' .. kind,
            label = '── ' .. meta.label .. ' ──',
        })
        for _, e in ipairs(group) do
            table.insert(choices, {
                id = kind .. ':' .. e.name,
                label = e.name,
            })
        end
    end
    return choices
end
```

- [ ] **Step 3.3: Прокинуть `kinds` в вызов `build_choices`**

В функции `pick_target` (текущие строки 56–82) заменить:

```lua
local entries = wezterm.GLOBAL.domain_entries or {}
local choices = build_choices(entries)
```

на:

```lua
local entries = wezterm.GLOBAL.domain_entries or {}
local kinds = wezterm.GLOBAL.domain_kinds or {}
local choices = build_choices(entries, kinds)
```

- [ ] **Step 3.4: Stylua check**

```bash
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 3.5: Live reload + визуальная проверка порядка**

`Ctrl+Shift+R`, затем `Ctrl+Shift+F3 → New Tab`. В списке:

1. Сначала группа `── SSH ──` со всеми SSH-хостами в alphabetical order.
2. Затем `── WSL ──` с `WSL:Ubuntu` (с пометкой default? — пока нет, добавим в Task 6; сейчас просто проверяем, что она первая в группе).
3. Затем `── LOCAL ──` с `Command Prompt`, `PowerShell`, `PowerShell v1` в alphabetical.
4. (Группа UNIX отсутствует, потому что unix entries нет — ок.)

- [ ] **Step 3.6: Commit**

```bash
git add utils/domain_launcher.lua
git commit -m "feat(launcher): сортировка групп по priority + alphabetical + default first"
```

---

## Task 4: Stage 1 — иконки и цвет в picker'е режимов спавна

**Files:**
- Modify: `utils/domain_launcher.lua`

**Цель:** Меню «Spawn mode» получает заголовок с иконкой ` Spawn mode` и цветные иконки на каждой строке: ` New Tab`, ` Horizontal Split`, ` Vertical Split`.

- [ ] **Step 4.1: Импортировать nerdfonts и палитру**

В верхней части файла под `local act = wezterm.action` добавить:

```lua
local nf = wezterm.nerdfonts
local Theme = require('colors.custom')
```

- [ ] **Step 4.2: Использовать `wezterm.format` для title и choices stage 1**

Заменить тело `M.action` (текущие строки 86–105). Полная замена:

```lua
M.action = wezterm.action_callback(function(window, pane)
    local title = wezterm.format({
        { Foreground = { Color = Theme.colors.blue } },
        { Text = ' ' .. nf.cod_terminal_powershell .. '  Spawn mode' },
    })

    local function mode_choice(id, icon, icon_color, text)
        return {
            id = id,
            label = wezterm.format({
                { Foreground = { Color = icon_color } },
                { Text = icon .. '  ' },
                { Foreground = { Color = Theme.colors.text } },
                { Text = text },
            }),
        }
    end

    window:perform_action(
        act.InputSelector({
            title = title,
            fuzzy = true,
            choices = {
                mode_choice('tab',    nf.cod_add,              Theme.colors.blue,  'New Tab'),
                mode_choice('hsplit', nf.cod_split_horizontal, Theme.colors.peach, 'Horizontal Split'),
                mode_choice('vsplit', nf.cod_split_vertical,   Theme.colors.mauve, 'Vertical Split'),
            },
            action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
                if not id then
                    return
                end
                pick_target(inner_window, inner_pane, id)
            end),
        }),
        pane
    )
end)
```

> Если `nf.cod_split_horizontal` / `cod_split_vertical` / `cod_add` не существуют в Hack Nerd Font (визуально — пустые квадраты), временно заменить на проверенные: `nf.md_view_split_horizontal`, `nf.md_view_split_vertical`, `nf.md_plus`. Финальный выбор — после Step 4.4 проверки.

- [ ] **Step 4.3: Stylua check**

```bash
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 4.4: Live reload + визуал**

`Ctrl+Shift+R`, затем `Ctrl+Shift+F3`. Проверить:
- Заголовок «  Spawn mode» — синий, иконка терминала видна.
- Три choice'а с иконками: ` New Tab` (синий), ` Horizontal Split` (peach), ` Vertical Split` (mauve).

Если какая-то иконка отрисована как пустой квадрат — заменить glyph согласно подсказке в Step 4.2 и повторить.

- [ ] **Step 4.5: Commit**

```bash
git add utils/domain_launcher.lua
git commit -m "feat(launcher): stylized stage 1 (Spawn mode) — иконки и цвета"
```

---

## Task 5: Stage 2 — цветные separator'ы групп

**Files:**
- Modify: `utils/domain_launcher.lua`

**Цель:** Заголовки групп в picker'е доменов получают цветную иконку + цветное название: `── 󰒋 SSH ─────────────────────────`. Сами entries пока без украшений (добавим в Task 6).

- [ ] **Step 5.1: Заменить генерацию separator label в `build_choices`**

В функции `build_choices` (после Task 3) заменить существующее построение separator (строка `label = '── ' .. meta.label .. ' ──'`) на форматированный label:

```lua
table.insert(choices, {
    id = '__sep_' .. kind,
    label = wezterm.format({
        { Foreground = { Color = Theme.colors.overlay1 } },
        { Text = '── ' },
        { Foreground = { Color = meta.color } },
        { Text = meta.icon .. '  ' .. meta.label },
        { Foreground = { Color = Theme.colors.overlay1 } },
        { Text = ' ──────────────────────' },
    }),
})
```

- [ ] **Step 5.2: Title stage 2 тоже стилизовать**

В `pick_target` заменить:

```lua
title = 'Domain (' .. mode .. ')',
```

на:

```lua
title = wezterm.format({
    { Foreground = { Color = Theme.colors.blue } },
    { Text = ' ' .. nf.cod_terminal .. '  Domain (' .. mode .. ')' },
}),
```

- [ ] **Step 5.3: Stylua check**

```bash
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 5.4: Live reload + визуал**

`Ctrl+Shift+R`, `Ctrl+Shift+F3 → tab`. В списке должны быть видны:
- Заголовок «  Domain (tab)» — синий.
- `── 󰒋 SSH ──────────────────────` — серые тире, blue иконка+SSH.
- `──  WSL ──────────────────────` — yellow.
- `──  LOCAL ────────────────────` — green.

Записи внутри групп — пока обычный белый текст.

- [ ] **Step 5.5: Commit**

```bash
git add utils/domain_launcher.lua
git commit -m "feat(launcher): stylized separators в stage 2 — цветные icon/label"
```

---

## Task 6: Stage 2 — иконки, dim-метаданные, default-маркер на entries

**Files:**
- Modify: `utils/domain_launcher.lua`

**Цель:** Каждая строка entry становится формата `  <icon>  <name>   <dim meta>   [★]`. `<dim meta>` выровнен колонкой по максимуму внутри группы. ★ только у default.

- [ ] **Step 6.1: Реализовать сборщик dim-meta по kind**

В верхней части файла (после require'ов) добавить:

```lua
local function entry_meta(entry)
    if entry.kind == 'ssh' then
        local user = entry.username or ''
        local host = entry.remote_address or entry.name
        if user ~= '' then
            return user .. '@' .. host
        end
        return host
    elseif entry.kind == 'wsl' then
        local user = entry.username or ''
        local cwd = entry.default_cwd or ''
        if user ~= '' and cwd ~= '' then
            return user .. ' · ' .. cwd
        end
        return user ~= '' and user or cwd
    elseif entry.kind == 'local' then
        local arg = (entry.args and entry.args[1]) or ''
        return arg:gsub('(.*[/\\])(.*)', '%2'):gsub('%.exe$', '')
    elseif entry.kind == 'unix' then
        return entry.socket_path or ''
    end
    return ''
end
```

- [ ] **Step 6.2: Реализовать построение entry label с выравниванием**

В `build_choices` после `sort_group(group)` посчитать колоночные метрики и собрать formatted labels. Заменить блок:

```lua
for _, e in ipairs(group) do
    table.insert(choices, {
        id = kind .. ':' .. e.name,
        label = e.name,
    })
end
```

на:

```lua
-- pre-compute max widths внутри группы
local max_name = 0
local metas = {}
for _, e in ipairs(group) do
    if #e.name > max_name then
        max_name = #e.name
    end
    metas[e] = entry_meta(e)
end

for _, e in ipairs(group) do
    local meta = metas[e]
    local pad_after_name = string.rep(' ', max_name - #e.name + 3)
    local spans = {
        { Foreground = { Color = meta_kind.color } },  -- icon color
        { Text = '  ' .. meta_kind.icon .. '  ' },
        { Foreground = { Color = Theme.colors.text } },
        { Text = e.name },
        { Text = pad_after_name },
        { Foreground = { Color = Theme.colors.overlay1 } },
        { Text = meta },
    }
    if e.default then
        table.insert(spans, { Text = '   ' })
        table.insert(spans, { Foreground = { Color = Theme.colors.peach } })
        table.insert(spans, { Text = '★' })
    end
    table.insert(choices, {
        id = kind .. ':' .. e.name,
        label = wezterm.format(spans),
    })
end
```

> Внимание: в этом блоке используется переменная `meta_kind`, которая должна указывать на `kinds[kind]`. Перед этим блоком в цикле `for _, kind in ipairs(kind_order) do` уже есть `local meta = kinds[kind]` (см. Task 5 / 3) — переименуйте её в `meta_kind` чтобы не конфликтовать с per-entry `meta` (строка `entry_meta(e)`):
>
> ```lua
> for _, kind in ipairs(kind_order) do
>     local group = groups[kind]
>     sort_group(group)
>     local meta_kind = kinds[kind]
>     -- separator (используем meta_kind вместо meta)
>     ...
> end
> ```
>
> Для separator'ы из Task 5 — там тоже заменить `meta` → `meta_kind`.

- [ ] **Step 6.3: Stylua check**

```bash
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 6.4: Live reload + визуал**

`Ctrl+Shift+R`, `Ctrl+Shift+F3 → tab`. Каждая entry рендерится:

- `  󰒋  AIRNET           root@1.2.3.4` (blue icon, dim meta серым)
- `  󰒋  AV/CH            av@chouse`
- ... (отсортировано по имени)
- `  WSL:Ubuntu       osddqd · /home/osddqd   ★` (yellow icon, peach звезда)
- `    Command Prompt  cmd` (green icon)
- `    PowerShell      pwsh`

Меркуры выровнены колонкой; default-маркер виден; SSH без user'а тоже работает (показывает только host).

- [ ] **Step 6.5: Commit**

```bash
git add utils/domain_launcher.lua
git commit -m "feat(launcher): rich entry rendering — icon, dim meta, default star"
```

---

## Task 7: Domain icon наследуется во вкладку

**Files:**
- Modify: `config/tab.lua`

**Цель:** В табе с открытым SSH-доменом (например, `WSVPS`) во вкладке отображается иконка `cod_remote` синего цвета. Local domain ничего не меняется (cmd.exe → cmd icon). Progress overlay по-прежнему имеет старший приоритет.

- [ ] **Step 7.1: Добавить функцию `get_domain_icon`**

В `config/tab.lua` ниже функции `get_process_icon` (после строки 67) добавить:

```lua
---@param domain_name string|nil
---@return string|nil icon, string|nil color
local function get_domain_icon(domain_name)
    if not domain_name or domain_name == '' then
        return nil
    end
    local entries = wezterm.GLOBAL.domain_entries or {}
    local kinds = wezterm.GLOBAL.domain_kinds or {}
    for _, e in ipairs(entries) do
        if e.name == domain_name and e.kind ~= 'local' and kinds[e.kind] then
            return kinds[e.kind].icon, kinds[e.kind].color
        end
    end
    return nil
end
```

- [ ] **Step 7.2: Встроить domain-резолвер в `format-tab-title`**

В обработчике `wezterm.on('format-tab-title', function(tab) ... end)` (текущие строки 78–103) после блока progress (после строки 96 `end`) и перед блоком process icon (строка 98) вставить domain-step:

```lua
local domain_icon, domain_color = get_domain_icon(tab.active_pane.domain_name)
if domain_icon then
    return wezterm.format({
        { Text = ' ' },
        { Foreground = { Color = tab.is_active and domain_color or tab_fg } },
        { Text = domain_icon },
        { Foreground = { Color = tab_fg } },
        { Attribute = { Intensity = intensity } },
        { Text = ' ' .. dir .. ' ' },
    })
end
```

- [ ] **Step 7.3: Stylua check**

```bash
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 7.4: Live reload + визуал**

`Ctrl+Shift+R`, затем:

1. `Ctrl+Shift+F3 → tab → SSH → выбрать любой SSH-хост` — во вкладке должна появиться иконка `󰒋` (cod_remote) синего цвета (если активная) или приглушённого (если inactive).
2. `Ctrl+Shift+F3 → tab → WSL → WSL:Ubuntu` — иконка ` ` (cod_terminal_ubuntu) yellow.
3. `Ctrl+Shift+F3 → tab → LOCAL → Command Prompt` — иконка `` (cod_terminal_cmd) от process_icons (НЕ overridden).
4. Запустить `npm install` или другой долгий процесс с OSC progress — progress glyph должен выигрывать у domain icon.

- [ ] **Step 7.5: Commit**

```bash
git add config/tab.lua
git commit -m "feat(tab): domain icon выигрывает у process icon для ssh/wsl/unix"
```

---

## Task 8: Документация в CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Цель:** Будущий читатель проекта (или агент в новой сессии) понимает, как устроена domain taxonomy и как добавить новый kind/entry/default.

- [ ] **Step 8.1: Добавить раздел «Domain taxonomy»**

В `CLAUDE.md` после раздела «Module pattern» (между ним и «Reserved keybindings») вставить:

```markdown
## Domain taxonomy

`config/domains.lua` is the single source of truth for everything spawnable. Two tables:

- `entries` — concrete spawnable items (`{ kind, name, ...kind-specific fields }`). One entry may carry `default = true`; that entry becomes WezTerm's default (`default_domain` for ssh/wsl/unix, `default_prog` for local).
- `kinds` — metadata per `kind`: `priority` (group order in launcher; smaller = higher), `icon` (Nerd Font glyph used in launcher and tab bar), `color` (palette ref for the group separator and the domain icon in tabs), `label` (group heading text).

Both are exposed as `wezterm.GLOBAL.domain_entries` / `wezterm.GLOBAL.domain_kinds`. The launcher (`utils/domain_launcher.lua`) and the tab title resolver (`config/tab.lua`) read these globals — no other modules depend on them.

Adding a new kind: register it in `kinds`, then make sure the projection block at the end of `config/domains.lua` knows how to map filtered entries of that kind into the appropriate native option (e.g., a new `unix` entry projects into `unix_domains`).

Adding a new entry: append to `entries`. Sort order in the launcher is automatic (group by `kind.priority`, alphabetical inside, default first).

Marking a different default: set `default = true` on exactly one entry; remove from the previous one.
```

- [ ] **Step 8.2: Stylua check (skip — markdown не форматируется stylua, но прогоним для целостности)**

```bash
stylua --check .
```

Ожидание: код 0 (markdown не затрагивается).

- [ ] **Step 8.3: Визуальная вычитка**

Открыть `CLAUDE.md` в редакторе/просмотрщике, убедиться что:
- параграф вставлен в правильное место;
- списки и code-fence'ы корректны;
- упомянуты все три действия (add kind / add entry / change default).

- [ ] **Step 8.4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): описание domain taxonomy и операций над ней"
```

---

## Task 9: Финальный walkthrough

**Files:** ничего не модифицируется — только ручная сверка.

**Цель:** Пройти полный verification list из спеки на одной живой сессии WezTerm.

- [ ] **Step 9.1: Stylua полная проверка**

```bash
cd /mnt/c/Users/grind/.config/wezterm
stylua --check .
```

Ожидание: код 0.

- [ ] **Step 9.2: Чистый старт WezTerm**

Закрыть WezTerm полностью (включая все окна). Запустить заново. Первая вкладка — WSL:Ubuntu (default).

- [ ] **Step 9.3: Default keybind**

`Ctrl+Shift+T` → новая вкладка с WSL:Ubuntu.

- [ ] **Step 9.4: Launcher — порядок и стиль**

`Ctrl+Shift+F3`:
- Stage 1: «  Spawn mode» (синий header), 3 choice'а с цветными иконками.
- `→ New Tab`.
- Stage 2: header «  Domain (tab)» (синий).
- Группы в порядке `SSH → WSL → LOCAL`.
- Внутри SSH — alphabetical, внутри LOCAL — `Command Prompt → PowerShell → PowerShell v1`.
- `WSL:Ubuntu` помечен `★` peach-цветом.
- Каждая entry имеет иконку kind.color и dim-meta (`user@host` / `user · cwd` / `cmd|pwsh|powershell`).

- [ ] **Step 9.5: Tab icons — все три kind'а**

Для каждого открыть вкладку через лаунчер и проверить иконку:
- Любой SSH (например `WSVPS`) — `󰒋` (cod_remote) синяя.
- `WSL:Ubuntu` — ` ` (cod_terminal_ubuntu) yellow.
- `Command Prompt` — `` (cod_terminal_cmd) — от process resolution, не от domain.
- `PowerShell` — `` (cod_terminal_powershell).

- [ ] **Step 9.6: Зафиксировать состояние (если есть hanging untracked/modified)**

Если в процессе тестирования что-то осталось (мусорные файлы, ничего не должно быть):

```bash
git status
```

Ожидание: всё чисто, либо вернуться и закомитить.

- [ ] **Step 9.7: Финальный отчёт**

Сводка в чате: какие коммиты добавлены, какие пункты verification list пройдены. Если что-то не подтверждено руками — явно сказать.

---

## Self-review checklist

(прогнал перед сохранением плана; найденные проблемы исправлены инлайн)

**1. Spec coverage:**
- §3 Architecture/data flow → Task 1
- §4 Data model (kind + default flag) → Task 1, Task 2
- §5 Sorting → Task 3
- §6 Default → Task 2
- §7 Launcher rendering (stage 1 / separators / entries) → Tasks 4, 5, 6
- §8 Tab title precedence → Task 7
- §9 Colors / palette → соблюдено в кодовых блоках Task 1/4/5/6/7
- §10 CLAUDE.md update → Task 8
- §11 .gitignore → уже сделано в коммите спеки `6756c6e`
- §12 Verification → Task 9

**2. Placeholder scan:** проверено — конкретные glyph'ы названы; «если не существует — заменить» рядом стоит как осознанная fallback-инструкция, не TBD.

**3. Type/name consistency:**
- `wezterm.GLOBAL.domain_kinds` — одинаково в Task 1 (объявление), Task 3 (чтение в build_choices), Task 7 (чтение в get_domain_icon).
- `kinds[kind].priority/icon/color/label` — поля одинаковые во всех использованиях.
- `default_entry` — локальная переменная только в Task 2; снаружи не утекает.
- `meta_kind` vs `meta` — конфликт имён прямо разрешён в подсказке Step 6.2.
- `get_domain_icon` возвращает `(icon, color)` — Task 7 это оба использует.

**4. Frequent commits:** один таск — один коммит, ничего лишнего не закидывается. P0 предупреждает про unrelated WIP.
