local todoage = require("todoage")

describe("FocusGained", function()
	local real_refresh = todoage.refresh

	after_each(function()
		todoage.refresh = real_refresh
	end)

	it("refreshes every loaded buffer, not just the current one", function()
		local refreshed = {}
		todoage.refresh = function(bufnr)
			refreshed[bufnr] = true
		end

		todoage.setup() -- registers the FocusGained autocmd

		local a = vim.api.nvim_create_buf(true, false)
		local b = vim.api.nvim_create_buf(true, false)
		assert.is_true(vim.api.nvim_buf_is_loaded(a))
		assert.is_true(vim.api.nvim_buf_is_loaded(b))

		vim.api.nvim_exec_autocmds("FocusGained", {})

		-- debounced_refresh fires on a 150ms timer; pump the loop until both land
		vim.wait(1000, function()
			return refreshed[a] and refreshed[b]
		end, 10)

		assert.is_true(refreshed[a])
		assert.is_true(refreshed[b])

		vim.api.nvim_buf_delete(a, { force = true })
		vim.api.nvim_buf_delete(b, { force = true })
	end)
end)
