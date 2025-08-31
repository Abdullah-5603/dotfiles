-- lua/plugins/surround.lua
return {
	"kylechui/nvim-surround",
	version = "*", -- use the latest stable version
	event = "VeryLazy",
	config = function()
		require("nvim-surround").setup({})
	end,
}
