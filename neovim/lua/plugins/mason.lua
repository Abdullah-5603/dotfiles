-- lua/plugins/mason.lua
return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = "Mason",
		opts = { ui = { border = "rounded" } },
		config = function(_, opts)
			require("mason").setup(opts)
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua_ls",
				"bashls",
				"ts_ls",
				"html",
				"cssls",
				"jsonls",
				"pyright",
				"rust_analyzer",
				"clangd",
				"gopls",
				"marksman",
				"yamlls",
				"dockerls",
				"intelephense",
			},
		},
		config = function(_, opts)
			require("mason-lspconfig").setup(opts)
		end,
	},
}
