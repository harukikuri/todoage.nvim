local todoage = require("todoage")
local fingerprint = todoage._test.fingerprint
local locate_gitdir = todoage._test.locate_gitdir

local function repo_root()
	return vim.fn.fnamemodify(vim.trim(vim.fn.system("git rev-parse --show-toplevel")), ":p"):gsub("/$", "")
end

describe("locate_gitdir", function()
	it("finds the git dir for a path inside the repo", function()
		local gitdir = locate_gitdir(repo_root())
		assert.is_truthy(gitdir)
		assert.is_truthy(gitdir:find("%.git"))
	end)

	it("returns nil outside any repository", function()
		assert.is_nil(locate_gitdir("/"))
	end)
end)

describe("fingerprint", function()
	it("returns nil for a file that does not exist", function()
		assert.is_nil(fingerprint("/no/such/path/todoage-does-not-exist", nil))
	end)

	it("changes when the file contents change", function()
		local path = vim.fn.tempname()
		local f = io.open(path, "w")
		f:write("one\n")
		f:close()
		local before = fingerprint(path, nil)
		assert.is_truthy(before)

		-- Rewrite with a different size so the fingerprint differs regardless
		-- of mtime resolution.
		f = io.open(path, "w")
		f:write("one\ntwo\nthree\n")
		f:close()
		local after = fingerprint(path, nil)

		assert.are_not.equal(before, after)
		os.remove(path)
	end)

	it("incorporates git state when a git dir is supplied", function()
		local root = repo_root()
		local gitdir = locate_gitdir(root)
		local somefile = root .. "/README.md"
		assert.are_not.equal(fingerprint(somefile, nil), fingerprint(somefile, gitdir))
	end)
end)
