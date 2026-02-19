local wezterm = require('wezterm')

return {
   font = wezterm.font_with_fallback({
     { family = 'JetBrainsMono Nerd Font' },
     { family = "Hack Nerd Font Mono" },
   }),
   font_size = 12,
   freetype_load_target = 'Normal',
   freetype_render_target = 'Normal', 
   warn_about_missing_glyphs = false,
}
