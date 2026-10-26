local wezterm = require('wezterm')
local colors = require('colors')

-- window-padding-balance: WezTerm отдаёт весь остаток от деления высоты окна
-- на высоту строки нижнему отступу, и снизу выходит заметно шире, чем сверху.
-- Делим остаток поровну между верхом и низом. Только при одной вкладке:
-- высоту полосы вкладок из Lua не узнать, при 2+ вкладках отступы базовые.
-- Снизу сверх Ghostty-шного 0,1 запас в 3 px: рамка и скругление окна
-- Hyprland (border_size = 2) перекрывают нижние пиксели последней строки.
local PADDING_TOP, PADDING_BOTTOM = 0, 3

local function balance_padding(window)
    local overrides = window:get_config_overrides() or {}
    local tab = window:active_tab()
    local want = nil
    if tab and #window:mux_window():tabs() == 1 then
        local size = tab:get_size()
        if size.rows > 0 then
            local cell = math.floor(size.pixel_height / size.rows)
            local height = window:get_dimensions().pixel_height
            local rows = math.floor((height - PADDING_TOP - PADDING_BOTTOM) / cell)
            local total = height - rows * cell
            local top = math.floor((total - PADDING_BOTTOM) / 2)
            want = { left = 4, right = 4, top = top, bottom = total - top }
        end
    end
    local cur = overrides.window_padding
    if (cur == nil and want == nil)
        or (cur and want and cur.top == want.top and cur.bottom == want.bottom) then
        return
    end
    overrides.window_padding = want
    window:set_config_overrides(overrides)
end
wezterm.on('window-resized', balance_padding)
wezterm.on('window-config-reloaded', balance_padding)
wezterm.on('update-status', balance_padding)

-- Внешний вид подогнан под ~/.config/ghostty/config. В комментариях — ключ Ghostty.
return {
    -- cursor: cursor-style = bar, cursor-style-blink = true, adjust-cursor-thickness = 2
    default_cursor_style = 'BlinkingBar',
    cursor_thickness = '2px',
    cursor_blink_rate = 600,
    -- Ghostty мигает без плавного затухания
    cursor_blink_ease_in = 'Constant',
    cursor_blink_ease_out = 'Constant',
    -- cursor-color = cell-foreground: курсор берёт цвет текста под ним
    force_reverse_video_cursor = true,

    -- font: font-family, font-size = 12, font-feature = +calt
    font = wezterm.font_with_fallback({
        'JetBrainsMono Nerd Font',
        'Symbols Nerd Font Mono',
        'Noto Color Emoji',
    }),
    -- Сам WezTerm вывел бы жирный в ExtraBold, а тусклый (SGR 2) в Thin.
    -- Ghostty рисует жирный Bold, а тусклый — тем же начертанием с прозрачностью
    -- 0.5 (faint-opacity); приглушать цвет WezTerm не умеет, поэтому Light.
    font_rules = {
        {
            intensity = 'Bold',
            italic = false,
            font = wezterm.font_with_fallback({
                { family = 'JetBrainsMono Nerd Font', weight = 'Bold' },
                'Symbols Nerd Font Mono',
                'Noto Color Emoji',
            }),
        },
        {
            intensity = 'Bold',
            italic = true,
            font = wezterm.font_with_fallback({
                { family = 'JetBrainsMono Nerd Font', weight = 'Bold', style = 'Italic' },
                'Symbols Nerd Font Mono',
                'Noto Color Emoji',
            }),
        },
        {
            intensity = 'Half',
            italic = false,
            font = wezterm.font_with_fallback({
                { family = 'JetBrainsMono Nerd Font', weight = 'Light' },
                'Symbols Nerd Font Mono',
                'Noto Color Emoji',
            }),
        },
        {
            intensity = 'Half',
            italic = true,
            font = wezterm.font_with_fallback({
                { family = 'JetBrainsMono Nerd Font', weight = 'Light', style = 'Italic' },
                'Symbols Nerd Font Mono',
                'Noto Color Emoji',
            }),
        },
    },
    font_size = 12,
    harfbuzz_features = { 'calt=1', 'liga=1' },
    -- adjust-cell-height = 15%. У Ghostty строка выходит 24 px, а WezTerm при
    -- 1.15 округляет ту же высоту до 25 px, и на экране текст заметно «реже».
    -- 1.13 даёт ровно 24 px, базовая линия совпадает (замер скриншотом).
    line_height = 1.13,
    -- freetype-load-flags = light, no-monochrome: лёгкий хинтинг, серое сглаживание
    freetype_load_target = 'Light',
    freetype_render_target = 'Light',

    -- color scheme (auto/theme.ghostty = Kitty Default)
    color_scheme = colors.color_scheme,
    color_schemes = colors.color_schemes,
    colors = { tab_bar = colors.tab_bar },
    bold_brightens_ansi_colors = 'No',

    -- scrollbar = system: у Ghostty это GTK-оверлей, который виден только при
    -- прокрутке. Постоянная полоса WezTerm на пустом окне выглядит чужеродно,
    -- поэтому выключена; позиция в скроллбэке видна в copy mode / по колесу.
    enable_scroll_bar = false,

    -- command palette (ctrl+shift+p)
    command_palette_bg_color = colors.accents.command_palette_bg,
    command_palette_fg_color = colors.accents.command_palette_fg,
    command_palette_font_size = 12,
    command_palette_rows = 12,

    -- window-decoration = auto: под Hyprland Ghostty своего заголовка не рисует
    -- (рамку даёт композитор), сверху только полоса вкладок при 2+ вкладках
    window_decorations = 'RESIZE',
    -- window: window-width = 120, window-height = 40
    initial_cols = 120,
    initial_rows = 40,
    -- window-padding-x = 4, window-padding-y = 0,1 (низ +2 px под рамку Hyprland)
    window_padding = {
        left = 4,
        right = 4,
        top = PADDING_TOP,
        bottom = PADDING_BOTTOM,
    },
    adjust_window_size_when_changing_font_size = false,
    -- background-opacity = 1.0
    window_background_opacity = 1.0,
    -- confirm-close-surface = false
    window_close_confirmation = 'NeverPrompt',
    window_frame = {
        font = wezterm.font_with_fallback({
            { family = 'Ubuntu', weight = 'Medium' },
            { family = 'Cantarell' },
            'Symbols Nerd Font Mono',
        }),
        font_size = 11,
        active_titlebar_bg = colors.accents.titlebar_bg,
        inactive_titlebar_bg = colors.accents.titlebar_bg,
        active_titlebar_fg = colors.accents.titlebar_fg,
        inactive_titlebar_fg = colors.accents.tab_inactive_fg,
        active_titlebar_border_bottom = colors.accents.titlebar_border,
        inactive_titlebar_border_bottom = colors.accents.titlebar_border,
        button_fg = colors.accents.titlebar_fg,
        button_bg = colors.accents.titlebar_bg,
        button_hover_fg = colors.accents.tab_active_fg,
        button_hover_bg = colors.accents.titlebar_border,
    },
    -- unfocused-split-opacity = 0.7 (+ серая заливка unfocused-split-fill)
    inactive_pane_hsb = {
        saturation = 0.9,
        brightness = 0.7,
    },
    -- bell-features = border: короткая вспышка вместо звука
    visual_bell = {
        fade_in_function = 'EaseIn',
        fade_in_duration_ms = 75,
        fade_out_function = 'EaseOut',
        fade_out_duration_ms = 150,
        target = 'BackgroundColor',
    },
    warn_about_missing_glyphs = false,
}
