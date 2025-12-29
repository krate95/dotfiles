return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

    -- Install parsers asynchronously. If they are already installed, it does nothing.
      require("nvim-treesitter").install({
        "lua", "vim", "vimdoc", "bash",
        "json", "yaml",
        "html", "css",
        "javascript", "typescript", "tsx",
        "markdown", "markdown_inline",
        "dockerfile", "gitignore",
        "regex", "query",
      })

    -- Enable highlighting per filetype (Neovim provides the highlighting)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "lua","vim","bash","json","yaml","html","css",
          "javascript","typescript","typescriptreact",
          "markdown","dockerfile","gitignore",
        },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },
}