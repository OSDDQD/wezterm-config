local wezterm = require('wezterm')
local act = wezterm.action
local domain_launcher = require('utils.domain_launcher')

-- Раскладка кейбиндов повторяет Ghostty (`ghostty +list-keybinds`:
-- ~/.config/ghostty/keybinds + дефолты Ghostty). При key_map_preference = 'Physical'
-- буквы ниже матчатся по ФИЗИЧЕСКОЙ клавише, поэтому всё работает и в русской
-- раскладке — то, ради чего в Ghostty заведены `key_*`.

local mod = {
    SUPER = 'ALT',
    SUPER_REV = 'ALT|CTRL',
}

---write_screen_file Ghostty: скринбэк пейна → временный файл, дальше `mode`.
---@param mode 'paste'|'copy'|'open'
local function write_screen_file(mode)
    return wezterm.action_callback(function(window, pane)
        local dims = pane:get_dimensions()
        local text = pane:get_lines_as_text(dims.scrollback_rows)
        local path = os.tmpname() .. '.txt'
        local f = io.open(path, 'w')
        if not f then
            wezterm.log_error('write_screen_file: cannot open ' .. path)
            return
        end
        f:write(text)
        f:close()
        if mode == 'paste' then
            pane:paste(path)
        elseif mode == 'copy' then
            window:copy_to_clipboard(path, 'Clipboard')
        else
            wezterm.open_with(path)
        end
    end)
end

local split_down = act.SplitVertical({ domain = 'CurrentPaneDomain' })
local split_right = act.SplitHorizontal({ domain = 'CurrentPaneDomain' })
-- window-inherit-working-directory: новая вкладка в cwd текущей (по OSC 7)
local new_tab = act.SpawnTab('CurrentPaneDomain')

-- stylua: ignore
local keys = {
    -- --- ~/.config/ghostty/keybinds ---
    { key = 'a',          mods = 'CTRL|SHIFT',       action = act.Nop }, -- select_all: аналога нет
    { key = 'b',          mods = 'CTRL|SHIFT',       action = act.ShowTabNavigator },
    { key = 'c',          mods = 'CTRL|SHIFT',       action = act.CopyTo('Clipboard') },
    { key = 'd',          mods = 'CTRL|SHIFT',       action = new_tab },
    { key = 'e',          mods = 'CTRL|SHIFT',       action = split_down },
    { key = 'f',          mods = 'CTRL|SHIFT',       action = act.Search({ CaseInSensitiveString = '' }) },
    { key = 'i',          mods = 'CTRL|SHIFT',       action = act.ShowDebugOverlay },
    { key = 'j',          mods = 'CTRL|SHIFT',       action = write_screen_file('paste') },
    { key = 'j',          mods = 'SUPER|CTRL|SHIFT', action = write_screen_file('copy') },
    { key = 'j',          mods = 'CTRL|ALT|SHIFT',   action = write_screen_file('open') },
    { key = 'n',          mods = 'CTRL|SHIFT',       action = act.SpawnWindow },
    { key = 'o',          mods = 'CTRL|SHIFT',       action = split_right },
    { key = 'p',          mods = 'CTRL|SHIFT',       action = act.ActivateCommandPalette },
    { key = 'q',          mods = 'CTRL|SHIFT',       action = act.QuitApplication },
    { key = 't',          mods = 'CTRL|SHIFT',       action = new_tab },
    { key = 't',          mods = 'CTRL',             action = new_tab },
    { key = 'v',          mods = 'CTRL|SHIFT',       action = act.PasteFrom('Clipboard') },
    { key = 'w',          mods = 'CTRL|SHIFT',       action = act.CloseCurrentTab({ confirm = false }) },
    { key = 'x',          mods = 'CTRL|SHIFT',       action = act.CloseCurrentPane({ confirm = false }) },
    { key = ',',          mods = 'CTRL|SHIFT',       action = act.ReloadConfiguration },
    { key = ',',          mods = 'CTRL',             action = wezterm.action_callback(function()
        wezterm.open_with(wezterm.config_file)
    end) },
    { key = '-',          mods = 'CTRL',             action = act.DecreaseFontSize },
    { key = '=',          mods = 'CTRL',             action = act.IncreaseFontSize },
    { key = '=',          mods = 'CTRL|SHIFT',       action = act.IncreaseFontSize },
    { key = '0',          mods = 'CTRL',             action = act.ResetFontSize },
    { key = '[',          mods = 'SUPER|CTRL',       action = act.ActivatePaneDirection('Prev') },
    { key = ']',          mods = 'SUPER|CTRL',       action = act.ActivatePaneDirection('Next') },
    { key = 'PageUp',     mods = 'ALT',              action = act.ScrollByLine(-10) },
    { key = 'PageDown',   mods = 'ALT',              action = act.ScrollByLine(10) },
    -- shift+enter=text:\n
    { key = 'Enter',      mods = 'SHIFT',            action = act.SendString('\n') },

    -- --- дефолты Ghostty ---
    { key = 'Insert',     mods = 'CTRL',             action = act.CopyTo('Clipboard') },
    { key = 'Insert',     mods = 'SHIFT',            action = act.PasteFrom('PrimarySelection') },
    { key = 'PageUp',     mods = 'SHIFT',            action = act.ScrollByPage(-1) },
    { key = 'PageDown',   mods = 'SHIFT',            action = act.ScrollByPage(1) },
    { key = 'Home',       mods = 'SHIFT',            action = act.ScrollToTop },
    { key = 'End',        mods = 'SHIFT',            action = act.ScrollToBottom },
    { key = 'PageUp',     mods = 'CTRL|SHIFT',       action = act.ScrollToPrompt(-1) },
    { key = 'PageDown',   mods = 'CTRL|SHIFT',       action = act.ScrollToPrompt(1) },
    { key = 'Tab',        mods = 'CTRL',             action = act.ActivateTabRelative(1) },
    { key = 'Tab',        mods = 'CTRL|SHIFT',       action = act.ActivateTabRelative(-1) },
    { key = 'PageDown',   mods = 'CTRL',             action = act.ActivateTabRelative(1) },
    { key = 'PageUp',     mods = 'CTRL',             action = act.ActivateTabRelative(-1) },
    { key = 'RightArrow', mods = 'CTRL|SHIFT',       action = act.ActivateTabRelative(1) },
    { key = 'LeftArrow',  mods = 'CTRL|SHIFT',       action = act.ActivateTabRelative(-1) },
    { key = '9',          mods = 'ALT',              action = act.ActivateTab(-1) },
    { key = 'Enter',      mods = 'CTRL|SHIFT',       action = act.TogglePaneZoomState },
    { key = 'UpArrow',    mods = 'CTRL|ALT',         action = act.ActivatePaneDirection('Up') },
    { key = 'DownArrow',  mods = 'CTRL|ALT',         action = act.ActivatePaneDirection('Down') },
    { key = 'LeftArrow',  mods = 'CTRL|ALT',         action = act.ActivatePaneDirection('Left') },
    { key = 'RightArrow', mods = 'CTRL|ALT',         action = act.ActivatePaneDirection('Right') },
    { key = 'UpArrow',    mods = 'SUPER|CTRL|SHIFT', action = act.AdjustPaneSize({ 'Up', 10 }) },
    { key = 'DownArrow',  mods = 'SUPER|CTRL|SHIFT', action = act.AdjustPaneSize({ 'Down', 10 }) },
    { key = 'LeftArrow',  mods = 'SUPER|CTRL|SHIFT', action = act.AdjustPaneSize({ 'Left', 10 }) },
    { key = 'RightArrow', mods = 'SUPER|CTRL|SHIFT', action = act.AdjustPaneSize({ 'Right', 10 }) },
    { key = 'F11',        mods = 'NONE',             action = act.ToggleFullScreen },

    -- --- своё, у Ghostty аналогов нет ---
    { key = 'F1',         mods = 'CTRL|SHIFT',       action = act.ActivateCopyMode },
    { key = 'r',          mods = 'CTRL|SHIFT',       action = domain_launcher.action },
    { key = 'F5',         mods = mod.SUPER,          action = act.ReloadConfiguration },
    { key = 'r',          mods = 'LEADER',           action = act.ActivateKeyTable({ name = 'resize_pane', one_shot = false, timeout_milliseconds = 2000 }) },
}

-- alt+1..8 = goto_tab:N (alt+9 = last_tab — выше)
for i = 1, 8 do
    table.insert(keys, { key = tostring(i), mods = 'ALT', action = act.ActivateTab(i - 1) })
end

-- Аналог кириллических `ctrl+ф=text:\x01` / `alt+ф=esc:a` из Ghostty: в русской
-- раскладке ctrl/alt+буква уходит в приложение кириллицей, и TUI её не понимает.
-- Здесь то же лечится проще — физической клавишей: ctrl+<буква> шлёт control-код,
-- alt+<буква> — ESC+латиница, в любой раскладке. Буквы, занятые действиями выше
-- (ctrl+t = new_tab), пропускаем.
local taken_ctrl = { t = true }
for code = string.byte('a'), string.byte('z') do
    local ch = string.char(code)
    if not taken_ctrl[ch] then
        table.insert(keys, { key = ch, mods = 'CTRL', action = act.SendString(string.char(code - 96)) })
    end
    table.insert(keys, { key = ch, mods = 'ALT', action = act.SendString('\27' .. ch) })
    table.insert(keys, { key = ch, mods = 'ALT|SHIFT', action = act.SendString('\27' .. ch:upper()) })
end
-- [ и ] в русской раскладке — х и ъ: ctrl+[ это ESC, ctrl+] это GS
table.insert(keys, { key = '[', mods = 'CTRL', action = act.SendString('\27') })
table.insert(keys, { key = ']', mods = 'CTRL', action = act.SendString('\29') })

-- stylua: ignore
local key_tables = {
    resize_pane = {
        { key = 'LeftArrow',  action = act.AdjustPaneSize({ 'Left', 5 }) },
        { key = 'DownArrow',  action = act.AdjustPaneSize({ 'Down', 5 }) },
        { key = 'UpArrow',    action = act.AdjustPaneSize({ 'Up', 5 }) },
        { key = 'RightArrow', action = act.AdjustPaneSize({ 'Right', 5 }) },
        { key = 'Escape',     action = 'PopKeyTable' },
        { key = 'Enter',      action = 'PopKeyTable' },
        { key = 'q',          action = 'PopKeyTable' },
    },
}

local mouse_bindings = {
    -- Ctrl-click открывает ссылку под курсором (как в Ghostty). Пара Down → Nop
    -- обязательна: иначе нажатие уходит в TUI с захватом мыши (herdr, Claude Code),
    -- и ссылка там не открывается. Вариант с Shift проходит мимо захвата мыши
    -- приложением (bypass_mouse_reporting_modifiers).
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.OpenLinkAtMouseCursor,
    },
    {
        event = { Down = { streak = 1, button = 'Left' } },
        mods = 'CTRL',
        action = act.Nop,
    },
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'CTRL|SHIFT',
        action = act.OpenLinkAtMouseCursor,
    },
    {
        event = { Down = { streak = 1, button = 'Left' } },
        mods = 'CTRL|SHIFT',
        action = act.Nop,
    },
    -- copy-on-select = true: у Ghostty это ТОЛЬКО primary selection (вставка
    -- средней кнопкой / shift+insert), в обычный буфер — ctrl+shift+c
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'NONE',
        action = act.CompleteSelectionOrOpenLinkAtMouseCursor('PrimarySelection'),
    },
    -- mouse-scroll-multiplier = 1: одна строка на щелчок колеса.
    -- Только в основном экране: в alt-screen (less, man) колесо по-прежнему
    -- превращается в стрелки (alternate_buffer_wheel_scroll_speed в behavior.lua).
    {
        event = { Down = { streak = 1, button = { WheelUp = 1 } } },
        mods = 'NONE',
        alt_screen = false,
        action = act.ScrollByLine(-1),
    },
    {
        event = { Down = { streak = 1, button = { WheelDown = 1 } } },
        mods = 'NONE',
        alt_screen = false,
        action = act.ScrollByLine(1),
    },
}

return {
    disable_default_key_bindings = true,
    disable_default_mouse_bindings = false,
    key_map_preference = 'Physical',
    leader = { key = 'Space', mods = mod.SUPER_REV },
    keys = keys,
    key_tables = key_tables,
    mouse_bindings = mouse_bindings,
    -- Как у Ghostty: herdr просит kitty-протокол (`CSI >7u`). Без него, в legacy,
    -- herdr после prefix не узнаёт кириллицу: `prefix+ы` и прочие дубли молчат.
    enable_kitty_keyboard = true,
    treat_left_ctrlalt_as_altgr = false,
}
