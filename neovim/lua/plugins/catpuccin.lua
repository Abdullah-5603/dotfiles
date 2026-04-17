-- lua/plugins/colorscheme.lua
return {
	"catppuccin/nvim",
	name = "catppuccin",
	enabled = false,
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- latte, frappe, macchiato, mocha
			transparent_background = false, -- true for terminal background
			integrations = {
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				telescope = true,
				treesitter = true,
				mason = true,
				notify = true,
			},
		})

		-- Apply colorscheme
		vim.cmd.colorscheme("catppuccin")

		-- Extra transparency adjustments
		-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
		-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
		-- vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
		-- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
	end,
}
