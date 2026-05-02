# Domain Launcher — стилизация, сортировка, default

**Дата:** 2026-05-02
**Статус:** Approved (brainstorming)
**Затрагивает:** `utils/domain_launcher.lua`, `config/domains.lua`, `config/tab.lua`

## Цели

1. Привести двухступенчатое меню лаунчера к более насыщенному (TUI-rich) виду через единственное доступное API — `wezterm.gui.InputSelector` (per-row форматирование).
2. Сделать порядок групп (`kind`) и порядок записей внутри группы детерминированным и конфигурируемым.
3. Поддержать понятие default-домена с корректной проекцией в нативный `default_domain` / `default_prog` WezTerm.
4. Иконка `kind`, увиденная в лаунчере, должна автоматически наследоваться во вкладку после спавна.

## Ограничения и решения

- **InputSelector рендерит каждую запись как одну строку текста** — никаких рамок, колонок, multiline. Решение: вся «картина» строится из per-row `wezterm.format`-спанов с цветами и Nerd Font иконками.
- **local launch_menu entries после спавна неотличимы друг от друга** — все они в домене `local`, домена-владельца «cmd vs pwsh» нет. Решение: для local-вкладок icon резолвится по `foreground_process_name` (как сейчас); domain-icon resolver для kind=`local` возвращает `nil`.

## Архитектура и data flow

`config/domains.lua` остаётся единым источником правды. К текущим `entries` добавляются:

- локальная таблица `kinds` с метаданными,
- per-entry опциональное поле `default = true`.

Через `wezterm.GLOBAL` экспортируется:

- `domain_entries` — как сейчас, после фильтров;
- `domain_kinds` — новое.

`utils/domain_launcher.lua` и `config/tab.lua` читают эти глобалы. Никаких новых модулей не вводится.

## Data model

### `kinds`

```lua
---@class DomainKind
---@field priority integer    -- меньше = выше в меню
---@field icon string         -- Nerd Font glyph
---@field color string        -- ссылка на Theme.colors (заголовок группы + цвет иконки)
---@field label string        -- что писать в заголовке группы

local Theme = require('colors.custom')
local nf = wezterm.nerdfonts

local kinds = {
    ssh       = { priority = 10, icon = nf.cod_remote,             color = Theme.colors.blue,   label = 'SSH'   },
    wsl       = { priority = 20, icon = nf.cod_terminal_ubuntu,    color = Theme.colors.yellow, label = 'WSL'   },
    ['local'] = { priority = 30, icon = nf.cod_terminal,           color = Theme.colors.green,  label = 'LOCAL' },
    unix      = { priority = 40, icon = nf.cod_server_environment, color = Theme.colors.mauve,  label = 'UNIX'  },
}
```

Конкретные имена иконок ориентировочные; финальный выбор glyph'а — в фазе имплементации (опираясь на наличие в `wezterm.nerdfonts`).

### `DomainEntry`

Существующие поля сохраняются (`kind`, `name`, kind-specific). Добавляется опциональное:

- `default = true` — допускается ровно у одной entry. При нескольких — `wezterm.log_error('multiple default domains; keeping first: ' .. first.name)`, дальше используется первая по порядку обхода.

## Sorting

Вся логика сортировки — внутри `utils/domain_launcher.lua` (не в `config/domains.lua`):

1. Группы выводятся по `kinds[kind].priority` ASC.
2. Записи внутри группы сортируются `table.sort` по `name:lower()` (case-insensitive алфавит).
3. Запись с `default = true` всплывает первой в своей группе вне зависимости от alphabetical-порядка; визуально помечается ★.

## Default домен

В `config/domains.lua` после построения `filtered`:

```lua
local default = nil
for _, e in ipairs(filtered) do
    if e.default then
        if default then
            wezterm.log_error('multiple default domains; keeping ' .. default.name)
        else
            default = e
        end
    end
end
```

Проекция в возвращаемую таблицу конфига:

| Kind                   | Что присваивается                       |
| ---------------------- | --------------------------------------- |
| `ssh` / `wsl` / `unix` | `default_domain = default.name`         |
| `local`                | `default_prog = default.args`           |

`Config:append()` мерджит эти ключи в общий конфиг — изменений в `wezterm.lua` не нужно.

Существующий биндинг `Ctrl+Shift+T → SpawnTab('DefaultDomain')` начинает открывать default-entry автоматически.

## Launcher rendering — вариант C (rich)

Полностью внутри `utils/domain_launcher.lua`. Используется `wezterm.format` для labels.

### Stage 1 — Spawn mode

- Title: `  Spawn mode` (color = `Theme.colors.blue`).
- Choices с иконками:
  - ` New Tab` — синий;
  - ` Horizontal Split` — peach;
  - ` Vertical Split` — mauve.

Точные иконки берутся из `wezterm.nerdfonts.cod_*` (split_horizontal / split_vertical / add) — финальный выбор glyph'а в фазе имплементации.

### Stage 2 — Domain pick

- Title: `  Domain`.
- Каждая группа предваряется choice со спецсемантикой: `id` начинается с `__sep_`, callback его игнорирует. Label — `wezterm.format` спаны:

  ```
  ──  SSH ─────────────────────────────────
  ```

  цвет = `kind.color`, иконка = `kind.icon`.

- Запись:

  ```
     <icon>  <name>   <dim meta>   [★]
  ```

  - `<icon>` — `kind.icon`, окрашен в `kind.color`;
  - `<name>` — обычный текст (`Theme.colors.text`);
  - `<dim meta>` — выравнивается колонкой через `string.format('%-Ns', meta)`, где N = max(meta length) внутри текущей группы; цвет = `Theme.colors.overlay1`;
  - `[★]` — только для default, цвет = `Theme.colors.peach`.

### Источники dim meta по kind

| Kind  | Meta                                  |
| ----- | ------------------------------------- |
| ssh   | `username@remote_address`             |
| wsl   | `username · default_cwd`              |
| local | `args[1]` (basename без `.exe`)       |
| unix  | `socket_path` или пустая строка       |

## Tab title — domain icon precedence

`config/tab.lua` дополняется функцией:

```lua
local function get_domain_icon(domain_name)
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

Порядок резолюции внутри `format-tab-title`:

1. `progress` (если есть) — старший приоритет, как сейчас.
2. `get_domain_icon(tab.active_pane.domain_name)` — **новое**, выигрывает над процессом для ssh/wsl/unix.
3. `get_process_icon(tab.active_pane.foreground_process_name)` — текущий fallback.

Для kind=`local` resolver всегда возвращает `nil` — process icon (cmd vs pwsh) сохраняется. Это специально: разные local entries отличаются именно процессом, а не доменом.

Цвет иконки во вкладке окрашивается в `kind.color` (только для активной вкладки; для inactive используется `tab_fg` как сейчас).

## Colors / palette

Никаких новых hex-литералов. Все kind-цвета — ссылки на существующие `Theme.colors.{blue,yellow,green,mauve,peach,overlay1}`. CLAUDE.md правило соблюдено.

## CLAUDE.md update

Добавляется параграф **Domain taxonomy** (под секцией «Module pattern» или отдельно): где живёт `kinds`, как добавить новый kind (запись в `kinds` + опциональный filter + проекция в нативный domain если новая категория), как пометить default.

## .gitignore

Добавляется строка `.superpowers/` — каталог brainstorming companion'а не должен попадать в репозиторий.

## Out of scope (для последующих PR)

- запоминание «последнего выбранного» домена;
- per-entry keybinding для прямого вызова конкретной entry;
- hover-preview entry до выбора;
- per-entry icon override (например, разные иконки для разных SSH-хостов).

## Затрагиваемые файлы

- `config/domains.lua` — `kinds`, валидация и проекция `default`, новый global.
- `utils/domain_launcher.lua` — sorting, default-marker, `wezterm.format` labels (вариант C), стилизация stage 1.
- `config/tab.lua` — `get_domain_icon`, новый шаг в `format-tab-title`.
- `CLAUDE.md` — параграф про domain taxonomy.
- `.gitignore` — `.superpowers/`.

## Верификация

CLAUDE.md явно говорит: «No tests, no linter configured». Проверка ручная:

1. `stylua --check .` в `/mnt/c/Users/grind/.config/wezterm` — без замечаний; при необходимости `stylua .`.
2. WezTerm reload (`Ctrl+Shift+R`).
3. Глазами:
   - `Ctrl+Shift+F3` → stage 1: иконки и цвета на местах, header корректный.
   - Выбор режима → stage 2: группы в порядке `ssh → wsl → local → unix`, записи внутри по алфавиту, dim meta колонкой справа, ★ на default-entry (WSL:Ubuntu по дефолту).
   - `Ctrl+Shift+T` → открывает default-entry в новой вкладке.
   - Спавн SSH-домена → во вкладке icon `cod_remote` (синий).
   - Спавн WSL:Ubuntu → icon `cod_terminal_ubuntu` (yellow).
   - Спавн `Command Prompt` → icon `cod_terminal_cmd` (от process resolution, как раньше).

Никакое утверждение «работает» не делается до выполнения шага 3 на живом WezTerm.
