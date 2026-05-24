local M = {}

function M.check()
	vim.health.start("todoage")

	if vim.fn.has("nvim-0.10") == 1 then
		vim.health.ok("Neovim " .. tostring(vim.version()) .. " (>= 0.10 required for vim.system)")
	else
		vim.health.error("Neovim 0.10+ required, found " .. tostring(vim.version()))
	end

	if vim.fn.executable("git") == 1 then
		vim.health.ok("`git` found on PATH")
	else
		vim.health.error("`git` not found on PATH — install it to enable blame")
	end

	local probe = { "lua", "javascript", "typescript", "python", "c", "go", "rust", "ruby" }
	local found = {}
	for _, lang in ipairs(probe) do
		if pcall(vim.treesitter.language.add, lang) then
			table.insert(found, lang)
		end
	end
	if #found > 0 then
		vim.health.ok("tree-sitter parsers available: " .. table.concat(found, ", "))
	else
		vim.health.warn(
			"no common tree-sitter parsers detected — install via `:TSInstall <lang>` "
				.. "(files without a parser are silently skipped)"
		)
	end
end

return M
