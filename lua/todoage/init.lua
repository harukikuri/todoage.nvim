local ns = vim.api.nvim_create_namespace("todoage")

vim.api.nvim_set_hl(0, "TodoageAge", { link = "Comment", default = true })
vim.api.nvim_set_hl(0, "TodoageUncommitted", { link = "Comment", default = true })

local config = {
	keywords = { "TODO", "FIXME", "HACK" },
	format = function(age_days)
		return string.format("(%d days)", age_days)
	end,
}

local patterns = {}

local function rebuild_patterns()
	local new_patterns = {}
	for _, kw in ipairs(config.keywords) do
		if type(kw) ~= "string" or not kw:match("^[%w_]+$") then
			error(
				string.format(
					"todoage: invalid keyword %q — keywords must contain only letters, digits, and underscores",
					tostring(kw)
				)
			)
		end
		table.insert(new_patterns, "%f[%w_]" .. kw .. "%f[^%w_]")
	end
	patterns = new_patterns
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

local UNCOMMITTED_SHA = string.rep("0", 40)

local function parse_blame(output)
	local result = {}
	local current_lnum = nil
	local current_time = nil
	local current_committed = nil
	for line in output:gmatch("[^\n]+") do
		local sha, final = line:match("^(%x+) %d+ (%d+)")
		if sha and #sha == 40 then
			current_lnum = tonumber(final)
			current_committed = sha ~= UNCOMMITTED_SHA
		else
			local time = line:match("^author%-time (%d+)")
			if time then
				current_time = tonumber(time)
			elseif line:sub(1, 1) == "\t" and current_lnum and current_time then
				if current_committed then
					result[current_lnum] = current_time
				else
					result[current_lnum] = false
				end
				current_lnum = nil
				current_time = nil
				current_committed = nil
			end
		end
	end
	return result
end

-- Comment nodes are named differently across grammars (`comment`,
-- `line_comment`, `block_comment`). Build a query from whichever names the
-- language actually defines so we can jump straight to comment nodes instead
-- of walking every node in the tree. Cached per language; `false` means the
-- grammar has no comment-like node and we fall back to a full walk.
local comment_queries = {}

local function comment_query(lang)
	local cached = comment_queries[lang]
	if cached ~= nil then
		return cached or nil
	end
	local parts = {}
	for _, name in ipairs({ "comment", "line_comment", "block_comment" }) do
		local pattern = "(" .. name .. ") @c"
		if pcall(vim.treesitter.query.parse, lang, pattern) then
			parts[#parts + 1] = pattern
		end
	end
	local query = #parts > 0 and vim.treesitter.query.parse(lang, table.concat(parts, " ")) or false
	comment_queries[lang] = query
	return query or nil
end

local function render(bufnr, blame_map, now)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	if vim.bo[bufnr].modified then
		return
	end

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
				local entry = blame_map[lnum + 1]
				if entry == false then
					vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
						virt_text = { { "(uncommitted)", "TodoageUncommitted" } },
						virt_text_pos = "eol",
					})
				elseif entry then
					local age_days = math.floor((now - entry) / 86400)
					vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
						virt_text = { { config.format(age_days), "TodoageAge" } },
						virt_text_pos = "eol",
					})
				end
			end
		end
	end

	local root = parser:parse()[1]:root()
	local query = comment_query(parser:lang())

	if query then
		for _, node in query:iter_captures(root, bufnr, 0, -1) do
			scan_comment(node)
		end
	else
		local function visit(node)
			if node:type():find("comment") then
				scan_comment(node)
			end
			for child in node:iter_children() do
				visit(child)
			end
		end
		visit(root)
	end
end

local enabled = true

-- Git-blame output for a file changes only when the file on disk changes or
-- git state moves (commit, checkout, rebase, stage). We cache the parsed blame
-- keyed by a cheap fingerprint of both, so repeated refreshes (notably the
-- FocusGained spam) re-render from cache instead of spawning git every time.
local blame_cache = {}
local gitdir_cache = {}

-- vim.system raises synchronously when the program is not on PATH, so a machine
-- without git would otherwise throw on every buffer event. Probe once and
-- memoize; nil means "not yet probed".
local git_available

local function has_git()
	if git_available == nil then
		git_available = vim.fn.executable("git") == 1
	end
	return git_available
end

-- Resolve the git directory for `start_dir`, handling worktrees/submodules
-- where `.git` is a file containing `gitdir: <path>`. Returns the git dir, or
-- nil when not inside a repository.
local function locate_gitdir(start_dir)
	local found = vim.fs.find(".git", { upward = true, path = start_dir, limit = 1 })[1]
	if not found then
		return nil
	end
	local st = vim.uv.fs_stat(found)
	if not st then
		return nil
	end
	if st.type == "directory" then
		return found
	end
	if st.type == "file" then
		local fd = io.open(found, "r")
		if not fd then
			return nil
		end
		local first = fd:read("*l")
		fd:close()
		local target = first and first:match("^gitdir:%s*(.+)%s*$")
		if not target then
			return nil
		end
		if not target:match("^/") then
			target = vim.fs.dirname(found) .. "/" .. target
		end
		return vim.fs.normalize(target)
	end
	return nil
end

local function resolve_gitdir(dir)
	local cached = gitdir_cache[dir]
	if cached ~= nil then
		return cached or nil
	end
	local gitdir = locate_gitdir(dir) or false
	gitdir_cache[dir] = gitdir
	return gitdir or nil
end

-- A string that changes whenever blame output could differ: the file's
-- mtime/size plus the mtime of the git dir's HEAD and index. Returns nil if
-- the file no longer exists. stat'ing a handful of paths is microseconds,
-- versus spawning git and walking history.
local function fingerprint(filepath, gitdir)
	local st = vim.uv.fs_stat(filepath)
	if not st then
		return nil
	end
	local parts = { st.mtime.sec, st.mtime.nsec, st.size }
	if gitdir then
		for _, name in ipairs({ "HEAD", "index" }) do
			local gst = vim.uv.fs_stat(gitdir .. "/" .. name)
			if gst then
				parts[#parts + 1] = name
				parts[#parts + 1] = gst.mtime.sec
				parts[#parts + 1] = gst.mtime.nsec
			end
		end
	end
	return table.concat(parts, ":")
end

function M.refresh(bufnr)
	if not enabled then
		return
	end
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return
	end

	local now = os.time()
	local dir = vim.fs.dirname(filepath)
	local gitdir = resolve_gitdir(dir)

	-- Outside a git repo there is nothing to blame; skip the spawn entirely.
	-- This is the common case for scratch buffers and untracked trees, and it
	-- also avoids the has_git() error path below for non-repo files.
	if not gitdir then
		return
	end

	-- vim.system raises synchronously if git is missing, which would turn every
	-- buffer event into an error on a machine without git.
	if not has_git() then
		return
	end

	local fp = fingerprint(filepath, gitdir)

	local cached = blame_cache[filepath]
	if cached and fp and cached.fp == fp then
		render(bufnr, cached.map, now)
		return
	end

	vim.system({
		"git",
		"-C",
		dir,
		"blame",
		"--line-porcelain",
		"--",
		filepath,
	}, { text = true }, function(obj)
		if obj.code ~= 0 then
			return
		end
		local blame_map = parse_blame(obj.stdout)
		blame_cache[filepath] = { fp = fp, map = blame_map }
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
	timers[bufnr]:start(
		150,
		0,
		vim.schedule_wrap(function()
			if timers[bufnr] then
				timers[bufnr]:close()
				timers[bufnr] = nil
			end
			M.refresh(bufnr)
		end)
	)
end

local function loaded_buffers()
	local bufs = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			bufs[#bufs + 1] = bufnr
		end
	end
	return bufs
end

function M.disable()
	enabled = false

	for bufnr, timer in pairs(timers) do
		timer:stop()
		timer:close()
		timers[bufnr] = nil
	end

	for _, bufnr in ipairs(loaded_buffers()) do
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
end

function M.enable()
	enabled = true

	for _, bufnr in ipairs(loaded_buffers()) do
		M.refresh(bufnr)
	end
end

function M.toggle()
	if enabled then
		M.disable()
	else
		M.enable()
	end
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	rebuild_patterns()

	local group = vim.api.nvim_create_augroup("todoage", { clear = true })

	-- BufEnter catches git state that changed while the buffer sat in the
	-- background (commit, checkout, rebase): the persisted extmarks would
	-- otherwise stay stale until the next save or focus. The blame cache keeps
	-- a switch into an unchanged buffer cheap (a stat, no git spawn).
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "BufEnter" }, {
		group = group,
		callback = function(args)
			debounced_refresh(args.buf)
		end,
	})

	-- Refresh every loaded buffer, not just the current one: git state may
	-- have changed for any of them while Neovim was in the background. The
	-- blame cache makes unchanged buffers cheap (a stat, no git spawn).
	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		callback = function()
			for _, bufnr in ipairs(loaded_buffers()) do
				debounced_refresh(bufnr)
			end
		end,
	})
end

M._test = {
	parse_blame = parse_blame,
	line_matches = line_matches,
	rebuild_patterns = rebuild_patterns,
	fingerprint = fingerprint,
	locate_gitdir = locate_gitdir,
	set_git_available = function(v)
		git_available = v
	end,
}

return M
