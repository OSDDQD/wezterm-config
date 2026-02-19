local wezterm = require('wezterm')
local Config = require('config')

require('utils.backdrops')
   -- :set_focus('#000000')
   -- :set_images_dir(require('wezterm').home_dir .. '/Pictures/Wallpapers/')
   :set_images()
   :random()

require("events.new-tab-button").setup()

local config = Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options

local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config, {
   position = "bottom",
   max_width = 30,
   modules = {
      tabs = {
         active_tab_fg = 8,  -- white  #F8F8F2
         inactive_tab_fg = 8,
         new_tab_fg = 7,     -- cyan   #8BE9FD
      },
      workspace = {
         enabled = false,
         color = 7,          -- cyan   #8BE9FD
      },
      leader = {
         color = 3,          -- green  #50FA7B
      },
      pane = {
         color = 5,          -- blue   #82AAFF
      },
      username = {
         enabled = false,
         color = 6,          -- purple #C792EA
      },
      hostname = {
         enabled = false,
      },
      clock = {
         enabled = false,
         color = 4,          -- yellow #FFCB6B
         format = "%H:%M",
      },
      cwd = {
         color = 3,          -- green  #50FA7B
      },
   },
})

return config
