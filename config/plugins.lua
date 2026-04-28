local wezterm = require('wezterm')
local Theme = require('colors.custom')

local M = {}

function M.apply(config)
    local smart_ssh = wezterm.plugin.require('https://github.com/DavidRR-F/smart_ssh.wezterm')
    smart_ssh.apply_to_config(config, {
        multiplexing = 'None',
        assume_shell = 'Posix',
    })

    config.keys = config.keys or {}
    for _, k in ipairs({
        { key = 'd', mods = 'ALT|CTRL', action = smart_ssh.tab() },
        { key = 'h', mods = 'ALT|CTRL', action = smart_ssh.hsplit() },
        { key = 'v', mods = 'ALT|CTRL', action = smart_ssh.vsplit() },
    }) do
        table.insert(config.keys, k)
    end
end

return M
