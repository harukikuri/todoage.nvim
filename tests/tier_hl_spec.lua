local tier_hl = require("todoage")._test.tier_hl

describe("tier_hl", function()
	describe("with default thresholds (aging=7, stale=30, fossil=180)", function()
		it("returns TodoageFresh for ages below the aging threshold", function()
			assert.are.equal("TodoageFresh", tier_hl(0))
			assert.are.equal("TodoageFresh", tier_hl(6))
		end)

		it("returns TodoageAging at the aging threshold", function()
			assert.are.equal("TodoageAging", tier_hl(7))
		end)

		it("returns TodoageAging for ages between aging and stale", function()
			assert.are.equal("TodoageAging", tier_hl(29))
		end)

		it("returns TodoageStale at the stale threshold", function()
			assert.are.equal("TodoageStale", tier_hl(30))
		end)

		it("returns TodoageStale for ages between stale and fossil", function()
			assert.are.equal("TodoageStale", tier_hl(179))
		end)

		it("returns TodoageFossil at the fossil threshold", function()
			assert.are.equal("TodoageFossil", tier_hl(180))
		end)

		it("returns TodoageFossil for very old ages", function()
			assert.are.equal("TodoageFossil", tier_hl(10000))
		end)
	end)
end)
