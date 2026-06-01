local todoage = require("todoage")

describe("refresh", function()
	it("does not error when given an invalid buffer", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_delete(bufnr, { force = true })
		assert.is_false(vim.api.nvim_buf_is_valid(bufnr))

		assert.has_no.errors(function()
			todoage.refresh(bufnr)
		end)
	end)
end)
