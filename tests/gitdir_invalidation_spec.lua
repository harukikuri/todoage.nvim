local todoage = require("todoage")
local resolve_gitdir = todoage._test.resolve_gitdir

describe("resolve_gitdir", function()
	it("does not cache a negative result, so a later git init is picked up", function()
		local dir = vim.fn.tempname()
		vim.fn.mkdir(dir, "p")

		-- Not a repo yet: must return nil (and must not cache that verdict).
		assert.is_nil(resolve_gitdir(dir))

		vim.fn.system({ "git", "-C", dir, "init" })
		assert.are.equal(0, vim.v.shell_error)

		-- The directory is now a repo; the next resolve must reflect that.
		assert.is_truthy(resolve_gitdir(dir))

		vim.fn.delete(dir, "rf")
	end)
end)
