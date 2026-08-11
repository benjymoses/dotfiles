-- vim-herdr-navigation, Neovim side.
--
-- Loads the editor half of the herdr plugin so <C-h/j/k/l> moves between Neovim
-- splits and, at a split edge, crosses into the neighbouring herdr pane.
--
-- Why after/plugin: this directory is sourced once plugins have loaded, so these
-- maps win over LazyVim's default window-navigation maps.
--
-- The upstream file falls back to tmux (if $TMUX is set) or plain wincmd when
-- not inside a herdr pane, so this is safe in every context.
--
-- The path is globbed because herdr installs plugins into a hashed directory,
-- which changes when the plugin is reinstalled or updated.
--
-- To revert: delete this file.

local pattern = vim.fn.expand("~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua")
local matches = vim.fn.glob(pattern, true, true)

if #matches > 0 then
  local ok, err = pcall(dofile, matches[1])
  if not ok then
    vim.notify("herdr_nav: failed to load " .. matches[1] .. ": " .. tostring(err), vim.log.levels.WARN)
  end
end
