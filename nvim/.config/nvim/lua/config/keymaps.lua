-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move between Neovim windows and WezTerm panes
vim.keymap.set("n", "<C-h>", function()
  require("smart-splits").move_cursor_left()
end, { desc = "Move left" })
vim.keymap.set("n", "<C-j>", function()
  require("smart-splits").move_cursor_down()
end, { desc = "Move down" })
vim.keymap.set("n", "<C-k>", function()
  require("smart-splits").move_cursor_up()
end, { desc = "Move up" })
vim.keymap.set("n", "<C-l>", function()
  require("smart-splits").move_cursor_right()
end, { desc = "Move right" })

-- Resize Neovim windows or, at their edge, the surrounding WezTerm pane
vim.keymap.set("n", "<C-S-Left>", function()
  require("smart-splits").resize_left()
end, { desc = "Resize left" })
vim.keymap.set("n", "<C-S-Down>", function()
  require("smart-splits").resize_down()
end, { desc = "Resize down" })
vim.keymap.set("n", "<C-S-Up>", function()
  require("smart-splits").resize_up()
end, { desc = "Resize up" })
vim.keymap.set("n", "<C-S-Right>", function()
  require("smart-splits").resize_right()
end, { desc = "Resize right" })
