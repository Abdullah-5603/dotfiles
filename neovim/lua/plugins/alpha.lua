-- lua/plugins/alpha.lua
return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		-- Header (custom text: NULL)
		dashboard.section.header.val = {
			"███╗   ██╗██╗   ██╗██╗     ██╗     ",
			"████╗  ██║██║   ██║██║     ██║     ",
			"██╔██╗ ██║██║   ██║██║     ██║     ",
			"██║╚██╗██║██║   ██║██║     ██║     ",
			"██║ ╚████║╚██████╔╝███████╗███████╗",
			"╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝",
		}

		-- Buttons
		dashboard.section.buttons.val = {
			dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
			dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
			dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
			dashboard.button("g", "  Live grep", ":Telescope live_grep<CR>"),
			dashboard.button("c", "  Config", ":e $MYVIMRC<CR>"),
			dashboard.button("q", "  Quit", ":qa<CR>"),
		}

		-- Footer
		dashboard.section.footer.val = "⚡ Neovim is loaded. Enjoy ⚡"

		alpha.setup(dashboard.opts)
	end,
}
