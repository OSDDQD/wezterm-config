local wezterm = require('wezterm')
local nf = wezterm.nerdfonts
local Theme = require('colors.custom')

-- When true, render our own tab title with process icon.
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

-- 1/8-th circle slices for ConEmu-style progress (OSC 9;4) percentage rendering.
-- stylua: ignore
local PCT_GLYPHS = {
    nf.md_circle_slice_1, nf.md_circle_slice_2, nf.md_circle_slice_3, nf.md_circle_slice_4,
    nf.md_circle_slice_5, nf.md_circle_slice_6, nf.md_circle_slice_7, nf.md_circle_slice_8,
}

local function pct_glyph(pct)
    local slot = math.max(0, math.min(7, math.floor((pct or 0) / 12)))
    return PCT_GLYPHS[slot + 1]
end

--- Map pane:get_progress() value to an icon and color, or nil when there is no progress.
---@param progress any value of tab.active_pane.progress (nightly WezTerm only)
---@return table|nil { icon = string, color = string }
local function format_progress(progress)
    if not progress or progress == 'None' then
        return nil
    end
    if progress == 'Indeterminate' then
        return { icon = nf.md_dots_horizontal, color = Theme.colors.peach }
    end
    if type(progress) == 'table' then
        if progress.Percentage ~= nil then
            return { icon = pct_glyph(progress.Percentage), color = Theme.colors.green }
        end
        if progress.Error ~= nil then
            return { icon = pct_glyph(progress.Error), color = Theme.colors.red }
        end
    end
    return nil
end

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
        local progress = format_progress(tab.active_pane.progress)
        local intensity = tab.is_active and 'Bold' or 'Half'
        local tab_fg = tab.is_active and Theme.colorscheme.tab_bar.active_tab.fg_color
            or Theme.colorscheme.tab_bar.inactive_tab.fg_color

        local accent = progress

        if accent then
            return wezterm.format({
                { Text = ' ' },
                { Foreground = { Color = accent.color } },
                { Text = accent.icon },
                { Foreground = { Color = tab_fg } },
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
