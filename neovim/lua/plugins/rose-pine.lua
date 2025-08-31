-- lua/plugins/colorscheme.lua
return {
	"rose-pine/neovim",
	name = "rose-pine",
	-- enabled = false,
	lazy = false,
	priority = 1000,
	config = function()
		require("rose-pine").setup({
			variant = "auto",
			dark_variant = "main",
			styles = {
				transparency = true, -- enable transparency
			},
		})

		-- Apply colorscheme
		vim.cmd("colorscheme rose-pine")

		-- Force transparency for Normal + Floating windows
		vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
		vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
		vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
	end,
}
