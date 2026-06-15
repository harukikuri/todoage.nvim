local todoage = require("todoage")

local function repo_root()
	return vim.fn.fnamemodify(vim.trim(vim.fn.system("git rev-parse --show-toplevel")), ":p"):gsub("/$", "")
end

local function named_buf(path)
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(bufnr, path)
	return bufnr
end

describe("git guards", function()
	local real_system = vim.system

	after_each(function()
		vim.system = real_system
		todoage._test.set_git_available(nil)
	end)

	it("skips git blame for files outside a repository", function()
		local spawned = false
		vim.system = function(...)
			spawned = true
			return real_system(...)
		end

		local path = vim.fn.tempname()
		local f = io.open(path, "w")
		f:write("// TODO: handle refunds\n")
		f:close()
		local bufnr = named_buf(path)

		assert.has_no.errors(function()
			todoage.refresh(bufnr)
		end)
		assert.is_false(spawned)

		os.remove(path)
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("does not spawn git or error when git is unavailable", function()
		todoage._test.set_git_available(false)
		local spawned = false
		vim.system = function(...)
			spawned = true
			return real_system(...)
		end

		-- A file inside this repo: gitdir resolves, but git is reported missing.
		local bufnr = named_buf(repo_root() .. "/README.md")

		assert.has_no.errors(function()
			todoage.refresh(bufnr)
		end)
		assert.is_false(spawned)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)
