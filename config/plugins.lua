local wezterm = require('wezterm')

local M = {}

function M.apply(config)
   local quick_domains =
      wezterm.plugin.require('https://github.com/DavidRR-F/quick_domains.wezterm')
   quick_domains.apply_to_config(config, {
      keys = {
         attach = { key = 'd', mods = 'ALT|CTRL', tbl = '' },
         vsplit = { key = 'v', mods = 'ALT|CTRL', tbl = '' },
         hsplit = { key = 'h', mods = 'ALT|CTRL', tbl = '' },
      },
   })
end

return M
