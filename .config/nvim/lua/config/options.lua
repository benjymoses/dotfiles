-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.incsearch = true
vim.o.autoread = true -- live reloading of files

vim.g.lazyvim_prettier_needs_config = true --ensures Biome takes priority

vim.opt.wrap = true

-- Clipboard over SSH: mirror yanks to the local machine's clipboard via OSC 52.
-- When editing on a remote host over SSH, `pbcopy` is not reachable, so yanks are
-- echoed as an OSC 52 sequence for the outer terminal to pick up. Emitted via
-- nvim_ui_send because nvim's core has no tty of its own; this routes through the
-- nvim-tui process to the real pty. `clipboard` is left as LazyVim's SSH default
-- ("") so local registers and buffer-to-buffer paste are untouched. Outside SSH the
-- whole block is skipped, leaving unnamedplus + pbcopy unchanged.
--
-- This previously double-wrapped the sequence in tmux passthrough to punch through
-- nested tmux layers. tmux is no longer used, so the sequence is emitted plain and
-- the terminal (or any multiplexer in between) is expected to forward it.
if vim.env.SSH_CONNECTION then
  local function osc52_copy(lines)
    local esc, bel = "\27", "\7"
    local seq = esc .. "]52;c;" .. vim.base64.encode(table.concat(lines, "\n")) .. bel
    vim.api.nvim_ui_send(seq)
  end
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("osc52_yank_mirror", { clear = true }),
    callback = function()
      local e = vim.v.event
      if e.operator == "y" and (e.regname == "" or e.regname == "+" or e.regname == "*") then
        osc52_copy(e.regcontents)
      end
    end,
  })
end
