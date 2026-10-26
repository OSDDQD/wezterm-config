return {
    -- Ghostty перечитывает конфиг только по ctrl+shift+, — так же и здесь
    automatically_reload_config = false,
    -- Ghostty закрывает вкладку при любом выходе шелла
    exit_behavior = 'Close',
    exit_behavior_messaging = 'Verbose',
    status_update_interval = 1000,
    -- bell-features = system, border, title — без audio (звук дают хуки Claude Code)
    audible_bell = 'Disabled',
    prefer_to_spawn_tabs = true,
    -- scrollback-limit = 20048000 (байт) ≈ 100k строк
    scrollback_lines = 100000,
    -- пакет wezterm-nightly обновляется через apt, встроенная проверка не нужна
    check_for_updates = false,
    -- Под Hyprland — нативный Wayland, как у Ghostty.
    -- (false было нужно только под GNOME/Mutter ради серверного тайтлбара.)
    enable_wayland = true,

    -- focus-follows-mouse = true: фокус сплита за курсором
    pane_focus_follows_mouse = true,
    -- mouse-hide-while-typing = true
    hide_mouse_cursor_when_typing = true,
    -- desktop-notifications = true (OSC 9 / OSC 777)
    notification_handling = 'AlwaysShow',
    -- mouse-scroll-multiplier = 1
    alternate_buffer_wheel_scroll_speed = 1,
    -- Каждая вкладка/сплит идёт новым процессом шелла; сам GUI — один процесс,
    -- аналога gtk-single-instance = false и linux-cgroup у WezTerm нет.
}
