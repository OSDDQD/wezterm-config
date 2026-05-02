local wezterm = require('wezterm')
local act = wezterm.action

local M = {}

local kind_order = { 'ssh', 'wsl', 'local', 'unix' }
local kind_label = {
    ssh = 'SSH',
    wsl = 'WSL',
    ['local'] = 'LOCAL',
    unix = 'UNIX',
}

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

local function build_choices(entries)
    local groups = {}
    for _, e in ipairs(entries) do
        groups[e.kind] = groups[e.kind] or {}
        table.insert(groups[e.kind], e)
    end

    local choices = {}
    for _, kind in ipairs(kind_order) do
        local group = groups[kind]
        if group and #group > 0 then
            table.insert(choices, {
                id = '__sep_' .. kind,
                label = '── ' .. kind_label[kind] .. ' ──',
            })
            for _, e in ipairs(group) do
                table.insert(choices, {
                    id = kind .. ':' .. e.name,
                    label = e.name,
                })
            end
        end
    end
    return choices
end

local function pick_target(window, pane, mode)
    local entries = wezterm.GLOBAL.domain_entries or {}
    local choices = build_choices(entries)
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

---Two-step launcher action: pick spawn mode, then pick a domain entry.
---Bind it from config.bindings like any other action.
M.action = wezterm.action_callback(function(window, pane)
    window:perform_action(
        act.InputSelector({
            title = 'Spawn mode',
            fuzzy = true,
            choices = {
                { id = 'tab', label = 'New Tab' },
                { id = 'hsplit', label = 'Horizontal Split' },
                { id = 'vsplit', label = 'Vertical Split' },
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
