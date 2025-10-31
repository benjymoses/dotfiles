local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("FiraCode Nerd Font Propo")
config.font_size = 14

config.initial_cols = 150
config.initial_rows = 45

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 15

config.window_frame = {
  border_left_width = "0.5cell",
  border_right_width = "0.5cell",
  border_bottom_height = "0.25cell",
  border_top_height = "0.75cell",
  border_left_color = "black",
  border_right_color = "black",
  border_bottom_color = "black",
  border_top_color = "black",
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
  action = wezterm.action.SendString("\x1bf")
  }
}

config.color_scheme = "Catppuccin Mocha" 

config.default_prog = { "/bin/zsh", "-l", "-c", "exec /opt/homebrew/bin/tmux new -A -s main" }

return config
