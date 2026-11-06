return {
  {
    "smart-splits-nvim/smart-splits.nvim",
    version = "^3.0.0",
    dependencies = {
      {
        "smart-splits-nvim/backend-wezterm",
        main = "smart-splits-backend-wezterm",
        opts = { cli_path = "wezterm" },
      },
    },
    opts = {
      mux = { backend = "smart-splits-backend-wezterm" },
    },
  },
}
