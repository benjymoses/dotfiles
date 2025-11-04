-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.incsearch = true
vim.o.autoread = true -- live reloading of files

vim.g.lazyvim_prettier_needs_config = true --ensures Biome takes priority

vim.opt.wrap = true