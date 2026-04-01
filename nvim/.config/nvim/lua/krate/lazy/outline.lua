return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>o", "<cmd>Outline<cr>", desc = "Toggle outline" },
  },
  config = function()
    require("outline").setup({})
  end,
}