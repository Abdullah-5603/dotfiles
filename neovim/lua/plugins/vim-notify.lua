-- lua/plugins/notify.lua
return {
	"rcarriga/nvim-notify",
	event = "VeryLazy",
	config = function()
		require("notify").setup({
			stages = "fade_in_slide_out",
			timeout = 3000,
			render = "compact",
			top_down = true, -- notifications start from the top
			position = "top_right", -- explicit: top-right corner
			background_colour = "#000000", -- keep transparent-friendly background
		})
		vim.notify = require("notify")
	end,
}
