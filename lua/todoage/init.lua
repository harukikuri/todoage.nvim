local ns = vim.api.nvim_create_namespace("todoage")

local M = {}

local function mark(lnum)
	vim.api.nvim_buf_set_extmark(0, ns, lnum, 0, {
		virt_text = { { "(found)", "Comment" } },
		virt_text_pos = "eol",
	})
end

local function scan_comment(node)
	local srow, _, erow, _ = node:range()
	local lines = vim.api.nvim_buf_get_lines(0, srow, erow + 1, false)
	for offset, line in ipairs(lines) do
		if line:find("%f[%w_]TODO%f[%W_]") then
			mark(srow + offset - 1)
		end
	end
end

local function visit(node)
	if node:type():find("comment") then
		scan_comment(node)
	end
	for child in node:iter_children() do
		visit(child)
	end
end

function M.refresh()
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

	local ok, parser = pcall(vim.treesitter.get_parser, 0)
	if not ok or not parser then
		return
	end

	local root = parser:parse()[1]:root()
	visit(root)
end

return M
