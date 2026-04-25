local wezterm = require('wezterm')

local options = {
   -- ref: https://wezfurlong.org/wezterm/config/luae/SshDomain.html
   ssh_domains = {},

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {
      {
         name = 'WSL:Ubuntu',
         distribution = 'Ubuntu',
         default_cwd = '/home/osddqd',
         username = 'osddqd',
         -- default_prog = { 'fish', '-l' },
      },
   },
}

-- add SSH domains from ~/.ssh/config
for host, _ in pairs(wezterm.enumerate_ssh_hosts()) do
   if host ~= '*' then
      table.insert(options.ssh_domains, {
         name = host,
         remote_address = host,
         multiplexing = 'None',
      })
   end
end

return options
