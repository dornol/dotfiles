return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_z = {}
      return opts
    end,
  },
  {
    "folke/snacks.nvim",
    opts = {
      indent = { enabled = false },
    },
  },
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
  -- YAML/JSON extras load SchemaStore only when their language server starts.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "marksman" },
    },
  },
}
