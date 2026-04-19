local map = vim.keymap.set

-- Helper function to get the PascalCase filename
local function get_pascal_name()
	local name = vim.fn.expand("%:t:r")
	-- 1. Capitalize the first letter
	name = name:gsub("^%l", string.upper)
	-- 2. Find underscores followed by a letter and uppercase that letter
	name = name:gsub("_(%l)", string.upper)
	-- 3. Remove the underscores
	name = name:gsub("_", "")
	return name
end

-- When text is wrapped, m by terminal rows, not line, unless a count is provided.
-- example of key-maps map(mode, mapping_key, execute_command, options)
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Reselect visual selection after indenting
map("v", "<", "<v")
map("v", ">", ">gv")

-- Maintain the cursor position when yanking a visual selection
map("v", "y", "myy`y")

-- Disable command line typo
map("n", "q:", ":q")

-- Paste replace visual selection without copying it
map("v", "p", '"_dP')

-- Easy insertion of trailing characters
map("i", ";;", "<Esc>A;")
map("i", ",,", "<Esc>A,")

-- Go to end of the line in insert mode
map("i", "<C-e>", "<Esc>A")

-- Keybindings for no highlights
map("n", "<Leader>k", ":nohlsearch<CR>")

-- Open current file in the default program
map("n", "<Leader>x", ":!open %<CR><CR>")

-- Move line ups to down by keymap
map("n", "<C-j>", ":m .+1<CR>==")
map("n", "<C-k>", ":m .-2<CR>==")
map("v", "<C-j>", ":m '>+1<CR>gv=gv")
map("v", "<C-k>", ":m '<-2<CR>gv=gv")

-- custom code shortcuts
map("i", "clg", [[console.log({  })<Left><Left><Left>]])

-- 1. rfc (Standard)
map("i", "rfc", function()
	local name = get_pascal_name()
	return "function " .. name .. "() {\n  return (\n    <div>" .. name .. "</div>\n  )\n}"
end, { expr = true })

-- 2. rfce (Export)
map("i", "rfce", function()
	local name = get_pascal_name()
	return "export function " .. name .. "() {\n  return (\n    <div>" .. name .. "</div>\n  )\n}"
end, { expr = true })

-- 3. rfced (Export Default)
map("i", "rfced", function()
	local name = get_pascal_name()
	return "export default function " .. name .. "() {\n  return (\n    <div>" .. name .. "</div>\n  )\n}"
end, { expr = true })
