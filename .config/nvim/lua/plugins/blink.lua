return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      list = {
        selection = {
          -- Don't auto-highlight the first item, so <CR> makes a newline
          -- unless you've deliberately selected something. Accept with <C-y>,
          -- or press <Down>/<C-n> to pick an item and then <CR>.
          preselect = false,
        },
      },
    },
    sources = {
      -- In prose, offer ONLY filename (path) completion: no buffer-word or
      -- snippet noise, so normal typing stays clean and <CR> is never hijacked.
      -- Code files keep the full default set (LSP symbols, path, snippets, buffer).
      per_filetype = {
        markdown = { "path" },
        text = { "path" },
        gitcommit = { "path" },
      },
    },
  },
}
