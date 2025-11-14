-- lua/plugins/cmp.lua
return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
		"onsails/lspkind-nvim", -- <-- icons for kinds (Class, Function, etc.)
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local lspkind = require("lspkind")

		require("luasnip.loaders.from_vscode").lazy_load()
		require("luasnip.loaders.from_lua").load({
			paths = vim.fn.stdpath("config") .. "/lua/snippets",
		})

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({
					select = true,
					behavior = cmp.ConfirmBehavior.Replace, -- good for additionalTextEdits
				}),
				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					elseif luasnip.expand_or_jumpable() then
						luasnip.expand_or_jump()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif luasnip.jumpable(-1) then
						luasnip.jump(-1)
					else
						fallback()
					end
				end, { "i", "s" }),
			}),

			-- put LSP first, copilot last by default
			sources = cmp.config.sources({
				{ name = "nvim_lsp", priority = 1000 },
				{ name = "path", priority = 750 },
				{ name = "buffer", priority = 500 },
				{ name = "luasnip", priority = 400 },
				{ name = "copilot", priority = 50 }, -- last so it doesn't shadow LSP
			}),

			sorting = {
				priority_weight = 2,
				comparators = {
					cmp.config.compare.score, -- overall score
					cmp.config.compare.locality, -- nearer words
					cmp.config.compare.recently_used,
					cmp.config.compare.kind, -- Class > Text, etc.
					cmp.config.compare.length,
					cmp.config.compare.order,
				},
			},

			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},

			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol_text", -- shows icon + kind text
					maxwidth = 50,
					ellipsis_char = "…",
					show_labelDetails = true,
					menu = {
						nvim_lsp = "[LSP]",
						luasnip = "[Snip]",
						buffer = "[Buf]",
						path = "[Path]",
						copilot = "[AI]",
					},
				}),
			},
		})

		-- Prefer LSP strongly for PHP: put Copilot dead last or disable it
		cmp.setup.filetype("php", {
			sources = cmp.config.sources({
				{ name = "nvim_lsp", priority = 1000 },
				{ name = "path", priority = 800 },
				{ name = "buffer", priority = 600 },
				{ name = "luasnip", priority = 500 },
				{ name = "copilot", priority = 10 },
			}),
		})

		-- `/` search
		cmp.setup.cmdline("/", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = { { name = "buffer" } },
		})
		-- `:` cmdline
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
		})
	end,
}
