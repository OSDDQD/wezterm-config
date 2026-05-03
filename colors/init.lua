local wezterm = require('wezterm')

-- Parens truncate require()'s multi-return (module + filepath) to the single
-- module value; without them the trailing call would inject the filepath as
-- a stray third entry.
local THEMES = {
    (require('colors.themes.dracula_plus')),
    (require('colors.themes.example_builtin')),
}

-- Active theme. Either a `name` from one of the THEMES entries (e.g. 'Dracula+'),
-- or any built-in WezTerm scheme name not declared in THEMES (e.g. 'Tokyo Night').
local ACTIVE = 'Dark+'

local function nilsafe(t, ...)
    for _, k in ipairs({ ... }) do
        if type(t) ~= 'table' then
            return nil
        end
        t = t[k]
    end
    return t
end

-- Index THEMES by name (type A) or builtin (type B). Errors on missing key or duplicate.
local by_name = {}
for _, theme in ipairs(THEMES) do
    local key = theme.name or theme.builtin
    if not key then
        error('colors: theme is missing both `name` and `builtin`')
    end
    if by_name[key] then
        error("colors: duplicate theme key '" .. key .. "'")
    end
    by_name[key] = theme
end

-- Resolve the active theme into a concrete WezTerm scheme table.
local active = by_name[ACTIVE]
local resolved
if active then
    if active.scheme then
        resolved = active.scheme
    else
        local builtins = wezterm.color.get_builtin_schemes()
        resolved = builtins[active.builtin]
        if not resolved then
            error("colors: built-in scheme '" .. tostring(active.builtin) .. "' not found")
        end
    end
else
    local builtins = wezterm.color.get_builtin_schemes()
    resolved = builtins[ACTIVE]
    if not resolved then
        error(
            "colors: theme '"
                .. tostring(ACTIVE)
                .. "' is not registered locally and is not a built-in WezTerm scheme"
        )
    end
end

-- Register every type-A scheme so swapping ACTIVE never requires touching color_schemes.
local color_schemes = {}
for _, theme in ipairs(THEMES) do
    if theme.name and theme.scheme then
        color_schemes[theme.name] = theme.scheme
    end
end

-- Accent fallback derived from the resolved scheme; theme-provided accents win.
-- stylua: ignore
local fallback_accents = {
    progress_indeterminate = resolved.ansi[4],
    progress_ok            = resolved.ansi[3],
    progress_error         = resolved.ansi[2],
    tab_active_fg          = nilsafe(resolved, 'tab_bar', 'active_tab', 'fg_color')   or resolved.foreground,
    tab_inactive_fg        = nilsafe(resolved, 'tab_bar', 'inactive_tab', 'fg_color') or resolved.foreground,
    titlebar_bg            = nilsafe(resolved, 'tab_bar', 'inactive_tab', 'bg_color') or resolved.background,
    command_palette_bg     = resolved.background,
    launcher_separator     = resolved.brights[1],
}

local accents = {}
local theme_accents = (active and active.accents) or {}
for k, v in pairs(fallback_accents) do
    accents[k] = theme_accents[k] or v
end

-- ANSI map: index 1..8 plus standard names.
local ansi_names = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' }
local ansi = {}
for i, color in ipairs(resolved.ansi) do
    ansi[i] = color
    ansi[ansi_names[i]] = color
end

return {
    color_scheme = ACTIVE,
    color_schemes = color_schemes,
    accents = accents,
    ansi = ansi,
    foreground = resolved.foreground,
    background = resolved.background,
}
