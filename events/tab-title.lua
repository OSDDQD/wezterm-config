local wezterm = require("wezterm")

local M = {}

-- Icons for different shells/processes (Nerd Font glyphs)
local ICON_MAP = {
   -- Shells
   ["pwsh"]        = wezterm.nerdfonts.md_powershell,
   ["powershell"]  = wezterm.nerdfonts.md_powershell,
   ["cmd"]         = wezterm.nerdfonts.cod_terminal_cmd,
   ["fish"]        = wezterm.nerdfonts.md_fish,
   ["bash"]        = wezterm.nerdfonts.cod_terminal_bash,
   ["zsh"]         = wezterm.nerdfonts.dev_terminal,
   ["nu"]          = wezterm.nerdfonts.md_greater_than,
   ["nushell"]     = wezterm.nerdfonts.md_greater_than,

   -- WSL distros
   ["ubuntu"]      = wezterm.nerdfonts.linux_ubuntu,
   ["debian"]      = wezterm.nerdfonts.linux_debian,
   ["archlinux"]   = wezterm.nerdfonts.linux_archlinux,
   ["arch"]        = wezterm.nerdfonts.linux_archlinux,
   ["fedora"]      = wezterm.nerdfonts.linux_fedora,
   ["opensuse"]    = wezterm.nerdfonts.linux_opensuse,
   ["kali"]        = wezterm.nerdfonts.linux_kali_linux,
   ["alpine"]      = wezterm.nerdfonts.linux_alpine,
   ["centos"]      = wezterm.nerdfonts.linux_centos,
   ["gentoo"]      = wezterm.nerdfonts.linux_gentoo,
   ["manjaro"]     = wezterm.nerdfonts.linux_manjaro,
   ["mint"]        = wezterm.nerdfonts.linux_mint,

   -- Editors/tools
   ["vim"]         = wezterm.nerdfonts.dev_vim,
   ["nvim"]        = wezterm.nerdfonts.custom_neovim,
   ["nano"]        = wezterm.nerdfonts.md_file_edit,
   ["git"]         = wezterm.nerdfonts.dev_git,
   ["node"]        = wezterm.nerdfonts.md_nodejs,
   ["python"]      = wezterm.nerdfonts.dev_python,
   ["python3"]     = wezterm.nerdfonts.dev_python,
   ["cargo"]       = wezterm.nerdfonts.dev_rust,
   ["rustc"]       = wezterm.nerdfonts.dev_rust,
   ["go"]          = wezterm.nerdfonts.seti_go,
   ["docker"]      = wezterm.nerdfonts.dev_docker,
   ["ssh"]         = wezterm.nerdfonts.md_ssh,
   ["htop"]        = wezterm.nerdfonts.md_chart_areaspline,
   ["btop"]        = wezterm.nerdfonts.md_chart_areaspline,
   ["top"]         = wezterm.nerdfonts.md_chart_areaspline,
   ["lazygit"]     = wezterm.nerdfonts.dev_git,
   ["claude"]      = wezterm.nerdfonts.md_robot,
}

local ICON_SSH = wezterm.nerdfonts.md_ssh
local ICON_LINUX = wezterm.nerdfonts.cod_terminal_linux
local ICON_DEFAULT = wezterm.nerdfonts.cod_terminal

-- Color scheme
local COLORS = {
   tab_bar_bg     = '#0D0D0D',
   active_bg      = '#212121',
   active_fg      = '#FFFFFF',
   active_accent  = '#212121',
   inactive_bg    = '#181818',
   inactive_fg    = '#6E6E6E',
   hover_bg       = '#2A2A2A',
   hover_fg       = '#BBBBBB',
}

--- Extract the process name from the full path
local function get_process_name(pane_info)
   local name = pane_info.foreground_process_name or ""
   name = name:gsub("(.*/)(.*)", "%2"):gsub("(.+\\)(.*)", "%2"):gsub("%.exe$", "")
   return name:lower()
end

--- Build WSL domain-to-distro mapping from config
local wsl_domain_map = {}
do
   local ok, domains = pcall(require, 'config.domains')
   if ok and domains.wsl_domains then
      for _, d in ipairs(domains.wsl_domains) do
         wsl_domain_map[d.name] = (d.distribution or "linux"):lower()
      end
   end
end

--- Detect if this is a WSL tab and return the distro name
local function get_wsl_distro(pane_info)
   local domain = pane_info.domain_name or ""
   if wsl_domain_map[domain] then
      return wsl_domain_map[domain]
   end
   local distro = domain:match("^WSL:(.+)$")
   if distro then
      return distro:lower()
   end
   return nil
end

--- Build SSH domain name set from config
local ssh_domain_set = {}
do
   local ok, domains = pcall(require, 'config.domains')
   if ok and domains.ssh_domains then
      for _, d in ipairs(domains.ssh_domains) do
         ssh_domain_set[d.name] = true
      end
   end
end

--- Detect if this is an SSH session
local function is_ssh_domain(pane_info)
   local domain = pane_info.domain_name or ""
   if domain:match("^SSH:") or domain:match("^SSHMUX:") then
      return true, domain:match("^SSH[MUX]*:(.+)$") or domain
   end
   if ssh_domain_set[domain] then
      return true, domain
   end
   return false, nil
end

--- Get the icon for a tab based on context
local function get_icon(pane_info)
   local process_name = get_process_name(pane_info)

   local ssh, _ = is_ssh_domain(pane_info)
   if ssh then
      return ICON_SSH
   end

   local wsl_distro = get_wsl_distro(pane_info)
   if wsl_distro then
      return ICON_MAP[wsl_distro] or ICON_LINUX
   end

   if process_name == "ssh" then
      return ICON_SSH
   end

   return ICON_MAP[process_name] or ICON_DEFAULT
end

--- Get the display title for the tab
local function get_title(tab)
   local pane = tab.active_pane

   -- If user manually set a tab title, use that
   if tab.tab_title and #tab.tab_title > 0 then
      return tab.tab_title
   end

   -- Check SSH
   local ssh, ssh_host = is_ssh_domain(pane)
   if ssh then
      return ssh_host or "SSH"
   end

   -- Check WSL - show the domain name as configured by user
   local wsl_distro = get_wsl_distro(pane)
   if wsl_distro then
      local domain = pane.domain_name or ""
      return domain
   end

   -- For local tabs, try to get a nice name from the process
   local process_name = get_process_name(pane)
   local display_names = {
      ["pwsh"]       = "PowerShell",
      ["powershell"] = "PowerShell",
      ["cmd"]        = "Command Prompt",
      ["fish"]       = "fish",
      ["bash"]       = "bash",
      ["zsh"]        = "zsh",
      ["nu"]         = "Nushell",
      ["nushell"]    = "Nushell",
   }

   if display_names[process_name] then
      return display_names[process_name]
   end

   -- Fallback: use the active pane title if it has meaningful info
   local pane_title = pane.title or ""
   if #pane_title > 0 and pane_title ~= process_name then
      return pane_title
   end

   -- Last fallback: process name
   if #process_name > 0 then
      return process_name
   end

   return "Terminal"
end

M.setup = function()
   wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
      local pane = tab.active_pane
      local icon = get_icon(pane)
      local title = get_title(tab)

      -- Determine colors based on state
      local bg, fg, accent
      if tab.is_active then
         bg = COLORS.active_bg
         fg = COLORS.active_fg
         accent = COLORS.active_accent
      elseif hover then
         bg = COLORS.hover_bg
         fg = COLORS.hover_fg
         accent = nil
      else
         bg = COLORS.inactive_bg
         fg = COLORS.inactive_fg
         accent = nil
      end

      -- Truncate title if needed
      -- overhead: active = ▌(1) + space(1) + icon(1) + 2×space(2) + trailing(1) = 6
      --           inactive =       space(1) + icon(1) + 2×space(2) + trailing(1) = 5
      local overhead = tab.is_active and 6 or 5
      local max_title_width = max_width - overhead
      if wezterm.column_width(title) > max_title_width then
         title = wezterm.truncate_right(title, max_title_width - 1) .. "…"
      end

      -- Admin indicator
      local admin_prefix = ""
      if pane.title and pane.title:match("^Administrator: ") then
         admin_prefix = wezterm.nerdfonts.md_shield_account .. " "
      end

      -- Build tab with visual accent for active tab
      local cells = {}
      if tab.is_active then
         -- Active tab: colored left accent bar
         table.insert(cells, { Background = { Color = accent } })
         table.insert(cells, { Foreground = { Color = accent } })
      end

      -- Tab content
      table.insert(cells, { Background = { Color = bg } })
      table.insert(cells, { Foreground = { Color = fg } })
      table.insert(cells, { Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } })
      table.insert(cells, { Text = " " .. admin_prefix .. icon .. "  " .. title .. " " })

      return cells
   end)
end

return M
