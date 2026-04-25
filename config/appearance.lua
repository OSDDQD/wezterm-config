local gpu_adapters = require('utils.gpu-adapter')
local backdrops = require('utils.backdrops')
local colors = require('colors.custom').colorscheme
local wezterm = require('wezterm')

return {
   max_fps = 120,
   front_end = 'WebGpu', ---@type 'WebGpu' | 'OpenGL' | 'Software'
   webgpu_power_preference = 'HighPerformance',
   webgpu_preferred_adapter = gpu_adapters:pick_best(),

   -- cursor
   animation_fps = 120,
   cursor_blink_ease_in = 'EaseOut',
   cursor_blink_ease_out = 'EaseOut',
   cursor_thickness = '0.1cell',
   default_cursor_style = 'BlinkingBlock',
   cursor_blink_rate = 650,

   -- color scheme
   colors = colors,

   -- background: pass in `true` if you want wezterm to start with focus mode on (no bg images)
   background = backdrops:initial_options(true),

   -- scrollbar
   enable_scroll_bar = true,

   -- command palette
   command_palette_fg_color = '#b4befe',
   command_palette_bg_color = '#11111b',
   command_palette_font_size = 13,
   command_palette_rows = 10,

   window_decorations = 'RESIZE',
   initial_cols = 160,
   initial_rows = 60,
   window_padding = {
      left = '1cell',
      right = '0.5cell',
      top = '0.2cell',
      bottom = '0.1cell',
   },
   adjust_window_size_when_changing_font_size = false,
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      font_size = 12,
      inactive_titlebar_bg = '#000',
      active_titlebar_bg = '#000',
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
