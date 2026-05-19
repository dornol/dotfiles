return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      indent = {
        -- YAML treesitter indent가 LSP indent와 충돌해서 불안정함
        disable = { "yaml" },
      },
    },
  },
  {
    "lambdalisue/suda.vim",
    cmd = { "SudaRead", "SudaWrite" },
    init = function()
      vim.cmd([[cnoreabbrev w!! SudaWrite]])
    end,
  },
  -- YAML 스키마 자동 감지 (k8s, GitHub Actions, docker-compose 등)
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
          on_new_config = function(config)
            config.settings.json.schemas = config.settings.json.schemas or {}
            vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
          end,
        },
      },
    },
  },
}
