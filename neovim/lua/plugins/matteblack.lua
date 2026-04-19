return {
	"tahayvr/matteblack.nvim",
	lazy = false,  -- Make sure the theme loads immediately
	priority = 1000, -- Load it before other plugins
	config = function()
		vim.cmd("colorscheme matteblack")
	end,
}
