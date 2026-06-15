local todoage = require("todoage")
local line_matches = todoage._test.line_matches

describe("keyword replacement", function()
	after_each(function()
		-- Restore defaults so later specs see the documented keyword set.
		todoage.setup({ keywords = { "TODO", "FIXME", "HACK" } })
	end)

	it("replaces the default keywords wholesale rather than merging", function()
		todoage.setup({ keywords = { "NOTE" } })

		assert.is_true(line_matches("// NOTE: revisit this"))

		-- The defaults must be gone, not merged in alongside NOTE.
		assert.is_false(line_matches("// TODO: revisit this"))
		assert.is_false(line_matches("// FIXME: revisit this"))
		assert.is_false(line_matches("// HACK: revisit this"))
	end)
end)
