-- lua/plugins/floaterm.lua
return {
	"voldikss/vim-floaterm",
	cmd = { "FloatermToggle", "FloatermNew", "FloatermNext", "FloatermPrev" },
	init = function()
		-- Window look
		vim.g.floaterm_width = 0.7
		vim.g.floaterm_height = 0.5
		vim.g.floaterm_borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

		-- Centered title text: "Terminal (index/total)"
		vim.g.floaterm_title = "Terminal ($1/$2)"
		vim.g.floaterm_titleposition = "center"
	end,
	keys = function()
		local K = {}

		-- helper to make mappings work from both normal & terminal mode
		local function map_bimode(lhs, rhs, desc)
			table.insert(K, { lhs, rhs, desc = desc, mode = "n" })
			table.insert(K, { lhs, ([[<C-\><C-n>]] .. rhs), desc = desc, mode = "t" })
		end

		-- toggle last terminal
		map_bimode("<leader>tt", "<cmd>FloatermToggle<CR>", "Toggle terminal")

		-- new terminal
		map_bimode("<leader>tn", "<cmd>FloatermNew<CR>", "New terminal")
		map_bimode("<leader>tj", "<cmd>FloatermPrev<CR>", "Previous terminal")
		map_bimode("<leader>tk", "<cmd>FloatermNext<CR>", "Next terminal")

		-- t1..t9 → named terminal slots (always valid; create if missing)
		for i = 1, 9 do
			local lhs = string.format("<leader>t%d", i)
			local rhs = string.format("<cmd>FloatermToggle term%d<CR>", i)
			map_bimode(lhs, rhs, string.format("Terminal slot #%d", i))
		end

		return K
	end,
	config = function() end, -- nothing else needed
}
