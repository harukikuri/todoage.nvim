local ns = vim.api.nvim_create_namespace("todoage")

local M = {}

local function parse_blame(output)
	local result = {}
	local current_lnum = nil
	local current_time = nil
	for line in output:gmatch("[^\n]+") do
		local sha, final = line:match("^(%x+) %d+ (%d+)")
		if sha and #sha == 40 then
			current_lnum = tonumber(final)
		else
			local time = line:match("^author%-time (%d+)")
			if time then
				current_time = tonumber(time)
			elseif line:sub(1, 1) == "\t" and current_lnum and current_time then
				result[current_lnum] = current_time
				current_lnum = nil
				current_time = nil
			end
		end
	end
	return result
end

local function render(bufnr, blame_map, now)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		return
	end

	local function scan_comment(node)
		local srow, _, erow, _ = node:range()
		local lines = vim.api.nvim_buf_get_lines(bufnr, srow, erow + 1, false)
		for offset, line in ipairs(lines) do
			if line:find("%f[%w_]TODO%f[%W_]") then
				local lnum = srow + offset - 1
				local commit_time = blame_map[lnum + 1]
				if commit_time then
					local age_days = math.floor((now - commit_time) / 86400)
					vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
						virt_text = { { string.format("(%d days)", age_days), "Comment" } },
						virt_text_pos = "eol",
					})
				end
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

	visit(parser:parse()[1]:root())
end

function M.refresh()
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return
	end

	local now = os.time()

	vim.system({
		"git", "-C", vim.fs.dirname(filepath),
		"blame", "--line-porcelain", "--", filepath,
	}, { text = true }, function(obj)
		if obj.code ~= 0 then
			return
		end
		local blame_map = parse_blame(obj.stdout)
		vim.schedule(function()
			render(bufnr, blame_map, now)
		end)
	end)
end

return M
