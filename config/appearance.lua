local wezterm = require('wezterm')
local backdrops = require('utils.backdrops')
local Theme = require('colors.custom')

return {
    -- cursor
    cursor_blink_ease_in = 'EaseOut',
    cursor_blink_ease_out = 'EaseOut',
    cursor_thickness = '0.2cell',
    default_cursor_style = 'BlinkingBar',
    cursor_blink_rate = 650,

    -- color scheme
    colors = Theme.colorscheme,

    -- background: pass in `true` if you want wezterm to start with focus mode on (no bg images)
    -- background = backdrops:initial_options(true),

    -- scrollbar
    enable_scroll_bar = true,

    -- command palette
    command_palette_fg_color = Theme.colors.command_palette_fg,
    command_palette_bg_color = Theme.colors.command_palette_bg,
    command_palette_font_size = 13,
    command_palette_rows = 10,

    window_decorations = 'RESIZE',
    initial_cols = 160,
    initial_rows = 60,
    window_padding = {
        left = '0.2cell',
        right = '0.4cell',
        top = '0.1cell',
        bottom = '0.1cell',
    },
    adjust_window_size_when_changing_font_size = false,
    window_close_confirmation = 'NeverPrompt',
    window_frame = {
        font = wezterm.font_with_fallback({ 'Segoe UI', 'Symbols Nerd Font Mono' }),
        font_size = 12,
        inactive_titlebar_bg = Theme.colors.base,
        active_titlebar_bg = Theme.colors.base,
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
    enable_checksum_rectangular_area = false,

    -- Drives blink animation in tab title (config/agent_deck.lua) — every tick
    -- triggers a window repaint via the registered `update-status` handler.
    status_update_interval = 500,
}
