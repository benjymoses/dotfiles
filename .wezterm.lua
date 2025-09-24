local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("MesloLGS NF")
config.font_size = 16

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 15

-- "Macchiato" or "Mocha"
config.color_scheme = "Catppuccin Mocha" 

return config