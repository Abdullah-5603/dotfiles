-- lua/plugins/gitsigns.lua
return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "󰍵" },
			topdelete = { text = "󰍵" },
			changedelete = { text = "▎" },
		},
		current_line_blame = true, -- show git blame inline
	},
	config = function(_, opts)
		require("gitsigns").setup(opts)
	end,
}
