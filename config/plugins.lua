local wezterm = require('wezterm')

local M = {}

-- wezterm-attention exposes AI-agent / background-task state as colored tab
-- indicators driven by marker files. We use `renderer = "manual"` so our
-- custom `format-tab-title` in config/tab.lua keeps owning the rendering;
-- tab.lua reads pane state through `attention.get_attention(pane_id)`.
local attention = wezterm.plugin.require('https://github.com/pro-vi/wezterm-attention')

---Plugin handle re-exported for other modules (see config/tab.lua).
M.attention = attention

-- Markers live inside WSL filesystem so Claude Code hooks running under WSL
-- can write them at `$HOME/.local/state/wezterm-attention/$WEZTERM_PANE`
-- naturally. WezTerm runs on Windows, so it reads via the UNC redirector.
-- Backslashes are required for the Windows CRT to recognise the UNC prefix;
-- long-bracket strings keep them literal without escaping.
local MARKER_DIR = [[\\wsl.localhost\Ubuntu\home\osddqd\.local\state\wezterm-attention]]

---Wire up third-party WezTerm plugins. Add new plugins inside this function.
---@param config table the built WezTerm config table
function M.apply(config)
    -- Manual mode: plugin registers pane cleanup, marker poller and the
    -- Alt+B review-toggle keybind, but leaves `format-tab-title` to us.
    attention.apply_to_config(config, {
        renderer = 'manual',
        dir = MARKER_DIR,
    })
end

return M
