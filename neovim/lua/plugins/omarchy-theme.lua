local ok, omarchy_theme = pcall(require, "config.omarchy_theme")

if not ok then
	return {}
end

return omarchy_theme.plugin_specs()
