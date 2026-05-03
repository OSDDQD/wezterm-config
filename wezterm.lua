local Config = require('config')
local plugins = require('config.plugins')

-- appearance must come first: it sets wezterm.GLOBAL.color_theme, which
-- colors/init.lua reads at first require. Other modules require colors
-- transitively (domains, tab, utils.domain_launcher), so they must follow.
local config = Config:init()
    :append(require('config.appearance'))
    :append(require('config.domains'))
    :append(require('config.behavior'))
    :append(require('config.bindings'))
    :append(require('config.fonts'))
    :append(require('config.hyperlinks'))
    :append(require('config.performance'))
    :append(require('config.tab')).options

plugins.apply(config)

return config
