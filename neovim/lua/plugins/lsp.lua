-- lua/plugins/lsp.lua
return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		if ok_cmp then
			capabilities = cmp_lsp.default_capabilities(capabilities)
		end

		-- common on_attach
		local on_attach = function(_, bufnr)
			local opts = { buffer = bufnr, silent = true }
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		end

		-- global diagnostic UI
		vim.diagnostic.config({
			underline = true,
			virtual_text = { spacing = 2, prefix = "●" },
			severity_sort = true,
			float = { border = "rounded" },
		})

		-- Configure servers with new API
		local servers = {
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
					},
				},
			},
			ts_ls = {},
			pyright = {},
			gopls = {},
			rust_analyzer = {},
			clangd = {},
			html = {},
			cssls = {},
			jsonls = {},
			yamlls = {},
			dockerls = {},
			marksman = {},
			intelephense = {
				settings = {
					intelephense = {
						files = { maxSize = 5000000 },
						environment = { includePaths = { "vendor" } },
						completion = {
							insertUseDeclaration = true, -- <<< auto-add `use` on confirm
							fullyQualifyGlobalConstantsAndFunctions = false,
							triggerParameterHints = true,
						},
						telemetry = { enabled = false },
					},
				},
			},
			bashls = {},
		}

		for name, opts in pairs(servers) do
			opts.capabilities = capabilities
			opts.on_attach = on_attach
			vim.lsp.config(name, opts) -- register config
			vim.lsp.enable(name) -- start if applicable
		end
	end,
}
