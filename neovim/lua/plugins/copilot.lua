-- lua/plugins/copilot.lua
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			suggestion = {
				enabled = true,
				auto_trigger = true, -- show suggestions as you type
				debounce = 75,
				keymap = {
					accept = "<C-j>", -- accept suggestion
					next = "<M-]>", -- next suggestion
					prev = "<M-[>", -- previous suggestion
					dismiss = "<C-]>",
				},
			},
			panel = { enabled = false }, -- disable side panel
			filetypes = {
				markdown = true,
				help = true,
				gitcommit = true,
				["*"] = true, -- enable everywhere
			},
		},
		config = function(_, opts)
			require("copilot").setup(opts)
		end,
	},
}
