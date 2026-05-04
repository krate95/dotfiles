return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "lua", "vim", "vimdoc", "bash",
        "json", "yaml",
        "html", "css",
        "javascript", "typescript", "tsx",
        "markdown", "markdown_inline",
        "dockerfile", "gitignore",
        "regex", "query",
      }

      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      if vim.fn.executable("tree-sitter") == 1 then
        require("nvim-treesitter").install(parsers)
      end

      -- Enable highlighting per filetype when the parser is available.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "lua","vim","bash","json","yaml","html","css",
          "javascript","typescript","typescriptreact",
          "markdown","dockerfile","gitignore",
        },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
