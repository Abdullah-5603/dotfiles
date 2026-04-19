-- lua/plugins/mason-tool-installer.lua
return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	event = "VeryLazy",
	dependencies = { "williamboman/mason.nvim" },
	opts = {
		ensure_installed = {
			-- LSP-like tools (you can add more here too if you want)
			-- NOTE: LSP servers are handled by mason-lspconfig ensure_installed already.

			-- Formatters / Linters
			-- JS/TS/HTML/CSS/JSON
			-- "prettierd",
			-- "prettier",
			"eslint_d",

			-- Lua
			"stylua",

			-- Python
			"ruff",
			"black",

			-- PHP
			"pint",

			-- Rust
			"codelldb", -- debugger (rustfmt/clippy via rustup: rustup component add rustfmt clippy)

			-- Go
			"golangci-lint",
			"gofumpt",

			-- C/C++
			"clang-format",

			-- Markdown
			"markdownlint",

			-- YAML / TOML
			"yamllint",
			"taplo",

			-- Docker
			"hadolint",

			-- Shell
			"shellcheck",
			"shfmt",
		},
		auto_update = true,
		run_on_start = true,
		start_delay = 300, -- ms
		debounce_hours = 12,
	},
	config = function(_, opts)
		require("mason-tool-installer").setup(opts)

		-- Programmatic install (no UI interaction needed)
		local mr = require("mason-registry")
		mr.refresh(function()
			local to_install = {}
			for _, name in ipairs(opts.ensure_installed or {}) do
				local ok, pkg = pcall(mr.get_package, name)
				if ok and not pkg:is_installed() then
					table.insert(to_install, name)
					pkg:install()
				end
			end
			if #to_install > 0 then
				vim.notify(
					"Installing tools: " .. table.concat(to_install, ", "),
					vim.log.levels.INFO,
					{ title = "Mason" }
				)
			end
		end)
	end,
}
