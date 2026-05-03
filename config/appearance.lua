local wezterm = require('wezterm')
local colors = require('colors')

return {
    -- cursor
    cursor_blink_ease_in = 'EaseOut',
    cursor_blink_ease_out = 'EaseOut',
    cursor_thickness = '0.1cell',
    default_cursor_style = 'BlinkingBar',
    cursor_blink_rate = 600,

    -- font
    font_size = 12,
    line_height = 1.1,

    -- color scheme
    color_scheme = colors.color_scheme,
    color_schemes = colors.color_schemes,

    -- scrollbar
    enable_scroll_bar = true,

    -- command palette
    command_palette_bg_color = colors.accents.command_palette_bg,
    command_palette_font_size = 14,
    command_palette_rows = 10,

    window_decorations = 'RESIZE|INTEGRATED_BUTTONS',

    initial_cols = 100,
    initial_rows = 20,
    window_padding = {
        left = '4pt',
        right = '4pt',
        top = '4pt',
        bottom = '5pt',
    },
    adjust_window_size_when_changing_font_size = false,
    window_close_confirmation = 'NeverPrompt',
    window_frame = {
        font = wezterm.font_with_fallback({
            { family = 'Segoe UI' },
            'Symbols Nerd Font Mono',
        }),
        font_size = 12,
        inactive_titlebar_bg = colors.accents.titlebar_bg,
        active_titlebar_bg = colors.accents.titlebar_bg,
    },
    inactive_pane_hsb = {
        saturation = 0.1,
        brightness = 0.2,
        hue = 0.7,
    },
    visual_bell = {
        fade_in_function = 'EaseIn',
        fade_in_duration_ms = 400,
        fade_out_function = 'EaseOut',
        fade_out_duration_ms = 250,
        target = 'CursorColor',
    },
    warn_about_missing_glyphs = false,
}
