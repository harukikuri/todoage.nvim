local todoage = require("todoage")

describe("BufEnter", function()
	local real_refresh = todoage.refresh

	after_each(function()
		todoage.refresh = real_refresh
	end)

	it("refreshes the entered buffer", function()
		local refreshed = {}
		todoage.refresh = function(bufnr)
			refreshed[bufnr] = true
		end

		todoage.setup() -- registers the BufEnter autocmd

		local b = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_exec_autocmds("BufEnter", { buffer = b })

		-- debounced_refresh fires on a 150ms timer; pump the loop until it lands
		vim.wait(1000, function()
			return refreshed[b]
		end, 10)

		assert.is_true(refreshed[b])

		vim.api.nvim_buf_delete(b, { force = true })
	end)
end)
