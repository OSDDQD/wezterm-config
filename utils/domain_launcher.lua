local wezterm = require('wezterm')
local act = wezterm.action
local nf = wezterm.nerdfonts
local colors = require('colors')

local M = {}

local function spawn_action(mode, entry)
    local spawn
    if entry.kind == 'local' then
        spawn = { args = entry.args, cwd = entry.cwd, domain = { DomainName = 'local' } }
    else
        spawn = { domain = { DomainName = entry.name } }
    end
    if mode == 'tab' then
        return act.SpawnCommandInNewTab(spawn)
    elseif mode == 'hsplit' then
        return act.SplitHorizontal(spawn)
    elseif mode == 'vsplit' then
        return act.SplitVertical(spawn)
    end
end

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
        local meta_kind = kinds[kind]
        table.insert(choices, {
            id = '__sep_' .. kind,
            label = wezterm.format({
                { Foreground = { Color = colors.accents.launcher_separator } },
                { Foreground = { Color = meta_kind.color } },
                { Text = meta_kind.icon .. '  ' .. meta_kind.label },
                { Foreground = { Color = colors.accents.launcher_separator } },
            }),
        })

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
                { Foreground = { Color = meta_kind.color } },
                { Text = '  ' .. meta_kind.icon .. '  ' },
                { Foreground = { Color = colors.foreground } },
                { Text = e.name },
                { Text = pad_after_name },
                { Foreground = { Color = colors.accents.launcher_separator } },
                { Text = meta },
            }
            if e.default then
                table.insert(spans, { Text = '   ' })
                table.insert(spans, { Foreground = { Color = colors.ansi.yellow } })
                table.insert(spans, { Text = '★' })
            end
            table.insert(choices, {
                id = kind .. ':' .. e.name,
                label = wezterm.format(spans),
            })
        end
    end
    return choices
end

local function pick_target(window, pane, mode)
    local entries = wezterm.GLOBAL.domain_entries or {}
    local kinds = wezterm.GLOBAL.domain_kinds or {}
    local choices = build_choices(entries, kinds)
    window:perform_action(
        act.InputSelector({
            title = wezterm.format({
                { Foreground = { Color = colors.ansi.blue } },
                { Text = ' ' .. nf.cod_terminal .. '  Domain (' .. mode .. ')' },
            }),
            fuzzy = true,
            choices = choices,
            action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
                if not id or id:match('^__sep_') then
                    return
                end
                local kind, name = id:match('^([^:]+):(.+)$')
                if not kind or not name then
                    return
                end
                for _, e in ipairs(entries) do
                    if e.kind == kind and e.name == name then
                        inner_window:perform_action(spawn_action(mode, e), inner_pane)
                        return
                    end
                end
            end),
        }),
        pane
    )
end

local function mode_choice(id, icon, icon_color, text)
    return {
        id = id,
        label = wezterm.format({
            { Foreground = { Color = icon_color } },
            { Text = ' ' .. icon .. '  ' },
            { Foreground = { Color = colors.foreground } },
            { Text = text },
        }),
    }
end

---Two-step launcher action: pick spawn mode, then pick a domain entry.
---Bind it from config.bindings like any other action.
M.action = wezterm.action_callback(function(window, pane)
    local title = wezterm.format({
        { Foreground = { Color = colors.ansi.blue } },
        { Text = nf.cod_terminal_powershell .. '  Spawn mode' },
    })

    window:perform_action(
        act.InputSelector({
            title = title,
            fuzzy = true,
            choices = {
                mode_choice('tab', nf.md_plus_box_outline, colors.ansi.blue, 'New Tab'),
                mode_choice(
                    'hsplit',
                    nf.cod_split_horizontal,
                    colors.ansi.yellow,
                    'Horizontal Split'
                ),
                mode_choice('vsplit', nf.cod_split_vertical, colors.ansi.magenta, 'Vertical Split'),
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

return M
