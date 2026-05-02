local wezterm = require('wezterm')
local act = wezterm.action
local nf = wezterm.nerdfonts
local Theme = require('colors.custom')

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

local function pick_target(window, pane, mode)
    local entries = wezterm.GLOBAL.domain_entries or {}
    local kinds = wezterm.GLOBAL.domain_kinds or {}
    local choices = build_choices(entries, kinds)
    window:perform_action(
        act.InputSelector({
            title = 'Domain (' .. mode .. ')',
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
            { Text = icon .. '  ' },
            { Foreground = { Color = Theme.colors.text } },
            { Text = text },
        }),
    }
end

---Two-step launcher action: pick spawn mode, then pick a domain entry.
---Bind it from config.bindings like any other action.
M.action = wezterm.action_callback(function(window, pane)
    local title = wezterm.format({
        { Foreground = { Color = Theme.colors.blue } },
        { Text = nf.cod_terminal_powershell .. '  Spawn mode' },
    })

    window:perform_action(
        act.InputSelector({
            title = title,
            fuzzy = true,
            choices = {
                mode_choice('tab', nf.cod_add, Theme.colors.blue, 'New Tab'),
                mode_choice(
                    'hsplit',
                    nf.cod_split_horizontal,
                    Theme.colors.peach,
                    'Horizontal Split'
                ),
                mode_choice('vsplit', nf.cod_split_vertical, Theme.colors.mauve, 'Vertical Split'),
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
