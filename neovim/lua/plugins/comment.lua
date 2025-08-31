-- lua/plugins/comment.lua
return {
	"numToStr/Comment.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	opts = {
		pre_hook = nil, -- custom pre-hooks can go here
	},
	config = function(_, opts)
		require("Comment").setup(opts)
	end,
}
