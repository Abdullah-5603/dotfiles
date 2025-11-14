return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},

	config = function()
		require("neo-tree").setup({
			close_if_last_window = true,

			filesystem = {
				follow_current_file = {
					enabled = true,
				},
				filtered_items = {
					visible = true,
					show_hidden = true,
				},
			},

			default_component_configs = {
				indent = { indent_size = 2, padding = 1 },
			},

			-- 🔥 AUTO CLOSE SIDEBAR WHEN A FILE IS OPENED
			event_handlers = {
				{
					event = "file_opened",
					handler = function(file_path)
						-- close all neo-tree windows
						require("neo-tree.command").execute({ action = "close" })
					end,
				},
			},
		})

		-- <leader>e toggles the sidebar
		vim.keymap.set("n", "<leader>e", ":Neotree toggle left<CR>", {
			desc = "Toggle File Explorer",
		})
	end,
}
