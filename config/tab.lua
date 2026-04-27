local wezterm = require('wezterm')
local nf = wezterm.nerdfonts
local agent_deck = require('config.agent_deck')

-- When true, render our own tab title with process icon (and agent status icon
-- when an OSC 1337 user var is set by Claude Code hooks running inside WSL).
local USE_CUSTOM_TAB_TITLE = true

-- Map foreground process name to a Nerd Font icon
local process_icons = {
    ['pwsh'] = nf.cod_terminal_powershell,
    ['powershell'] = nf.cod_terminal_powershell,
    ['cmd'] = nf.cod_terminal_cmd,
    ['wsl'] = nf.cod_terminal_ubuntu,
    ['wslhost'] = nf.cod_terminal_ubuntu,
    ['bash'] = nf.cod_terminal_linux,
    ['zsh'] = nf.cod_terminal_linux,
    ['node'] = nf.md_nodejs,
    ['python'] = nf.dev_python,
    ['python3'] = nf.dev_python,
    ['vim'] = nf.custom_vim,
    ['nvim'] = nf.custom_vim,
    ['git'] = nf.dev_git,
}

local function get_process_icon(proc)
    local name = proc:gsub('(.*[/\\])(.*)', '%2'):gsub('%.exe$', '')
    if process_icons[name] then
        return process_icons[name]
    end
    if name:match('^wsl') then
        return nf.cod_terminal_ubuntu
    end
    return nf.cod_terminal
end

local function get_dir_name(pane_title)
    if pane_title == '' then
        return '~'
    end
    local dir = pane_title:match('([^/\\]+)[/\\]?$')
    return dir or pane_title
end

if USE_CUSTOM_TAB_TITLE then
    wezterm.on('format-tab-title', function(tab)
        local dir = get_dir_name(tab.active_pane.title)
        local status = agent_deck.pick_tab_status(tab)
        local intensity = tab.is_active and 'Bold' or 'Half'

        if status then
            local s = agent_deck.STATUS[status]
            return wezterm.format({
                { Text = ' ' },
                { Foreground = { Color = s.color } },
                { Text = s.icon },
                { Foreground = { Color = 'default' } },
                { Attribute = { Intensity = intensity } },
                { Text = ' ' .. dir .. ' ' },
            })
        end

        local icon = get_process_icon(tab.active_pane.foreground_process_name)
        return wezterm.format({
            { Attribute = { Intensity = intensity } },
            { Text = ' ' .. icon .. ' ' .. dir .. ' ' },
        })
    end)
end

return {
    enable_tab_bar = true,
    tab_bar_at_bottom = true,
    use_fancy_tab_bar = true,
    show_new_tab_button_in_tab_bar = false,
    tab_max_width = 25,
    hide_tab_bar_if_only_one_tab = false,
    show_tab_index_in_tab_bar = false,
    switch_to_last_active_tab_when_closing_tab = true,
    show_close_tab_button_in_tabs = false,
}
