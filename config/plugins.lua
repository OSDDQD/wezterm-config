local wezterm = require('wezterm')

local M = {}

---Wire up third-party WezTerm plugins. Add new plugins inside this function.
---@param config table the built WezTerm config table
function M.apply(config)
    -- local theme_rotator = wezterm.plugin.require('https://github.com/koh-sh/wezterm-theme-rotator')
    -- -- The plugin always registers four bindings (next/prev/random/default).
    -- -- Pin all four under ALT|SHIFT so the plugin's defaults (SUPER|SHIFT, i.e.
    -- -- Win+Shift+R/D on Windows) don't collide with OS-level shortcuts.
    -- theme_rotator.apply_to_config(config, {
    --     next_theme_key = 'n',
    --     next_theme_mods = 'ALT|SHIFT',
    --     prev_theme_key = 'p',
    --     prev_theme_mods = 'ALT|SHIFT',
    --     random_theme_key = 'r',
    --     random_theme_mods = 'ALT|SHIFT',
    --     default_theme_key = 'd',
    --     default_theme_mods = 'ALT|SHIFT',
    -- })
end

return M
