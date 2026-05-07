return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "yamlls",
          "ts_ls",
          "lua_ls",
          "helm_ls",
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      vim.filetype.add({
        pattern = {
          [".*/templates/.*%.ya?ml"] = "helm",
          [".*/templates/.*%.tpl"] = "helm",
          [".*/values.*%.ya?ml"] = "yaml.helm-values",
        },
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config('yamlls', {
        capabilities = capabilities,
        settings = {
          redhat = {
            telemetry = {
              enabled = false,
            },
          },
          yaml = {
            schemaStore = {
              enable = true,
            },
            schemas = {
              kubernetes = {
                "*.k8s.yaml",
                "*.k8s.yml",
                "k8s/**/*.yaml",
                "k8s/**/*.yml",
                "kubernetes/**/*.yaml",
                "kubernetes/**/*.yml",
                "manifests/**/*.yaml",
                "manifests/**/*.yml",
                "deploy/**/*.yaml",
                "deploy/**/*.yml",
                "deployment.yaml",
                "deployment.yml",
                "*deployment*.yaml",
                "*deployment*.yml",
                "service.yaml",
                "service.yml",
                "*service*.yaml",
                "*service*.yml",
                "ingress.yaml",
                "ingress.yml",
                "*ingress*.yaml",
                "*ingress*.yml",
                "configmap.yaml",
                "configmap.yml",
                "*configmap*.yaml",
                "*configmap*.yml",
                "secret.yaml",
                "secret.yml",
                "*secret*.yaml",
                "*secret*.yml",
                "*namespace*.yaml",
                "*namespace*.yml",
                "*cronjob*.yaml",
                "*cronjob*.yml",
                "*job*.yaml",
                "*job*.yml",
                "*pod*.yaml",
                "*pod*.yml",
                "*pvc*.yaml",
                "*pvc*.yml",
              },
              ["https://json.schemastore.org/kustomization"] = "kustomization.yaml",
              ["https://json.schemastore.org/chart"] = "Chart.yaml",
              ["https://json.schemastore.org/helmfile"] = "helmfile.yaml",
            },
            validate = true,
            completion = true,
            hover = true,
          }
        },
        filetypes = { "yaml", "yml" },
        on_attach = function(client, bufnr)
          local path = vim.api.nvim_buf_get_name(bufnr)
          if path:match("templates/") then
            vim.lsp.buf_detach_client(bufnr, client.id)
          end
        end
      })

      vim.lsp.config('helm_ls', {
        capabilities = capabilities,
        filetypes = { "helm", "yaml.helm-values" },
        settings = {
          ['helm-ls'] = {
            yamlls = {
              enabled = true,
              config = {
                schemas = {
                  kubernetes = "templates/**",
                },
                completion = true,
                hover = true,
              },
            }
          }
        }
      })

      vim.lsp.config('ts_ls', {
        capabilities = capabilities,
      })
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
      })

      vim.lsp.enable({ 'yamlls', 'ts_ls', 'lua_ls', 'helm_ls' })
    end
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
          ['<C-e>'] = cmp.mapping.abort(),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        },
      })
    end
  }
}
