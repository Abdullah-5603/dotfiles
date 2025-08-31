-- lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate", -- auto update parsers
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "lua", "vim", "vimdoc", "bash",
      "javascript", "typescript", "tsx", "json",
      "html", "css", "scss",
      "php", "python", "rust",
      "c", "cpp", "go",
      "markdown", "markdown_inline",
      "yaml", "toml", "dockerfile",
      "query", "regex",
    },
    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,        -- enable syntax highlighting
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,        -- treesitter-based indentation
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}

