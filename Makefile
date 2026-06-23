.PHONY: test fmt fmt-check lint

PLENARY_DIR := .tests/site/pack/deps/start/plenary.nvim

test: $(PLENARY_DIR)
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }" \
		-c "qa!"

$(PLENARY_DIR):
	git clone --depth=1 https://github.com/nvim-lua/plenary.nvim.git $@

fmt:
	stylua lua/ tests/ plugin/

fmt-check:
	stylua --check lua/ tests/ plugin/

lint:
	selene lua/ tests/ plugin/
