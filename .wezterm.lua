local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13.0
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.colors = {
  foreground = "#24292E",
  background = "#FFFFFF",
  cursor_bg = "#044289",
  cursor_fg = "#FFFFFF",
  cursor_border = "#044289",
  selection_bg = "#0366D6",
  selection_fg = "#FFFFFF",
  ansi = {
    "#24292E",
    "#D73A49",
    "#22863A",
    "#B08800",
    "#0366D6",
    "#6F42C1",
    "#1B7C83",
    "#6A737D",
  },
  brights = {
    "#959DA5",
    "#CB2431",
    "#28A745",
    "#DBAB09",
    "#2188FF",
    "#8A63D2",
    "#3192AA",
    "#D1D5DA",
  },
}
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.bold_brightens_ansi_colors = false
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.scrollback_lines = 10000
config.enable_scroll_bar = false

return config
