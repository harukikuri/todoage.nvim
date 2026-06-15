local todoage = require("todoage")

describe("buffer cleanup", function()
	before_each(function()
		-- Register the BufDelete/BufWipeout autocmd.
		todoage.setup()
	end)

	it("drops the blame cache entry when a buffer is wiped", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, vim.fn.tempname())

		-- Key the cache the same way refresh() and cleanup_buffer() do.
		local name = vim.api.nvim_buf_get_name(bufnr)
		assert.are_not.equal("", name)
		todoage._test.blame_cache[name] = { fp = "x", map = {} }

		vim.api.nvim_buf_delete(bufnr, { force = true })

		assert.is_nil(todoage._test.blame_cache[name])
	end)

	it("stops and drops the debounce timer when a buffer is wiped", function()
		local bufnr = vim.api.nvim_create_buf(false, true)

		local timer = vim.uv.new_timer()
		todoage._test.timers[bufnr] = timer

		vim.api.nvim_buf_delete(bufnr, { force = true })

		assert.is_nil(todoage._test.timers[bufnr])
		assert.is_true(timer:is_closing())
	end)
end)
