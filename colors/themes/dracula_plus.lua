-- Dracula+ theme
-- stylua: ignore
local palette = {
    rosewater          = '#FF92DF',
    flamingo           = '#FF79C6',
    pink               = '#FF92DF',
    mauve              = '#C792EA',
    red                = '#FF5555',
    maroon             = '#FF6E6E',
    peach              = '#FFCB6B',
    yellow             = '#FFCB6B',
    green              = '#50FA7B',
    teal               = '#8BE9FD',
    sky                = '#A4FFFF',
    blue               = '#82AAFF',
    lavender           = '#D6ACFF',
    text               = '#F8F8F2',
    subtext1           = '#E0E0E0',
    subtext0           = '#BFBFBF',
    overlay2           = '#9A9A9A',
    overlay1           = '#7A7A7A',
    overlay0           = '#636363',
    surface2           = '#545454',
    surface1           = '#3B3B3B',
    surface0           = '#21222C',
    base               = '#000000',
    mantle             = '#ffffff',
    crust              = '#121212',
    command_palette_fg = '#b4befe',
    command_palette_bg = '#11111b',
    bright_green       = '#69FF94',
}

local scheme = {
    split = palette.subtext1,
    foreground = palette.text,
    background = palette.base,
    cursor_bg = '#ECEFF4',
    cursor_border = '#ECEFF4',
    cursor_fg = palette.base,
    selection_bg = '#44475A',
    visual_bell = palette.surface0,
    indexed = {
        [16] = palette.peach,
        [17] = palette.rosewater,
    },
    scrollbar_thumb = palette.overlay0,
    compose_cursor = palette.flamingo,
    ansi = {
        palette.surface0,
        palette.red,
        palette.green,
        palette.yellow,
        palette.blue,
        palette.mauve,
        palette.teal,
        palette.text,
    },
    brights = {
        palette.surface2,
        palette.maroon,
        palette.bright_green,
        palette.yellow,
        palette.lavender,
        palette.pink,
        palette.sky,
        palette.text,
    },
    tab_bar = {
        active_tab = {
            bg_color = palette.base,
            fg_color = palette.blue,
            italic = false,
            strikethrough = false,
        },
        inactive_tab = {
            bg_color = palette.surface0,
            fg_color = palette.overlay1,
        },
        inactive_tab_hover = {
            bg_color = palette.surface0,
            fg_color = palette.subtext1,
        },
        new_tab = {
            bg_color = palette.crust,
            fg_color = palette.overlay0,
        },
        new_tab_hover = {
            bg_color = palette.surface0,
            fg_color = palette.subtext1,
        },
        inactive_tab_edge = palette.base,
    },
}

-- stylua: ignore
local accents = {
    progress_indeterminate = palette.peach,
    progress_ok            = palette.green,
    progress_error         = palette.red,
    tab_active_fg          = palette.blue,
    tab_inactive_fg        = palette.overlay1,
    titlebar_bg            = palette.surface0,
    command_palette_bg     = palette.command_palette_bg,
    launcher_separator     = palette.overlay1,
}

return {
    name = 'Dracula+',
    scheme = scheme,
    accents = accents,
}
