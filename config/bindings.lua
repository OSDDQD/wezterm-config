local wezterm = require('wezterm')
local act = wezterm.action

local mod = {
   SUPER = 'ALT',
   SUPER_REV = 'ALT|CTRL',
}

-- stylua: ignore
local keys = {
   -- misc/useful --
   { key = 'F1', mods = 'CTRL|SHIFT', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'CTRL|SHIFT', action = act.ShowLauncher },
   { key = 'F3', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   { key = 'F4', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },
   { key = 'F5', mods = 'CTRL|SHIFT',    action = act.ShowDebugOverlay },
   { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },

   { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
   { key = 'f',   mods = 'CTRL|SHIFT', action = act.Search({ CaseInSensitiveString = '' }) },

   -- cursor movement --
   { key = 'LeftArrow',  mods = mod.SUPER_REV,     action = act.SendKey({ key = 'Home' }) },
   { key = 'RightArrow', mods = mod.SUPER_REV,     action = act.SendKey({ key = 'End' }) },
   { key = 'Backspace',  mods = mod.SUPER_REV,     action = act.SendKey({ key = 'u', mods = 'CTRL' }) },

   -- copy/paste --
   { key = 'c',          mods = 'CTRL|SHIFT',  action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = 'CTRL|SHIFT',  action = act.PasteFrom('Clipboard') },

   -- tabs --
   -- tabs: spawn+close
   { key = 't',          mods = 'CTRL|SHIFT', action = act.SpawnTab('DefaultDomain') },
   { key = 'w',          mods = 'CTRL|SHIFT', action = act.CloseCurrentTab({ confirm = false }) },

   -- new line --
   { key = 'Enter', mods = 'SHIFT', action = act.SendString("\n"), },

   -- tabs: duplicate current tab (same domain + working directory)
   {
      key = 'd',
      mods = 'CTRL|SHIFT',
      action = wezterm.action_callback(function(window, pane)
         local cwd_uri = pane:get_current_working_dir()
         local cwd = nil
         if cwd_uri then
            cwd = cwd_uri.file_path
         end
         local domain = pane:get_domain_name()
         window:perform_action(
            act.SpawnCommandInNewTab({
               domain = { DomainName = domain },
               cwd = cwd,
            }),
            pane
         )
      end),
   },

   -- tabs: navigation
   -- { key = '1', mods = 'SHIFT|CTRL', action = act.ActivateTab(0) },
   -- { key = '2', mods = 'SHIFT|CTRL', action = act.ActivateTab(1) },
   -- { key = '3', mods = 'SHIFT|CTRL', action = act.ActivateTab(2) },
   -- { key = '4', mods = 'SHIFT|CTRL', action = act.ActivateTab(3) },

   { key = 'Tab',  mods = 'CTRL',  action = act.ActivateTabRelative(1) },


   -- window --
   -- window: spawn windows
   { key = 'n',  mods = 'SHIFT|CTRL',  action = act.SpawnWindow },

   -- panes: scroll pane
   { key = 'PageUp', mods = mod.SUPER, action = act.ScrollByLine(-5) },
   { key = 'PageDown', mods = mod.SUPER, action = act.ScrollByLine(5) },
   { key = 'PageUp',   mods = mod.SUPER_REV,  action = act.ScrollByPage(-0.85) },
   { key = 'PageDown', mods = mod.SUPER_REV,  action = act.ScrollByPage(0.85) },
}

local mouse_bindings = {
   -- Ctrl-click will open the link under the mouse cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
   -- {
   --    event = { Up = { streak = 1, button = 'Left' } },
   --    mods = 'SHIFT|CTRL',
   --    action = act.OpenLinkAtMouseCursor,
   -- },
}

return {
   disable_default_key_bindings = true,
   -- disable_default_mouse_bindings = true,
   key_map_preference = 'Physical',
   leader = { key = 'Space', mods = mod.SUPER_REV },
   keys = keys,
   mouse_bindings = mouse_bindings,
   allow_win32_input_mode = false,
   enable_kitty_keyboard = false,
   ui_key_cap_rendering = 'WindowsSymbols',
}
