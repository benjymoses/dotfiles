-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.incsearch = true
vim.o.autoread = true -- live reloading of files

vim.g.lazyvim_prettier_needs_config = true --ensures Biome takes priority

vim.opt.wrap = true

-- Clipboard over SSH (cloud desktop): mirror yanks to the Mac's clipboard via OSC 52.
-- The cloud desktop runs nvim inside TWO nested tmux layers (cloud inner tmux, reached
-- over ssh from the laptop's outer tmux) before WezTerm. tmux won't forward plain OSC 52
-- through this chain, so we DOUBLE-WRAP it in tmux passthrough: the inner tmux strips one
-- wrapper, the outer tmux strips the second, and WezTerm receives the OSC 52. Emitted via
-- nvim_ui_send (nvim's core has no tty of its own; this routes through the nvim-tui
-- process to the real pty). `clipboard` is left as LazyVim's SSH default ("") so local
-- registers and buffer-to-buffer paste are untouched. On the laptop (not SSH) this whole
-- block is skipped, so unnamedplus + pbcopy is unchanged.
-- NOTE: assumes exactly 2 nested tmux layers (the standard cloud-desktop setup).
if vim.env.SSH_CONNECTION then
  local function osc52_copy(lines)
    local esc, bel = "\27", "\7"
    local seq = esc .. "]52;c;" .. vim.base64.encode(table.concat(lines, "\n")) .. bel
    if vim.env.TMUX then
      local osc_d = seq:gsub(esc, esc .. esc) -- wrap for the OUTER tmux
      local l1 = esc .. "Ptmux;" .. osc_d .. esc .. "\\"
      local l1_d = l1:gsub(esc, esc .. esc) -- wrap again for the INNER tmux
      seq = esc .. "Ptmux;" .. l1_d .. esc .. "\\"
    end
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
