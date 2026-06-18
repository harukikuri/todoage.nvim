local parse_blame = require("todoage")._test.parse_blame

local function block(sha, lnum, author_time)
	return table.concat({
		string.format("%s %d %d", sha, lnum, lnum),
		"author Alice",
		string.format("author-time %d", author_time),
		"author-tz +0000",
		"committer Alice",
		string.format("committer-time %d", author_time),
		"committer-tz +0000",
		"summary test",
		"filename foo.txt",
		"\tline content",
	}, "\n")
end

local SHA_A = string.rep("a", 40)
local SHA_B = string.rep("b", 40)
local SHA_ZERO = string.rep("0", 40)

describe("parse_blame", function()
	it("returns an empty table for empty input", function()
		assert.are.same({}, parse_blame(""))
	end)

	it("parses a single committed line with time, author, and sha", function()
		local result = parse_blame(block(SHA_A, 1, 1700000000))
		assert.are.same({
			[1] = { time = 1700000000, author = "Alice", sha = SHA_A },
		}, result)
	end)

	it("parses multiple committed lines from different commits", function()
		local input = block(SHA_A, 1, 1700000000) .. "\n" .. block(SHA_B, 2, 1700100000)
		local result = parse_blame(input)
		assert.are.same({
			[1] = { time = 1700000000, author = "Alice", sha = SHA_A },
			[2] = { time = 1700100000, author = "Alice", sha = SHA_B },
		}, result)
	end)

	it("records uncommitted lines as false", function()
		local result = parse_blame(block(SHA_ZERO, 1, 1700000000))
		assert.are.same({ [1] = false }, result)
	end)

	it("handles a mix of committed and uncommitted lines", function()
		local input = block(SHA_A, 1, 1700000000) .. "\n" .. block(SHA_ZERO, 2, 1700100000)
		local result = parse_blame(input)
		assert.are.same({
			[1] = { time = 1700000000, author = "Alice", sha = SHA_A },
			[2] = false,
		}, result)
	end)
end)
