local wezterm = require('wezterm')
local Config = require('config')

local config = Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.hyperlinks'))
   :append(require('config.launch'))
   :append(require('config.tab')).options

local domains = wezterm.plugin.require('https://github.com/DavidRR-F/quick_domains.wezterm')
domains.apply_to_config(config, {
   keys = {
      attach = { key = 'd', mods = 'ALT|CTRL', tbl = '' },
      vsplit = { key = 'v', mods = 'ALT|CTRL', tbl = '' },
      hsplit = { key = 'h', mods = 'ALT|CTRL', tbl = '' },
   },
})

return config
