return {
  "nvim-tree/nvim-tree.lua",
  cmd = {
    "NvimTreeToggle",
    "NvimTreeOpen",
    "NvimTreeFindFile",
  },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    { "<leader>E", "<cmd>NvimTreeFocus<cr>", desc = "Focus file explorer" },
    { "<leader>w", "<cmd>wincmd p<cr>", desc = "Focus previous window" },
  },
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        if vim.fn.isdirectory(data.file) == 1 then
          vim.cmd.cd(data.file)
          require("nvim-tree.api").tree.open()
        end
      end,
    })
  end,
  opts = {
    view = {
      side = "left",
      width = 32,
    },
    renderer = {
      group_empty = true,
      icons = {
        git_placement = "after",
      },
    },
    filters = {
      dotfiles = false,
    },
    git = {
      ignore = false,
    },
    update_focused_file = {
      enable = true,
      update_root = false,
    },
    actions = {
      open_file = {
        quit_on_open = false,
        resize_window = true,
      },
    },
  },
}
