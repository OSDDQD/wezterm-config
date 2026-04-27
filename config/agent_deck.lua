-- Agent status driven by OSC 1337 SetUserVar from Claude Code hooks.
-- Replaces wezterm-agent-deck plugin (process detection doesn't work through WSL).
-- Companion files: ~/.local/bin/wez-user-var (in WSL) and ~/.claude/settings.json hooks.
local wezterm = require('wezterm')
local Theme = require('colors.custom')
local nf = wezterm.nerdfonts

local M = {}

-- stylua: ignore
M.STATUS = {
    working = { icon = nf.md_brain,        color = Theme.colors.green                },
    waiting = { icon = nf.md_bell_ring,    color = Theme.colors.peach, blink = true  },
    idle    = { icon = nf.md_check_circle, color = Theme.colors.text                 },
}

local PRIORITY = { waiting = 3, working = 2, idle = 1 }

--- Aggregate the worst-priority claude_status across all panes in the tab.
---@param tab table TabInformation passed to format-tab-title
---@return string|nil status name (or nil if no agent in this tab)
function M.pick_tab_status(tab)
    local best, best_prio = nil, 0
    for _, pane in ipairs(tab.panes or {}) do
        local s = (pane.user_vars or {}).claude_status
        if s and PRIORITY[s] and PRIORITY[s] > best_prio then
            best, best_prio = s, PRIORITY[s]
        end
    end
    return best
end

--- Whether the blink phase is currently "on". 1Hz cycle.
---@return boolean
function M.is_blink_visible()
    return (os.time() % 2) == 0
end

-- Per-pane dedup so we toast only on transitions INTO `waiting`.
local last_status = {}

wezterm.on('user-var-changed', function(window, pane, name, value)
    if name ~= 'claude_status' then return end
    local pane_id = pane:pane_id()
    local prev = last_status[pane_id]
    last_status[pane_id] = value

    if value ~= 'waiting' or prev == 'waiting' then return end

    local project = (pane:get_user_vars() or {}).claude_project
    if not project or project == '' then project = 'agent' end

    window:toast_notification('Claude Code', project, nil, 6000)
end)

-- Force a window repaint (tab bar + format-tab-title for ALL tabs, including
-- inactive ones) on every status_update_interval tick. Two reasons:
--   1. The `waiting` status icon needs to blink without external triggers.
--   2. Inactive tabs would otherwise show a stale title — WezTerm only
--      invalidates the tab bar when something visibly changes, and a passive
--      tab whose pane title or claude_status updates in the background does
--      not always trip that path on its own.
-- WezTerm skips invalidation when set_right_status receives an unchanged
-- value, so we tick a counter to guarantee the value differs each tick. The
-- text is rendered with foreground == titlebar bg, so it's invisible.
wezterm.GLOBAL.repaint_tick = wezterm.GLOBAL.repaint_tick or 0
wezterm.on('update-status', function(window)
    wezterm.GLOBAL.repaint_tick = (wezterm.GLOBAL.repaint_tick + 1) % 10
    window:set_right_status(wezterm.format({
        { Foreground = { Color = Theme.colors.base } },
        { Background = { Color = Theme.colors.base } },
        { Text = tostring(wezterm.GLOBAL.repaint_tick) },
    }))
end)

return M
