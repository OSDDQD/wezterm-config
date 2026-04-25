local wezterm = require('wezterm')
local colors = require('colors.custom').colors
local nf = wezterm.nerdfonts

-- Map foreground process name to a Nerd Font icon
local process_icons = {
   ['pwsh'] = nf.cod_terminal_powershell,
   ['powershell'] = nf.cod_terminal_powershell,
   ['cmd'] = nf.cod_terminal_cmd,
   ['wsl'] = nf.cod_terminal_ubuntu,
   ['wslhost'] = nf.cod_terminal_ubuntu,
   ['bash'] = nf.cod_terminal_linux,
   ['zsh'] = nf.cod_terminal_linux,
   ['node'] = nf.md_nodejs,
   ['python'] = nf.dev_python,
   ['python3'] = nf.dev_python,
   ['vim'] = nf.custom_vim,
   ['nvim'] = nf.custom_vim,
   ['git'] = nf.dev_git,
}

local function get_process_icon(proc)
   local name = proc:gsub('(.*[/\\])(.*)', '%2'):gsub('%.exe$', '')
   if process_icons[name] then
      return process_icons[name]
   end
   if name:match('^wsl') then
      return nf.cod_terminal_ubuntu
   end
   return nf.cod_terminal
end

local function get_dir_name(pane_title)
   if pane_title == '' then
      return '~'
   end
   local dir = pane_title:match('([^/\\]+)[/\\]?$')
   return dir or pane_title
end

wezterm.on('format-tab-title', function(tab)
   local icon = get_process_icon(tab.active_pane.foreground_process_name)
   local dir = get_dir_name(tab.active_pane.title)

   if tab.is_active then
      return wezterm.format({
         { Attribute = { Intensity = 'Half' } },
         -- { Foreground = { Color = colors.blue } },
         { Text = ' ' .. icon .. ' ' .. dir .. ' ' },
      })
   else
      return wezterm.format({
         { Attribute = { Intensity = 'Half' } },
         -- { Foreground = { Color = colors.overlay1 } },
         { Text = ' ' .. icon .. ' ' .. dir .. ' ' },
      })
   end
end)

return {
   enable_tab_bar = true,
   tab_bar_at_bottom = true,
   use_fancy_tab_bar = true,
   show_new_tab_button_in_tab_bar = false,
   tab_max_width = 25,
   hide_tab_bar_if_only_one_tab = true,
   show_tab_index_in_tab_bar = false,
   switch_to_last_active_tab_when_closing_tab = true,
   show_close_tab_button_in_tabs = false,
}
