local wezterm = require('wezterm')

-- Дополнительные mime-типы, которые считаем редактируемыми (помимо text/*).
local extra_text_mimes = {
   ['application/json'] = true,
   ['application/xml'] = true,
   ['application/javascript'] = true,
   ['application/x-yaml'] = true,
   ['application/yaml'] = true,
   ['application/toml'] = true,
   ['application/x-shellscript'] = true,
   ['application/x-sh'] = true,
   ['application/x-empty'] = true, -- пустые файлы
   ['inode/x-empty'] = true,
}

-- Запасной список расширений на случай, если file(1) не угадал mime.
local extra_text_exts = {
   json = true,
   jsonc = true,
   json5 = true,
   yaml = true,
   yml = true,
   toml = true,
   ini = true,
   conf = true,
   cfg = true,
   env = true,
   xml = true,
   svg = true,
   lock = true,
   md = true,
   markdown = true,
   lua = true,
   py = true,
   rb = true,
   pl = true,
   ts = true,
   tsx = true,
   jsx = true,
   mjs = true,
   cjs = true,
   rs = true,
   go = true,
   java = true,
   kt = true,
   c = true,
   h = true,
   cpp = true,
   hpp = true,
   sh = true,
   bash = true,
   zsh = true,
   fish = true,
   sql = true,
   dockerfile = true,
   gitignore = true,
}

local function is_text(stdout, file_path)
   if stdout:find('^text/') or stdout:find('text/') then
      return true
   end
   local mime = stdout:match('^[%w%-%./]+')
   if mime and extra_text_mimes[mime] then
      return true
   end
   local ext = file_path:match('%.([%w]+)$')
   if ext and extra_text_exts[ext:lower()] then
      return true
   end
   return false
end

wezterm.on('open-uri', function(window, pane, uri)
   local editor = 'micro'

   if uri:find('^file:') ~= 1 or pane:is_alt_screen_active() then
      return
   end

   local distro = (pane:get_domain_name() or ''):match('^WSL:(.+)$')
   if not distro then
      return
   end

   local url = wezterm.url.parse(uri)

   local success, stdout, _ = wezterm.run_child_process({
      'wsl.exe',
      '-d',
      distro,
      '--',
      'file',
      '--brief',
      '--mime-type',
      url.file_path,
   })
   if not success then
      return
   end

   if stdout:find('directory') then
      pane:send_text(wezterm.shell_join_args({ 'cd', url.file_path }) .. '\r')
      pane:send_text('ls\r')
      return false
   end

   if is_text(stdout, url.file_path) then
      local target = url.fragment and (url.file_path .. ':' .. url.fragment) or url.file_path
      pane:send_text(wezterm.shell_join_args({ editor, target }) .. '\r')
      return false
   end
end)

-- Start with the built-in hyperlinking (URLs, emails, etc.)
return {
   hyperlink_rules = wezterm.default_hyperlink_rules(),
}
