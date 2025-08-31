-- lua/plugins/neoscroll.lua
return {
	"karb94/neoscroll.nvim",
	event = "VeryLazy",
	config = function()
		require("neoscroll").setup({
			-- All are optional, defaults are shown here:
			hide_cursor = true, -- Hide cursor while scrolling
			stop_eof = true, -- Stop at <EOF> when scrolling down
			use_local_scrolloff = false, -- Use the local scope of scrolloff instead of global
			respect_scrolloff = true, -- Stop scrolling when cursor reaches scrolloff margin
			cursor_scrolls_alone = true, -- Cursor will keep scrolling even if window cannot
			easing_function = nil, -- Default easing function (can be "sine", "cubic", "quint")
			pre_hook = nil, -- Function to run before scrolling starts
			post_hook = nil, -- Function to run after scrolling ends
		})
	end,
}
