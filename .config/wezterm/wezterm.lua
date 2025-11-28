local wezterm = require("wezterm")
local config = wezterm.config_builder()
local constants = require("constants")
local commands = require("commands")

-- Font settings
config.font_size = 18
config.line_height = 1.2
config.font = wezterm.font_with_fallback({
	{
		family = "MonaspiceRn Nerd Font Mono",
		weight = "Medium",
		stretch = "Normal",
		style = "Normal",
	},
	{
		family = "MesloLGS Nerd Font Mono",
		weight = "Medium",
		stretch = "Normal",
		style = "Italic",
	},
	{
		family = "MonaspiceAr Nerd Font Mono",
		weight = "Medium",
		stretch = "Normal",
		style = "Italic",
	},
})

-- Colors
config.colors = {
	cursor_bg = "white",
	cursor_border = "white",
}
config.color_scheme = "Tokyo Night"

-- Appearance
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
	left = 10,
	right = 10,
	top = 0,
	bottom = 0,
}
config.window_background_image = constants.bg_image
config.macos_window_background_blur = 40
config.window_background_opacity = 0.8

-- Miscalleneous settings
config.max_fps = 120
config.prefer_egl = true

-- Custom commands
wezterm.on("augment-command-palette", function()
	return commands
end)

return config
