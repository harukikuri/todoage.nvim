local ns = vim.api.nvim_create_namespace("todoage")

vim.api.nvim_set_hl(0, "TodoageFresh", { link = "Comment", default = true })
vim.api.nvim_set_hl(0, "TodoageAging", { link = "WarningMsg", default = true })
vim.api.nvim_set_hl(0, "TodoageStale", { link = "WarningMsg", bold = true, default = true })
vim.api.nvim_set_hl(0, "TodoageFossil", { link = "ErrorMsg", bold = true, default = true })

local function tier_hl(age_days)
	if age_days < config.tiers.aging then
		return "TodoageFresh"
	elseif age_days < config.tiers.stale then
		return "TodoageAging"
	elseif age_days < config.tiers.fossil then
		return "TodoageStale"
	else
		return "TodoageFossil"
	end
end

local config = {
	keywords = { "TODO", "FIXME", "HACK" },
	tiers = {
		aging = 7,
		stale = 30,
		fossil = 180,
	},
}

local patterns = {}

local function rebuild_patterns()
	patterns = {}
	for _, kw in ipairs(config.keywords) do
		table.insert(patterns, "%f[%w_]" .. kw .. "%f[%W_]")
	end
end

rebuild_patterns()

local function line_matches(line)
	for _, pat in ipairs(patterns) do
		if line:find(pat) then
			return true
		end
	end
	return false
end

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
			if line_matches(line) then
				local lnum = srow + offset - 1
				local commit_time = blame_map[lnum + 1]
				if commit_time then
					local age_days = math.floor((now - commit_time) / 86400)
					vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
						virt_text = { { string.format("(%d days)", age_days), tier_hl(age_days) } },
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

function M.refresh(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
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

local timers = {}

local function debounced_refresh(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
		timers[bufnr]:close()
	end
	timers[bufnr] = vim.uv.new_timer()
	timers[bufnr]:start(150, 0, vim.schedule_wrap(function()
		if timers[bufnr] then
			timers[bufnr]:close()
			timers[bufnr] = nil
		end
		M.refresh(bufnr)
	end))
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	rebuild_patterns()

	local group = vim.api.nvim_create_augroup("todoage", { clear = true })

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		group = group,
		callback = function(args)
			debounced_refresh(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		callback = function()
			debounced_refresh(vim.api.nvim_get_current_buf())
		end,
	})
end

return M
