local wezterm = require("wezterm")
local constants = require("constants")
local commands = require("commands")

local act = wezterm.action
local mux = wezterm.mux

-- ====================================================================================================================
-- Plugins
-- ====================================================================================================================

local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local smart_splits = wezterm.plugin.require("https://github.com/smart-splits-nvim/backend-wezterm")

local config = wezterm.config_builder()

-- ====================================================================================================================
-- Font settings
-- ====================================================================================================================

config.font_size = 14
config.line_height = 1.2
config.font = wezterm.font_with_fallback({
	{
		family = "Liga SFMono Nerd Font",
		weight = "Medium",
		stretch = "Normal",
		style = "Normal",
	},
	{
		family = "MesloLGS Nerd Font Mono",
		weight = "Medium",
		stretch = "Normal",
		style = "Normal",
	},
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

-- ====================================================================================================================
-- Colors
-- ====================================================================================================================

config.colors = {
	cursor_bg = "white",
	cursor_border = "white",
}
config.color_scheme = "Tokyo Night"

-- ====================================================================================================================
-- Appearance
-- ====================================================================================================================

config.window_decorations = "RESIZE"
config.window_padding = {
	left = 10,
	right = 10,
	top = 0,
	bottom = 0,
}
config.window_background_image = constants.bg_image
config.macos_window_background_blur = 40
config.window_background_opacity = 0.95

-- Keep a status-bar-like tab strip visible, matching tmux's always-on status line.
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false

-- ====================================================================================================================
-- Miscellaneous/General settings
-- ====================================================================================================================

config.max_fps = 120
config.prefer_egl = true
config.scrollback_lines = 1000000
config.audible_bell = "Disabled"

-- ====================================================================================================================
-- LEADER SETUP: Ctrl-S (matches the tmux prefix)
-- ====================================================================================================================

config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 2000 }

-- ====================================================================================================================
-- WORKSPACE MANAGEMENT
-- ====================================================================================================================

-- Switch between workspaces
local function switch_workspace(window, pane, workspace)
	window:perform_action(
		act.SwitchToWorkspace({
			name = workspace,
		}),
		pane
	)
end

-- Create or switch to a named workspace
local function create_workspace(window, pane)
	window:perform_action(
		act.PromptInputLine({
			description = "Create / switch to workspace:",
			action = wezterm.action_callback(function(w, p, line)
				if line and line ~= "" then
					switch_workspace(w, p, line)
				end
			end),
		}),
		pane
	)
end

-- Rename the current workspace
local function rename_workspace(window, pane)
	local current = mux.get_active_workspace()

	window:perform_action(
		act.PromptInputLine({
			description = string.format("Rename workspace %q:", current),
			action = wezterm.action_callback(function(_, _, line)
				if line and line ~= "" then
					mux.rename_workspace(current, line)
				end
			end),
		}),
		pane
	)
end

-- ====================================================================================================================
-- TAB MANAGEMENT
-- ====================================================================================================================

local function rename_tab(window, pane)
	window:perform_action(
		act.PromptInputLine({
			description = "Rename tab:",
			action = wezterm.action_callback(function(w, _, line)
				if line and line ~= "" then
					w:active_tab():set_title(line)
				end
			end),
		}),
		pane
	)
end

-- ====================================================================================================================
-- SESSION MANAGEMENT
-- ====================================================================================================================

-- Limit saved terminal output to avoid excessively large session files.
resurrect.state_manager.set_max_nlines(10000)

-- Save sessions every five minutes. Layouts and window states are enough to
-- restore the workspace; per-tab states are intentionally not saved.
resurrect.state_manager.periodic_save({
	interval_seconds = 300,
	save_workspaces = true,
	save_windows = true,
	save_tabs = false,
})

-- Update the current workspace pointer after periodic saves.
-- This is important for automatic restoration on startup.
wezterm.on("resurrect.state_manager.periodic_save.finished", function()
	local workspace = mux.get_active_workspace()
	resurrect.state_manager.write_current_state(workspace, "workspace")
end)

-- Automatically restore the last saved workspace on startup.
wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

-- Manual workspace save
local function save_workspace(window)
	local workspace = mux.get_active_workspace()
	local state = resurrect.workspace_state.get_workspace_state()

	resurrect.state_manager.save_state(state, workspace)
	resurrect.state_manager.write_current_state(workspace, "workspace")
	window:toast_notification("WezTerm", "Workspace saved: " .. workspace, nil, 3000)
end

-- Fuzzy session restoration
local function load_workspace(window, pane)
	resurrect.fuzzy_loader.fuzzy_load(window, pane, function(id)
		local state_type, state_name = string.match(id, "^([^/\\]+)[/\\](.+)$")
		if not state_type or not state_name then
			return
		end

		-- State IDs include the .json suffix; state_manager appends it itself.
		state_name = string.gsub(state_name, "%.json$", "")

		if state_type == "workspace" then
			local state = resurrect.state_manager.load_state(state_name, "workspace")
			if state then
				resurrect.workspace_state.restore_workspace(state, {
					window = window,
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				})
			end
		elseif state_type == "window" then
			local state = resurrect.state_manager.load_state(state_name, "window")
			if state then
				resurrect.window_state.restore_window(pane:window(), state, {
					relative = true,
					restore_text = true,
					close_open_tabs = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				})
			end
		end
	end, {
		ignore_tabs = true,
	})
end

-- ====================================================================================================================
-- KEYBINDINGS
-- ====================================================================================================================

config.keys = {
	-- ====================================================================================================================
	-- PANE MANAGEMENT
	-- ====================================================================================================================

	-- Splits (tmux: | = horizontal, - = vertical)
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Resize panes (tmux: h/j/k/l, 5 cells per press)
	{ key = "h", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- Zoom / maximize pane (tmux: m and z)
	{ key = "m", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- Close pane (tmux: x)
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Select panes by direction (tmux: arrow keys)
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },

	-- Next pane (tmux: o)
	{ key = "o", mods = "LEADER", action = act.ActivatePaneDirection("Next") },

	-- Display pane numbers and select one (tmux: q)
	{ key = "q", mods = "LEADER", action = act.PaneSelect({ alphabet = "1234567890" }) },

	-- Break pane out into a new tab (tmux: !)
	{
		key = "!",
		mods = "LEADER|SHIFT",
		action = wezterm.action_callback(function(_, pane)
			pane:move_to_new_tab()
		end),
	},

	-- Rotate panes (kept from the previous WezTerm config; not a tmux binding)
	{ key = "R", mods = "LEADER|SHIFT", action = act.RotatePanes("Clockwise") },

	-- ====================================================================================================================
	-- TAB MANAGEMENT
	-- ====================================================================================================================

	-- New tab in the current pane's directory (tmux: c)
	{ key = "c", mods = "LEADER", action = act.SpawnCommandInNewTab({}) },

	-- Close tab (tmux: &)
	{ key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },

	-- Previous / next tab (tmux: p / n)
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },

	-- Move tab left / right (tmux: { / })
	{ key = "{", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) },
	{ key = "}", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },

	-- Rename tab (tmux: ,)
	{ key = ",", mods = "LEADER", action = wezterm.action_callback(rename_tab) },

	-- Tab picker (tmux: w)
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },

	-- ====================================================================================================================
	-- WORKSPACE MANAGEMENT
	-- ====================================================================================================================

	-- Workspace picker (tmux: s)
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- Create / switch workspace (tmux has no direct default; replaces the old Leader+n binding)
	{ key = "n", mods = "LEADER|CTRL", action = wezterm.action_callback(create_workspace) },

	-- Rename current workspace (tmux: $)
	{ key = "$", mods = "LEADER|SHIFT", action = wezterm.action_callback(rename_workspace) },

	-- Previous / next workspace (tmux: ( / ))
	{ key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
	{ key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1) },

	-- ====================================================================================================================
	-- SESSION MANAGEMENT
	-- ====================================================================================================================

	-- Reload configuration (tmux: r)
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },

	-- Save workspace manually (tmux continuum autosave counterpart)
	{ key = "s", mods = "LEADER|CTRL", action = wezterm.action_callback(save_workspace) },

	-- Restore a saved workspace / window with the fuzzy picker
	{
		key = "r",
		mods = "LEADER|CTRL",
		action = wezterm.action_callback(function(window, pane)
			load_workspace(window, pane)
		end),
	},

	-- ====================================================================================================================
	-- COPY / PASTE
	-- ====================================================================================================================

	-- Copy mode (tmux: [)
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	-- Paste (tmux: P)
	{ key = "P", mods = "LEADER|SHIFT", action = act.PasteFrom("Clipboard") },
}

-- ====================================================================================================================
-- Quick tab selection: Leader + 1 through 9
-- ====================================================================================================================

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- ====================================================================================================================
-- SMART-SPLITS: Ctrl-h/j/k/l across Neovim and WezTerm panes
-- ====================================================================================================================

smart_splits.apply_to_config(config, {
	direction_keys = {
		move = { "h", "j", "k", "l" },
		resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
	},
	modifiers = {
		move = "CTRL",
		resize = "CTRL|SHIFT",
	},
	at_edge = "stop",
})

-- ====================================================================================================================
-- CUSTOM COMMAND PALETTE
-- ====================================================================================================================

wezterm.on("augment-command-palette", function()
	return commands
end)

return config
