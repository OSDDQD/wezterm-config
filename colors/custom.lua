-- Dracula+ theme
-- stylua: ignore
local M = {}
local Theme = {}

Theme.colors = {
    rosewater = '#FF92DF',
    flamingo = '#FF79C6',
    pink = '#FF92DF',
    mauve = '#C792EA',
    red = '#FF5555',
    maroon = '#FF6E6E',
    peach = '#FFCB6B',
    yellow = '#FFCB6B',
    green = '#50FA7B',
    teal = '#8BE9FD',
    sky = '#A4FFFF',
    blue = '#82AAFF',
    lavender = '#D6ACFF',
    text = '#F8F8F2',
    subtext1 = '#E0E0E0',
    subtext0 = '#BFBFBF',
    overlay2 = '#9A9A9A',
    overlay1 = '#7A7A7A',
    overlay0 = '#636363',
    surface2 = '#545454',
    surface1 = '#3B3B3B',
    surface0 = '#21222C',
    base = '#000000',
    mantle = '#ffffff',
    crust = '#121212',
    command_palette_fg = '#b4befe',
    command_palette_bg = '#11111b',
}

local colorscheme = {
    split = Theme.colors.subtext1,
    foreground = Theme.colors.text,
    background = Theme.colors.base,
    cursor_bg = '#ECEFF4',
    cursor_border = '#ECEFF4',
    cursor_fg = Theme.colors.base,
    selection_bg = '#44475A',
    visual_bell = Theme.colors.surface0,
    indexed = {
        [16] = Theme.colors.peach,
        [17] = Theme.colors.rosewater,
    },
    scrollbar_thumb = Theme.colors.overlay0,
    compose_cursor = Theme.colors.flamingo,
    ansi = {
        Theme.colors.surface0,
        Theme.colors.red,
        Theme.colors.green,
        Theme.colors.yellow,
        Theme.colors.blue,
        Theme.colors.mauve,
        Theme.colors.teal,
        Theme.colors.text,
    },
    brights = {
        Theme.colors.surface2,
        Theme.colors.maroon,
        '#69FF94',
        Theme.colors.yellow,
        Theme.colors.lavender,
        Theme.colors.pink,
        Theme.colors.sky,
        Theme.colors.text,
    },
    tab_bar = {
        active_tab = {
            bg_color = Theme.colors.base,
            fg_color = Theme.colors.blue,
            -- underline = 'Single',
            italic = false,
            strikethrough = false,
        },
        inactive_tab = {
            bg_color = Theme.colors.surface0,
            fg_color = Theme.colors.overlay1,
        },
        inactive_tab_hover = {
            bg_color = Theme.colors.surface0,
            fg_color = Theme.colors.subtext1,
        },
        new_tab = {
            bg_color = Theme.colors.crust,
            fg_color = Theme.colors.overlay0,
        },
        new_tab_hover = {
            bg_color = Theme.colors.surface0,
            fg_color = Theme.colors.subtext1,
        },
        inactive_tab_edge = Theme.colors.base,
    },
}

M.colorscheme = colorscheme
M.colors = Theme.colors

return M
