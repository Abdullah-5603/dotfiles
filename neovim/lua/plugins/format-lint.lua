-- lua/plugins/format-lint.lua
return {
	-- Formatter
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		opts = {
			format_on_save = function(bufnr)
				local eslint_filetypes = {
					astro = true,
					htmlangular = true,
					javascript = true,
					javascriptreact = true,
					svelte = true,
					typescript = true,
					typescriptreact = true,
					vue = true,
				}

				if eslint_filetypes[vim.bo[bufnr].filetype] then
					return
				end

				return { timeout_ms = 1000, lsp_fallback = true }
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				--	javascript = { "prettierd", "prettier" },
				-- typescript = { "prettierd", "prettier" },
				-- javascriptreact = { "prettierd", "prettier" },
				-- typescriptreact = { "prettierd", "prettier" },
				json = { "prettierd", "prettier" },
				html = { "prettierd", "prettier" },
				css = { "prettierd", "prettier" },
				scss = { "prettierd", "prettier" },
				yaml = { "prettierd", "prettier" },
				toml = { "taplo" },
				sh = { "shfmt" },
				php = { "pint" },
				go = { "gofumpt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				python = { "ruff", "black" },
				blade = { "blade-formatter" },
			},
		},
		config = function(_, opts)
			require("conform").setup(opts)
			-- optional: keymap to format
			vim.keymap.set({ "n", "v" }, "<leader>fm", function()
				require("conform").format({ async = true, lsp_fallback = true })
			end, { desc = "Format buffer" })
		end,
	},

	-- Linter
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost", "InsertLeave" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				markdown = { "markdownlint" },
				yaml = { "yamllint" },
				dockerfile = { "hadolint" },
				sh = { "shellcheck" },
				python = { "ruff" },
				-- php = { "pint" },
				go = { "golangci_lint" },
			}
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
			vim.keymap.set("n", "<leader>ll", function()
				require("lint").try_lint()
			end, { desc = "Lint now" })
		end,
	},
}
