local todoage = require("todoage")
local safe_format = todoage._test.safe_format

describe("safe_format", function()
	local real_notify = vim.notify

	after_each(function()
		vim.notify = real_notify
		-- Restore a sane default and re-arm the warning for the next test.
		todoage.setup({
			format = function(age_days)
				return string.format("(%d days)", age_days)
			end,
		})
	end)

	it("returns the string from a valid format function", function()
		todoage.setup({
			format = function(age_days)
				return "age:" .. age_days
			end,
		})
		assert.are.equal("age:3", safe_format(3))
	end)

	it("returns nil and warns once when format errors", function()
		local notified = 0
		vim.notify = function()
			notified = notified + 1
		end
		todoage.setup({
			format = function()
				error("boom")
			end,
		})

		assert.is_nil(safe_format(1))
		assert.is_nil(safe_format(2))
		assert.are.equal(1, notified)
	end)

	it("returns nil when format returns a non-string", function()
		vim.notify = function() end
		todoage.setup({
			format = function()
				return 42
			end,
		})
		assert.is_nil(safe_format(5))
	end)

	it("forwards the info context table to format", function()
		local seen
		todoage.setup({
			format = function(age_days, info)
				seen = info
				return tostring(age_days)
			end,
		})

		safe_format(7, { age_days = 7, author = "Bob", sha = "deadbeef", time = 123 })

		assert.is_table(seen)
		assert.are.equal("Bob", seen.author)
		assert.are.equal("deadbeef", seen.sha)
		assert.are.equal(123, seen.time)
	end)
end)
