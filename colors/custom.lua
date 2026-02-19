-- Dracula+ color scheme (adapted from Windows Terminal)
-- stylua: ignore
local dracula = {
   background    = '#212121',
   foreground    = '#F8F8F2',
   cursor_bg     = '#ECEFF4',
   cursor_border = '#ECEFF4',
   cursor_fg     = '#212121',
   selection_bg  = '#44475A',
   selection_fg  = '#F8F8F2',
   black         = '#21222C',
   red           = '#FF5555',
   green         = '#50FA7B',
   yellow        = '#FFCB6B',
   blue          = '#82AAFF',
   purple        = '#C792EA',
   cyan          = '#8BE9FD',
   white         = '#F8F8F2',
   bright_black  = '#545454',
   bright_red    = '#FF6E6E',
   bright_green  = '#69FF94',
   bright_yellow = '#FFCB6B',
   bright_blue   = '#D6ACFF',
   bright_purple = '#FF92DF',
   bright_cyan   = '#A4FFFF',
   bright_white  = '#F8F8F2',
}

local colorscheme = {
   foreground = dracula.foreground,
   background = dracula.background,
   cursor_bg = dracula.cursor_bg,
   cursor_border = dracula.cursor_border,
   cursor_fg = dracula.cursor_fg,
   selection_bg = dracula.selection_bg,
   selection_fg = dracula.selection_fg,
   ansi = {
      dracula.black,        -- black
      dracula.red,          -- red
      dracula.green,        -- green
      dracula.yellow,       -- yellow
      dracula.blue,         -- blue
      dracula.purple,       -- magenta/purple
      dracula.cyan,         -- cyan
      dracula.white,        -- white
   },
   brights = {
      dracula.bright_black,   -- black
      dracula.bright_red,     -- red
      dracula.bright_green,   -- green
      dracula.bright_yellow,  -- yellow
      dracula.bright_blue,    -- blue
      dracula.bright_purple,  -- magenta/purple
      dracula.bright_cyan,    -- cyan
      dracula.bright_white,   -- white
   },
   tab_bar = {
      background = '#0D0D0D',
      active_tab = {
         bg_color = '#212121',
         fg_color = '#F8F8F2',
      },
      inactive_tab = {
         bg_color = '#161616',
         fg_color = '#545454',
      },
      inactive_tab_hover = {
         bg_color = '#2A2A2A',
         fg_color = '#BBBBBB',
      },
      new_tab = {
         bg_color = '#0D0D0D',
         fg_color = '#545454',
      },
      new_tab_hover = {
         bg_color = '#2A2A2A',
         fg_color = '#F8F8F2',
      },
   },
   visual_bell = dracula.red,
   scrollbar_thumb = '#44475A',
   split = '#545454',
   compose_cursor = dracula.cyan,
}

return colorscheme
