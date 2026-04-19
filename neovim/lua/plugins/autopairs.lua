return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = true,
	-- This is optional but recommended if you use nvim-cmp
	opts = {
		check_ts = true, -- uses treesitter to check for pairs
	}
}
