local Config = require('config')
local plugins = require('config.plugins')

local config = Config:init()
    :append(require('config.domains'))
    :append(require('config.appearance'))
    :append(require('config.behavior'))
    :append(require('config.bindings'))
    :append(require('config.fonts'))
    :append(require('config.hyperlinks'))
    :append(require('config.performance'))
    :append(require('config.tab')).options

plugins.apply(config)

return config
