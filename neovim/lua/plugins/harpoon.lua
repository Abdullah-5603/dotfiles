return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
		end

		-- Add / Remove
		map("<leader>ha", function()
			harpoon:list():add()
		end, "Harpoon add file")
		map("<leader>hr", function()
			harpoon:list():remove()
		end, "Harpoon remove file")

		-- Floating UI with Nui
		map("<leader>hh", function()
			harpoon.ui:toggle_quick_menu(harpoon:list(), {
				ui_opts = {
					border = "rounded",
					title = "Harpoon Files",
					title_pos = "center",
					width = 50,
					height = 12,
				},
			})
		end, "Harpoon menu")

		-- Quick nav
		map("<leader>h1", function()
			harpoon:list():select(1)
		end, "Harpoon file 1")
		map("<leader>h2", function()
			harpoon:list():select(2)
		end, "Harpoon file 2")
		map("<leader>h3", function()
			harpoon:list():select(3)
		end, "Harpoon file 3")
		map("<leader>h4", function()
			harpoon:list():select(4)
		end, "Harpoon file 4")
	end,
}
