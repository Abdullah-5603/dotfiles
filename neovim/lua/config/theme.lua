vim.opt.termguicolors = true

local ok, omarchy_theme = pcall(require, "config.omarchy_theme")
if ok then
	omarchy_theme.apply()
	omarchy_theme.watch()
end
