local todoage = require("todoage")
local render = todoage._test.render

-- Build a loaded lua buffer (the lua tree-sitter parser ships with Neovim, so
-- render's comment scan works without installing anything) and clear the
-- modified flag so render doesn't bail early.
local function lua_buf(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "lua"
	vim.bo[buf].modified = false
	return buf
end

local SHA = string.rep("a", 40)

describe("M.get", function()
	it("returns the markers found in the buffer, in line order", function()
		local buf = lua_buf({
			"-- TODO: refactor this", -- line 1, committed
			"local x = 1",
			"-- FIXME: broken", -- line 3, uncommitted
		})
		local now = 1000000
		render(buf, {
			[1] = { time = now - 86400 * 10, author = "Alice", sha = SHA },
			[3] = false,
		}, now)

		local todos = todoage.get(buf)
		assert.are.equal(2, #todos)
		assert.are.same({ lnum = 1, keyword = "TODO", age_days = 10, author = "Alice", sha = SHA }, todos[1])
		-- Uncommitted lines appear with nil blame fields so they can still be listed.
		assert.are.same({ lnum = 3, keyword = "FIXME" }, todos[2])

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("returns an empty table for a buffer that never rendered", function()
		local buf = vim.api.nvim_create_buf(false, true)
		assert.are.same({}, todoage.get(buf))
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("returns a copy that callers cannot use to corrupt internal state", function()
		local buf = lua_buf({ "-- TODO: one" })
		local now = 1000000
		render(buf, { [1] = { time = now, author = "Bob", sha = SHA } }, now)

		local first = todoage.get(buf)
		first[1].keyword = "MUTATED"
		first[2] = { lnum = 99 }

		local second = todoage.get(buf)
		assert.are.equal(1, #second)
		assert.are.equal("TODO", second[1].keyword)

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)

describe("User TodoageRefreshed", function()
	after_each(function()
		vim.api.nvim_clear_autocmds({ event = "User", pattern = "TodoageRefreshed" })
	end)

	it("fires after a render with the bufnr in the event data", function()
		local seen = {}
		vim.api.nvim_create_autocmd("User", {
			pattern = "TodoageRefreshed",
			callback = function(args)
				seen[#seen + 1] = args.data and args.data.bufnr
			end,
		})

		local buf = lua_buf({ "-- TODO: ping" })
		render(buf, { [1] = false }, os.time())

		assert.is_true(vim.tbl_contains(seen, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)
