local wezterm = require('wezterm')
local nf = wezterm.nerdfonts
local Theme = require('colors.custom')

---@alias DomainKind 'ssh' | 'wsl' | 'local' | 'unix'

---@class DomainKindMeta
---@field priority integer    -- меньше = выше в меню
---@field icon string         -- Nerd Font glyph
---@field color string        -- цвет заголовка группы и иконки
---@field label string        -- надпись в заголовке группы

---@type table<DomainKind, DomainKindMeta>
-- stylua: ignore
local kinds = {
    ssh       = { priority = 30, icon = nf.cod_remote,             color = Theme.colors.blue,   label = 'SSH'   },
    wsl       = { priority = 10, icon = nf.cod_terminal_ubuntu,    color = Theme.colors.yellow, label = 'WSL'   },
    ['local'] = { priority = 20, icon = nf.cod_terminal,           color = Theme.colors.green,  label = 'LOCAL' },
    unix      = { priority = 40, icon = nf.cod_server_environment, color = Theme.colors.mauve,  label = 'UNIX'  },
}

---@class DomainEntry
---@field kind DomainKind
---@field name string
--- ssh:   remote_address, username, port?, multiplexing?, assume_shell?
--- wsl:   distribution, username?, default_cwd?, default_prog?
--- local: args, cwd?
--- unix:  socket_path?, no_serve_automatically?

---Single source of truth for everything spawnable.
---The launcher (config.domain_launcher) reads the filtered list back via wezterm.GLOBAL.
---@type DomainEntry[]
local entries = {
    -- stylua: ignore start
    { kind = 'wsl',   name = 'WSL:Ubuntu', distribution = 'Ubuntu', username = 'osddqd', default_cwd = '/home/osddqd', default = true },
    { kind = 'local', name = 'Command Prompt',        args = { 'cmd.exe' } },
    { kind = 'local', name = 'PowerShell',       args = { 'pwsh.exe', '-NoLogo' } },
    { kind = 'local', name = 'PowerShell v1', args = { 'powershell.exe' } },
    -- stylua: ignore end
}

-- auto-enumerate SSH hosts from ~/.ssh/config
for host, info in pairs(wezterm.enumerate_ssh_hosts()) do
    if host ~= '*' then
        table.insert(entries, {
            kind = 'ssh',
            name = host,
            remote_address = info.hostname or host,
            username = info.user,
            multiplexing = 'None',
            assume_shell = 'Posix',
        })
    end
end

---Predicates applied to every entry. Any returning false drops the entry.
---By default empty (everything passes). Add functions here to slice the list.
---Examples:
---  function(e) return not (e.kind == 'ssh' and e.name:match('^bastion%-')) end,
---  function(e) return e.name ~= 'localhost' end,
---@type (fun(entry: DomainEntry): boolean)[]
local filters = {}

local function passes(entry)
    for _, f in ipairs(filters) do
        if not f(entry) then
            return false
        end
    end
    return true
end

local filtered = {}
for _, e in ipairs(entries) do
    if passes(e) then
        table.insert(filtered, e)
    end
end

local default_entry = nil
for _, e in ipairs(filtered) do
    if e.default then
        if default_entry then
            wezterm.log_error(
                ('multiple default domains; keeping %s, ignoring %s'):format(
                    default_entry.name,
                    e.name
                )
            )
        else
            default_entry = e
        end
    end
end

-- expose the filtered list to the launcher without putting it on the config table
wezterm.GLOBAL.domain_entries = filtered
wezterm.GLOBAL.domain_kinds = kinds

-- project filtered entries into wezterm-native option tables
local ssh_domains, wsl_domains, unix_domains, launch_menu = {}, {}, {}, {}

for _, e in ipairs(filtered) do
    if e.kind == 'ssh' then
        table.insert(ssh_domains, {
            name = e.name,
            remote_address = e.remote_address,
            username = e.username,
            multiplexing = e.multiplexing or 'None',
            assume_shell = e.assume_shell or 'Posix',
        })
    elseif e.kind == 'wsl' then
        table.insert(wsl_domains, {
            name = e.name,
            distribution = e.distribution,
            username = e.username,
            default_cwd = e.default_cwd,
            default_prog = e.default_prog,
        })
    elseif e.kind == 'unix' then
        table.insert(unix_domains, {
            name = e.name,
            socket_path = e.socket_path,
            no_serve_automatically = e.no_serve_automatically,
        })
    elseif e.kind == 'local' then
        table.insert(launch_menu, {
            label = e.name,
            args = e.args,
            cwd = e.cwd,
            domain = { DomainName = 'local' },
        })
    end
end

local result = {
    ssh_domains = ssh_domains,
    wsl_domains = wsl_domains,
    unix_domains = unix_domains,
    launch_menu = launch_menu,
}

if default_entry then
    if default_entry.kind == 'local' then
        result.default_prog = default_entry.args
    else
        result.default_domain = default_entry.name
    end
end

return result
