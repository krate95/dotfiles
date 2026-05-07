return {
  'akinsho/bufferline.nvim',
  version = "*",
  keys = {
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
    {
      "<leader>x",
      function()
        local current = vim.api.nvim_get_current_buf()
        local listed_buffers = vim.tbl_filter(function(buffer)
          return vim.bo[buffer].buflisted
        end, vim.api.nvim_list_bufs())

        if #listed_buffers > 1 then
          vim.cmd("BufferLineCycleNext")
        end

        vim.cmd("bdelete " .. current)
      end,
      desc = "Close buffer",
    },
  },
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    vim.opt.termguicolors = true
    require('bufferline').setup {}
  end
}
