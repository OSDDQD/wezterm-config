local wezterm = require('wezterm')
local backdrops = require('utils.backdrops')
local Theme = require('colors.custom')

return {
    -- cursor
    cursor_blink_ease_in = 'EaseOut',
    cursor_blink_ease_out = 'EaseOut',
    cursor_thickness = '0.1cell',
    default_cursor_style = 'BlinkingBar',
    cursor_blink_rate = 600,

    -- color scheme
    colors = Theme.colorscheme,

    -- background: pass in `true` if you want wezterm to start with focus mode on (no bg images)
    -- background = backdrops:initial_options(true),

    -- scrollbar
    enable_scroll_bar = true,

    -- command palette
    -- command_palette_fg_color = Theme.colors.command_palette_fg,
    -- command_palette_bg_color = Theme.colors.command_palette_bg,
    command_palette_font_size = 14,
    command_palette_rows = 10,

    window_decorations = "RESIZE",

    initial_cols = 100,
    initial_rows = 20,
    window_padding = {
        left = '1pt',
        right = '1pt',
        top = '0',
        bottom = '0',
    },
    adjust_window_size_when_changing_font_size = false,
    window_close_confirmation = 'NeverPrompt',
    window_frame = {
        font = wezterm.font_with_fallback({ 'Segoe UI', 'Symbols Nerd Font Mono' }),
        font_size = 13,
        inactive_titlebar_bg = Theme.colors.surface0,
        active_titlebar_bg = Theme.colors.surface0,
    },
    inactive_pane_hsb = {
        saturation = 0.1,
        brightness = 0.6,
        hue = 0.1,
    },
    visual_bell = {
        fade_in_function = 'EaseIn',
        fade_in_duration_ms = 250,
        fade_out_function = 'EaseOut',
        fade_out_duration_ms = 250,
        target = 'CursorColor',
    },
    warn_about_missing_glyphs = false,
}
