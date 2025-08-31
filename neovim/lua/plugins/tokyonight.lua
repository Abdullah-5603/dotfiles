-- lua/plugins/colorscheme.lua
return {
	"folke/tokyonight.nvim",
	enabled = false,
	lazy = false,
	priority = 1000,
	config = function()
		require("tokyonight").setup({
			style = "moon", -- "storm", "night", "day", or "moon"
			transparent = true, -- true = use terminal background
			styles = {
				sidebars = "dark", -- style for sidebars (NvimTree, etc.)
				floats = "dark", -- style for floating windows
			},
		})

		-- Apply colorscheme
		vim.cmd.colorscheme("tokyonight")

		-- Optional: extra solid backgrounds (if transparency leaked before)
		vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	end,
}
