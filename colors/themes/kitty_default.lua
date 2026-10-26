-- Kitty Default — та же тема, что сейчас активна в Ghostty
-- (~/.config/ghostty/auto/theme.ghostty → /usr/share/ghostty/themes/Kitty Default).
-- Хром окна (тайтлбар, вкладки) красится от фона терминала, как у Ghostty
-- с `window-theme = ghostty`.
-- stylua: ignore
local palette = {
    black          = '#000000',
    red            = '#cc0403',
    green          = '#19cb00',
    yellow         = '#cecb00',
    blue           = '#0d73cc',
    magenta        = '#cb1ed1',
    cyan           = '#0dcdcd',
    white          = '#dddddd',
    bright_black   = '#767676',
    bright_red     = '#f2201f',
    bright_green   = '#23fd00',
    bright_yellow  = '#fffd00',
    bright_blue    = '#1a8fff',
    bright_magenta = '#fd28ff',
    bright_cyan    = '#14ffff',
    bright_white   = '#ffffff',
    cursor         = '#cccccc',
    cursor_text    = '#111111',
    selection_bg   = '#fffacd',
    -- хром: сняты пипеткой со скриншота полосы вкладок Ghostty (адвайта поверх
    -- чёрного фона): полоса #000, «таблетка» активной вкладки #161616
    chrome         = '#000000',
    chrome_raised  = '#161616',
    chrome_hover   = '#0e0e0e',
    chrome_border  = '#373737',
    chrome_dim_fg  = '#bdbdbd',
    -- заливка неактивного сплита (unfocused-split-fill Ghostty)
    split_fill     = '#44464f',
}

local scheme = {
    foreground = palette.white,
    background = palette.black,
    cursor_bg = palette.cursor,
    cursor_border = palette.cursor,
    cursor_fg = palette.cursor_text,
    selection_bg = palette.selection_bg,
    selection_fg = palette.black,
    split = palette.chrome_border,
    scrollbar_thumb = palette.chrome_border,
    visual_bell = palette.chrome_border,
    compose_cursor = palette.bright_yellow,
    ansi = {
        palette.black,
        palette.red,
        palette.green,
        palette.yellow,
        palette.blue,
        palette.magenta,
        palette.cyan,
        palette.white,
    },
    brights = {
        palette.bright_black,
        palette.bright_red,
        palette.bright_green,
        palette.bright_yellow,
        palette.bright_blue,
        palette.bright_magenta,
        palette.bright_cyan,
        palette.bright_white,
    },
    tab_bar = {
        background = palette.chrome,
        active_tab = {
            bg_color = palette.chrome_raised,
            fg_color = palette.bright_white,
        },
        inactive_tab = {
            bg_color = palette.chrome,
            fg_color = palette.chrome_dim_fg,
        },
        inactive_tab_hover = {
            bg_color = palette.chrome_hover,
            fg_color = palette.white,
        },
        new_tab = {
            bg_color = palette.chrome,
            fg_color = palette.chrome_dim_fg,
        },
        new_tab_hover = {
            bg_color = palette.chrome_hover,
            fg_color = palette.white,
        },
        inactive_tab_edge = palette.chrome,
    },
}

-- stylua: ignore
local accents = {
    progress_indeterminate = palette.blue,
    progress_ok            = palette.green,
    progress_error         = palette.red,
    tab_active_fg          = palette.bright_white,
    tab_inactive_fg        = palette.chrome_dim_fg,
    titlebar_bg            = palette.chrome,
    titlebar_fg            = palette.white,
    titlebar_border        = palette.chrome,
    command_palette_bg     = palette.chrome_raised,
    command_palette_fg     = palette.white,
    launcher_separator     = palette.bright_black,
    bell_indicator         = palette.bright_yellow,
}

return {
    name = 'Kitty Default',
    scheme = scheme,
    accents = accents,
}
