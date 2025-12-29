return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")

    configs.setup({
      ensure_installed = {
          "lua", "vim", "vimdoc", "bash",
          "json", "yaml",
          "html", "css",
          "javascript", "typescript", "tsx",
          "markdown", "markdown_inline",
          "dockerfile", "gitignore",
          "regex", "query",
      },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}