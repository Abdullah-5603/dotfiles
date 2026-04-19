local M = {}

local uv = vim.uv or vim.loop

local omarchy_dir = vim.fn.expand("~/.config/omarchy")
local current_theme_file = omarchy_dir .. "/current/theme/neovim.lua"
local current_theme_name_file = omarchy_dir .. "/current/theme.name"
local reload_signal_file = vim.fn.stdpath("cache") .. "/omarchy-theme-reload"

local function plugin_name(spec)
	if type(spec) ~= "table" then
		return nil
	end

	if spec.name then
		return spec.name
	end

	if type(spec[1]) == "string" then
		return spec[1]:match("[^/]+$")
	end

	return nil
end

local function load_theme_file(path)
	if vim.fn.filereadable(path) ~= 1 then
		return {}
	end

	local chunk, err = loadfile(path)
	if not chunk then
		vim.notify("Could not load Omarchy theme file: " .. err, vim.log.levels.WARN)
		return {}
	end

	local ok, result = pcall(chunk)
	if not ok then
		vim.notify("Could not evaluate Omarchy theme file: " .. result, vim.log.levels.WARN)
		return {}
	end

	return type(result) == "table" and result or {}
end

local function normalize_specs(specs, lazy)
	local normalized = {}
	local colorscheme = nil
	local names = {}
	local items = specs

	if type(specs[1]) == "string" then
		items = { specs }
	end

	for _, spec in ipairs(items) do
		if type(spec) == "table" then
			if spec[1] == "LazyVim/LazyVim" then
				if type(spec.opts) == "table" and type(spec.opts.colorscheme) == "string" then
					colorscheme = spec.opts.colorscheme
				end
			else
				local copy = vim.deepcopy(spec)
				copy.lazy = lazy
				copy.priority = copy.priority or 1000

				table.insert(normalized, copy)
				local name = plugin_name(copy)
				if name then
					table.insert(names, name)
				end
			end
		end
	end

	return normalized, colorscheme, names
end

local function run_theme_configs(specs)
	local items = specs

	if type(specs[1]) == "string" then
		items = { specs }
	end

	for _, spec in ipairs(items) do
		if type(spec) == "table" and spec[1] ~= "LazyVim/LazyVim" and type(spec.config) == "function" then
			local ok, err = pcall(spec.config, spec, spec.opts or {})
			if not ok then
				vim.notify("Could not run Omarchy theme config: " .. err, vim.log.levels.WARN)
			end
		end
	end
end

local function add_installed_theme_to_runtimepath(name)
	local candidates = {
		vim.fn.stdpath("data") .. "/lazy/" .. name,
		vim.fn.stdpath("data") .. "/lazy/" .. name:gsub("%.nvim$", ""),
	}

	for _, path in ipairs(candidates) do
		if vim.fn.isdirectory(path) == 1 then
			vim.opt.runtimepath:prepend(path)
			return true
		end
	end

	return false
end

function M.plugin_specs()
	local specs_for_file = load_theme_file(current_theme_file)
	local specs, colorscheme = normalize_specs(specs_for_file, false)
	vim.g.omarchy_colorscheme = colorscheme

	return specs
end

function M.apply()
	vim.opt.termguicolors = true

	local specs = load_theme_file(current_theme_file)
	local _, colorscheme, names = normalize_specs(specs, false)

	local lazy_ok, lazy = pcall(require, "lazy")
	if lazy_ok then
		for _, name in ipairs(names) do
			local ok = pcall(lazy.load, { plugins = { name }, wait = true })
			if not ok then
				add_installed_theme_to_runtimepath(name)
			end
		end
	end

	run_theme_configs(specs)

	if colorscheme then
		local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
		if not ok then
			vim.notify("Could not apply Omarchy colorscheme " .. colorscheme .. ": " .. err, vim.log.levels.WARN)
		end
		return
	end

	load_theme_file(current_theme_file)
end

local function ensure_reload_signal()
	local cache_dir = vim.fn.fnamemodify(reload_signal_file, ":h")
	if vim.fn.isdirectory(cache_dir) ~= 1 then
		vim.fn.mkdir(cache_dir, "p")
	end

	if vim.fn.filereadable(reload_signal_file) ~= 1 then
		vim.fn.writefile({ tostring(os.time()) }, reload_signal_file)
	end
end

function M.watch()
	ensure_reload_signal()

	if vim.g.omarchy_theme_watch_started then
		return
	end
	vim.g.omarchy_theme_watch_started = true

	local timer = uv.new_timer()
	local function reload()
		timer:stop()
		timer:start(120, 0, function()
			vim.schedule(M.apply)
		end)
	end

	vim.g.omarchy_theme_watchers = {}
	for _, path in ipairs({ current_theme_file, current_theme_name_file, reload_signal_file }) do
		if vim.fn.filereadable(path) == 1 then
			local watcher = uv.new_fs_event()
			watcher:start(path, {}, reload)
			table.insert(vim.g.omarchy_theme_watchers, watcher)
		end
	end
end

return M
