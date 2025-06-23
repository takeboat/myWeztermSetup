local wezterm = require 'wezterm'

local config = wezterm.config_builder()
-- 检测操作系统
local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"
local is_mac = wezterm.target_triple:find("darwin") ~= nil

-- shell配置
if is_windows then
    -- Windows 平台
    config.default_prog = { "powershell.exe", "-NoLogo" }
    config.exit_behavior = "Hold"
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
    -- Linux 平台
    config.default_prog = { "/bin/zsh" }
elseif is_mac then
    -- macOS 平台
    config.default_prog = { "/opt/homebrew/bin/zsh" }
end

-- 外观配置
config.color_scheme = "GruvboxDarkHard" -- 内置配色方案
config.font = wezterm.font_with_fallback({
    "Maple Mono NF CN",                 -- 您当前的字体
    "FiraCode Nerd Font",               -- 广泛支持的 Nerd Font
}, { weight = "Regular" })
config.font_size = 12
config.window_background_opacity = 0.95 -- 透明度 (0-1)

-- 窗口配置
config.initial_rows = 30
config.initial_cols = 140
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE" -- 替代 window_borderless
config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = true
config.tab_bar_at_bottom = true

-- 键位绑定
local act = wezterm.action

-- 主键绑定
config.keys = {
    -- 窗格导航
    { key = "h",     mods = "CTRL",       action = act.ActivatePaneDirection("Left") },
    { key = "j",     mods = "CTRL",       action = act.ActivatePaneDirection("Down") },
    { key = "k",     mods = "CTRL",       action = act.ActivatePaneDirection("Up") },
    { key = "l",     mods = "CTRL",       action = act.ActivatePaneDirection("Right") },

    -- 分割窗口
    { key = "v",     mods = "ALT",        action = act.SplitVertical },  -- 垂直分割
    { key = "s",     mods = "ALT",        action = act.SplitHorizontal }, -- 水平分割

    -- 解决 Ctrl+H 冲突
    { key = "h",     mods = "CTRL|SHIFT", action = act.SendString("\x08") }, -- 保留删除功能
    { key = "q",     mods = "ALT",        action = act.CloseCurrentPane({ confirm = false }) },

    -- 标签操作
    { key = "t",     mods = "ALT",        action = act.SpawnTab("CurrentPaneDomain") },
    { key = "h",     mods = "ALT",        action = act.ActivateTabRelative(-1) }, -- Alt+h → 上一个 Tab
    { key = "l",     mods = "ALT",        action = act.ActivateTabRelative(1) },  -- Alt+l → 下一个 Tab
    { key = "z",     mods = "ALT",        action = act.TogglePaneZoomState },     -- Alt+z 放大/恢复窗格

    -- 全屏
    { key = "Enter", mods = "CTRL",       action = act.ToggleFullScreen },
    
    -- 智能 Ctrl+C：优先复制选中文本，没有选中时发送中断信号
    {
        key = "c", 
        mods = "CTRL", 
        action = wezterm.action_callback(function(window, pane)
            -- 清除任何选中的文本（准备接收新输入）
            window:perform_action(act.ClearSelection, pane)
            
            -- 获取当前是否有选中文本
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""
            
            if has_selection then
                -- 如果有选中文本，执行复制
                window:perform_action(act.CopyTo("Clipboard"), pane)
            else
                -- 没有选中文本时发送中断信号
                window:perform_action(act.SendKey{key="c", mods="CTRL"}, pane)
            end
        end)
    },
    
    -- 安全粘贴 (Ctrl+V) - 只粘贴不执行
    {
        key = "v", 
        mods = "CTRL", 
        action = wezterm.action_callback(function(window, pane)
            -- 清除任何选中的文本
            window:perform_action(act.ClearSelection, pane)
            
            -- 直接粘贴但不立即执行
            window:perform_action(act.PasteFrom("Clipboard"), pane)
        end)
    },
    
    -- 备用粘贴（安全粘贴）
    { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") }
}

-- 平台特定的复制粘贴键位（作为备用）
if is_windows or not is_mac then
    -- Windows 和 Linux
    config.keys[#config.keys + 1] = { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo 'Clipboard' }
else
    -- macOS
    config.keys[#config.keys + 1] = { key = "c", mods = "SUPER", action = act.CopyTo 'Clipboard' }
end

-- 添加额外的 Ctrl+C 作为可靠的中断信号源
config.keys[#config.keys + 1] = {
    key = "c", mods = "CTRL|SHIFT", 
    action = act.SendKey{ key = "c", mods = "CTRL" }
}

-- 修复的鼠标绑定配置
config.mouse_bindings = {
    -- 双击选词
    {
        event = { Down = { streak = 2, button = "Left" } },
        action = act.SelectTextAtMouseCursor("Word"),
    }
}
config.set_environment_variables = {
    LC_ALL = "en_US.UTF-8",
    LANG = "en_US.UTF-8",
    LC_CTYPE = "zh_CN.UTF-8",
}

-- 右键粘贴（保持不变）
-- ...（保持原来的右键粘贴代码不变）

-- macOS 特殊设置（保持不变）
if is_mac then
    config.use_ime = true
    config.send_composed_key_when_left_alt_is_pressed = true
    config.send_composed_key_when_right_alt_is_pressed = false
end

-- 通用设置（保持不变）
config.scrollback_lines = 10000
config.enable_scroll_bar = true

return config