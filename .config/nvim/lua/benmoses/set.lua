vim.g.mapleader = " "

vim.cmd.colorscheme("catppuccin")
 
vim.opt.clipboard = 'unnamedplus' -- use system keyboard for yank
 
vim.opt.relativenumber = true     -- use relative line numbers
vim.opt.number = true
-- set tab size to 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
 
vim.opt.wrap = true

vim.diagnostic.config({
  signs = false,
  underline = false
})
 
vim.opt.incsearch = true -- incremental search
 
vim.opt.termguicolors = true
