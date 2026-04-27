return {
   default_prog = { 'wsl.exe' },
   default_cwd = os.getenv('HOME'),
   default_domain = 'WSL:Ubuntu',
   -- stylua: ignore
   launch_menu = {
      { label = 'cmd',        args = { 'cmd.exe' },             domain = { DomainName = 'local' } },
      { label = 'pwsh',       args = { 'pwsh.exe', '-NoLogo' }, domain = { DomainName = 'local' } },
      { label = 'powershell', args = { 'powershell.exe' },      domain = { DomainName = 'local' } },
   },
}
