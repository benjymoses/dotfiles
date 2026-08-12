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

return config
