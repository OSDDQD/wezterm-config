local wezterm = require('wezterm')
local colors = require('colors')

-- Вкладки как у Ghostty (GTK/libadwaita): заголовок = title терминала
-- (OSC 0/2 от шелла и приложений), полоса вкладок видна только при 2+ вкладках.

-- bell-features = title: вкладка с BEL помечается 🔔, пока на неё не переключишься
local function bell_key(pane_id)
    return 'bell_' .. tostring(pane_id)
end

wezterm.on('bell', function(window, pane)
    local tab = pane:tab()
    if window:active_tab():tab_id() ~= (tab and tab:tab_id()) then
        wezterm.GLOBAL[bell_key(pane:pane_id())] = true
    end
end)

local function tab_has_bell(tab)
    local has = false
    for _, p in ipairs(tab.panes) do
        local key = bell_key(p.pane_id)
        if wezterm.GLOBAL[key] then
            if tab.is_active then
                wezterm.GLOBAL[key] = nil
            else
                has = true
            end
        end
    end
    return has
end

-- Ghostty делит полосу поровну между вкладками и центрирует заголовок.
-- У fancy-бара WezTerm ширина вкладки = ширина текста, поэтому добиваем
-- заголовок пробелами. Метрики шрифта полосы (Ubuntu Medium 11pt, scale 1)
-- сняты `wezterm ls-fonts`: пробел 3.42 px, средняя буква 7.7 px.
local SPACE_PX = 3.42
local CHAR_PX = 7.7
local TAB_CHROME_PX = 12 -- кнопка × и внутренние отступы вкладки (подобрано по скриншоту)

local function remember_width(window)
    wezterm.GLOBAL['tabbar_px_' .. window:window_id()] = window:get_dimensions().pixel_width
end
wezterm.on('window-resized', remember_width)
wezterm.on('update-status', remember_width)

wezterm.on('format-tab-title', function(tab, tabs)
    local title = tab.tab_title
    if not title or title == '' then
        title = tab.active_pane.title
    end
    if tab.active_pane.is_zoomed then
        title = '⤢ ' .. title
    end
    local bell = tab_has_bell(tab)
    local prefix = bell and '🔔 ' or ''

    local left, right = '', ''
    local px = wezterm.GLOBAL['tabbar_px_' .. tab.window_id]
    if px then
        local slot = px / #tabs - TAB_CHROME_PX
        local max_chars = math.max(1, math.floor(slot / CHAR_PX) - utf8.len(prefix))
        title = wezterm.truncate_right(title, max_chars)
        local text_px = (utf8.len(title) + utf8.len(prefix)) * CHAR_PX
        local pad = math.max(0, math.floor((slot - text_px) / SPACE_PX / 2))
        left = string.rep(' ', pad)
        right = left
    end

    local cells = { { Text = left } }
    if bell then
        table.insert(cells, { Foreground = { Color = colors.accents.bell_indicator } })
        table.insert(cells, { Text = prefix })
    end
    local fg = tab.is_active and colors.accents.tab_active_fg or colors.accents.tab_inactive_fg
    table.insert(cells, { Foreground = { Color = fg } })
    table.insert(cells, { Text = title .. right })
    return wezterm.format(cells)
end)

-- window-subtitle = working-directory: у Ghostty под заголовком окна идёт cwd.
-- В WezTerm одна строка — показываем «title — cwd».
wezterm.on('format-window-title', function(tab, pane, tabs)
    local title = tab.active_pane.title
    local cwd = pane.current_working_dir
    local path = cwd and cwd.file_path or nil
    if path and path ~= '' then
        local home = wezterm.home_dir
        if path:sub(1, #home) == home then
            path = '~' .. path:sub(#home + 1)
        end
        if not title:find(path, 1, true) then
            title = title .. ' — ' .. path
        end
    end
    if #tabs > 1 then
        title = '[' .. (tab.tab_index + 1) .. '/' .. #tabs .. '] ' .. title
    end
    return title
end)

return {
    enable_tab_bar = true,
    tab_bar_at_bottom = false,
    use_fancy_tab_bar = true,
    -- адвайтовская полоса вкладок Ghostty появляется только со второй вкладкой
    hide_tab_bar_if_only_one_tab = true,
    -- кнопки «+» у Ghostty в полосе нет (она в заголовке, а его под Hyprland нет)
    show_new_tab_button_in_tab_bar = false,
    show_close_tab_button_in_tabs = true,
    show_tab_index_in_tab_bar = false,
    -- ширину считает format-tab-title, лимит только чтобы не резать паддинг
    tab_max_width = 1000,
    switch_to_last_active_tab_when_closing_tab = true,
}
