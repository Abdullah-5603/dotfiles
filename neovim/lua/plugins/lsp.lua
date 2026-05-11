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
		local util = require("lspconfig.util")

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

		-- Less ugly diagnostic UI
		vim.diagnostic.config({
			underline = true,
			virtual_text = {
				spacing = 2,
				prefix = "●",
				source = "if_many",
			},
			signs = true,
			severity_sort = true,
			update_in_insert = false,
			float = {
				border = "rounded",
				source = "always",
			},
		})

		local eslint_fix_augroup = vim.api.nvim_create_augroup("EslintFixOnSave", {
			clear = true,
		})

		local eslint_base_on_attach = vim.lsp.config.eslint and vim.lsp.config.eslint.on_attach

		local function eslint_fix_all(client, bufnr)
			if not client then
				return
			end

			client:request_sync("workspace/executeCommand", {
				command = "eslint.applyAllFixes",
				arguments = {
					{
						uri = vim.uri_from_bufnr(bufnr),
						version = vim.lsp.util.buf_versions[bufnr],
					},
				},
			}, 1500, bufnr)
		end

		local eslint_on_attach = function(client, bufnr)
			on_attach(client, bufnr)

			if eslint_base_on_attach then
				eslint_base_on_attach(client, bufnr)
			end

			vim.api.nvim_clear_autocmds({
				group = eslint_fix_augroup,
				buffer = bufnr,
			})

			vim.api.nvim_create_autocmd("BufWritePre", {
				group = eslint_fix_augroup,
				buffer = bufnr,
				callback = function()
					eslint_fix_all(client, bufnr)
				end,
			})
		end

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

			eslint = {
				settings = {
					validate = "on",

					-- Auto-detect current project / monorepo ESLint working directory
					workingDirectory = {
						mode = "auto",
					},

					-- We handle fixing manually on BufWritePre
					codeActionOnSave = {
						enable = false,
						mode = "all",
					},

					format = true,
				},

				on_attach = eslint_on_attach,
			},

			pyright = {},
			gopls = {},
			rust_analyzer = {},
			clangd = {
				cmd = { "clangd", "--background-index", "--clang-tidy" },
				root_dir = util.root_pattern("Makefile", ".git"),
				init_options = {
					fallbackFlags = { "-Iinclude" },
				},
			},
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
							insertUseDeclaration = true,
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

			-- Do not overwrite server-specific on_attach.
			-- ESLint needs its own on_attach for fix-on-save.
			opts.on_attach = opts.on_attach or on_attach

			vim.lsp.config(name, opts)
			vim.lsp.enable(name)
		end
	end,
}
