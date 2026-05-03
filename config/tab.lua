local wezterm = require('wezterm')
local nf = wezterm.nerdfonts
local colors = require('colors')
local attention = require('config.plugins').attention

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

-- wezterm-attention: indicator glyphs and tab background tints.
-- We bypass `attention.wrap_title_formatter` because it hard-prepends
-- `N: ` to every tab title. Instead we read the cached pane state via
-- `attention.get_attention(pane_id)` and render the glyph + tint ourselves.
-- Values mirror the plugin's defaults — keep in sync if either side changes.
local THINKING_FRAMES = { '◌', '◔', '◑', '◕' }
local ATTENTION_GLYPH = { stop = '✓', notify = '!', review = '◆' }
local ATTENTION_TINT = {
    thinking = '#1c1730',
    stop = '#12271c',
    notify = '#240f16',
    review = '#1a1a0c',
}
-- Higher number = higher priority (matches plugin's ordering).
local ATTENTION_PRIORITY = { thinking = 1, review = 2, stop = 3, notify = 4 }

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
        return { icon = nf.md_dots_horizontal, color = colors.accents.progress_indeterminate }
    end
    if type(progress) == 'table' then
        if progress.Percentage ~= nil then
            return { icon = pct_glyph(progress.Percentage), color = colors.accents.progress_ok }
        end
        if progress.Error ~= nil then
            return { icon = pct_glyph(progress.Error), color = colors.accents.progress_error }
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

local function get_dir_name(pane_title)
    if pane_title == '' then
        return '~'
    end
    local dir = pane_title:match('([^/\\]+)[/\\]?$')
    return dir or pane_title
end

--- Resolve the highest-priority attention state across all panes in a tab.
---@param tab table TabInformation passed to format-tab-title
---@return string|nil glyph, string|nil tint
local function format_attention(tab)
    local best_type, best_frame, best_priority = nil, nil, 0
    for _, p in ipairs(tab.panes or {}) do
        local atype, frame = attention.get_attention(p.pane_id)
        local prio = atype and ATTENTION_PRIORITY[atype] or 0
        if prio > best_priority then
            best_type, best_frame, best_priority = atype, frame, prio
        end
    end
    if not best_type then
        return nil
    end
    local glyph
    if best_type == 'thinking' then
        glyph = THINKING_FRAMES[((best_frame or 0) % #THINKING_FRAMES) + 1]
    else
        glyph = ATTENTION_GLYPH[best_type]
    end
    return glyph, ATTENTION_TINT[best_type]
end

if USE_CUSTOM_TAB_TITLE then
    -- We deliberately don't use `attention.wrap_title_formatter`: it hard-prepends
    -- `N: ` (tab index) to the title with no opt-out. Instead we ask the plugin's
    -- public API for the cached state and render indicator + tint ourselves.
    wezterm.on('format-tab-title', function(tab)
        local dir = get_dir_name(tab.active_pane.title)
        local progress = format_progress(tab.active_pane.progress)
        local tab_fg = tab.is_active and colors.accents.tab_active_fg
            or colors.accents.tab_inactive_fg

        local att_glyph, att_tint = format_attention(tab)
        local prefix = att_glyph and (att_glyph .. ' ') or ''

        local accent = progress

        local elements
        if accent then
            elements = {
                { Text = ' ' .. prefix },
                { Foreground = { Color = accent.color } },
                { Text = accent.icon },
                { Foreground = { Color = tab_fg } },
                { Text = ' ' .. dir .. ' ' },
            }
        else
            local domain_icon, domain_color = get_domain_icon(tab.active_pane.domain_name)
            if domain_icon then
                elements = {
                    { Text = ' ' .. prefix },
                    { Foreground = { Color = tab.is_active and domain_color or tab_fg } },
                    { Text = domain_icon },
                    { Foreground = { Color = tab_fg } },
                    { Text = ' ' .. dir .. ' ' },
                }
            else
                local icon = get_process_icon(tab.active_pane.foreground_process_name)
                elements = {
                    { Text = ' ' .. prefix .. icon .. ' ' .. dir .. ' ' },
                }
            end
        end

        if att_tint then
            table.insert(elements, 1, { Background = { Color = att_tint } })
        end
        return wezterm.format(elements)
    end)
end

return {
    enable_tab_bar = true,
    tab_bar_at_bottom = false,
    use_fancy_tab_bar = true,
    show_new_tab_button_in_tab_bar = false,
    tab_max_width = 30,
    hide_tab_bar_if_only_one_tab = false,
    show_tab_index_in_tab_bar = false,
    switch_to_last_active_tab_when_closing_tab = true,
    show_close_tab_button_in_tabs = false,
}
