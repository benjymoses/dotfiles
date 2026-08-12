local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("FiraCode Nerd Font Propo")
config.font_size = 14

config.initial_cols = 175
config.initial_rows = 75

config.enable_tab_bar = true
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 15

config.window_frame = {
	border_left_width = "0.5cell",
	border_right_width = "0.5cell",
	border_bottom_height = "0.25cell",
	border_top_height = "0.75cell",
	border_left_color = "#12081c",
	border_right_color = "#12081c",
	border_bottom_color = "#12081c",
	border_top_color = "#12081c",
}

-- Fix for ALT+LEFT and ALT+RIGHT in MacOS
config.keys = {
	{
		key = "LeftArrow",
		mods = "ALT",
		action = wezterm.action.SendString("\x1bb"),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = wezterm.action.SendString("\x1bf"),
	},
	{
		key = "n",
		mods = "SHIFT|CTRL",
		action = wezterm.action.ToggleFullScreen,
	},
}

config.enable_kitty_keyboard = true

config.color_scheme = "Catppuccin Mocha"

config.native_macos_fullscreen_mode = true

-- No default_prog: herdr is launched manually and is the only multiplexer.
-- Its mirror plugin surfaces remote herdr workspaces in the local sidebar, so a
-- second window or tab is not needed to reach them.

-- Colour the tab amber when the pane is a remote SSH session. The "host" user
 -- var is set by the OSC 1337 SetUserVar emission in .zprofile, guarded on
 -- SSH_CONNECTION, so it only appears for panes logged into a remote machine.
 wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
        local pane = tab.active_pane
        local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or pane.title
        title = wezterm.truncate_right(title, max_width - 2)

        local bg = tab.is_active and "#2b2042" or "#1b1032"
        if pane.user_vars and pane.user_vars.host then
                bg = tab.is_active and "#8f4700" or "#5a2d00" -- amber: remote
        end

        return {
                { Background = { Color = bg } },
                { Foreground = { Color = "#c0c0c0" } },
                { Text = " " .. title .. " " },
        }
 end)

return config
