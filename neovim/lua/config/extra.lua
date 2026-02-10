local function keep_cursor_middle()
	local group = vim.api.nvim_create_augroup("KeepCursorMiddle", { clear = true })
	local added_lines = 0

	-- Helper function to check if buffer should be ignored
	local function should_ignore_buffer()
		local buftype = vim.bo.buftype
		local filetype = vim.bo.filetype

		-- Ignore special buffers
		if buftype ~= "" then
			return true
		end

		-- Ignore specific filetypes
		local ignore_filetypes = {
			"neo-tree",
			"NvimTree",
			"help",
			"qf",
			"prompt",
			"nofile",
			"terminal",
		}

		for _, ft in ipairs(ignore_filetypes) do
			if filetype == ft then
				return true
			end
		end

		return false
	end

	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = function()
			-- Skip if special buffer
			if should_ignore_buffer() then
				return
			end

			vim.opt.scrolloff = 999
			-- Get window height and add empty lines at the end
			local win_height = vim.api.nvim_win_get_height(0)
			local buf = vim.api.nvim_get_current_buf()
			local total_lines = vim.api.nvim_buf_line_count(buf)
			-- Add padding lines (half of window height)
			local padding = math.floor(win_height / 2) + 5
			added_lines = padding
			local empty_lines = {}
			for i = 1, padding do
				table.insert(empty_lines, "")
			end
			vim.api.nvim_buf_set_lines(buf, total_lines, total_lines, false, empty_lines)
			-- Center the cursor
			vim.cmd("normal! zz")
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function()
			-- Skip if special buffer
			if should_ignore_buffer() then
				return
			end

			vim.opt.scrolloff = 0
			-- Remove the padding lines we added
			if added_lines > 0 then
				local buf = vim.api.nvim_get_current_buf()
				local total_lines = vim.api.nvim_buf_line_count(buf)
				-- Remove empty lines from the end
				local start_line = total_lines - added_lines
				vim.api.nvim_buf_set_lines(buf, start_line, total_lines, false, {})
				added_lines = 0
			end
		end,
	})
end

keep_cursor_middle()
