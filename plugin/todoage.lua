vim.api.nvim_create_user_command("Todoage", function()
	require("todoage").refresh()
end, {})

vim.api.nvim_create_user_command("TodoageToggle", function()
	require("todoage").toggle()
end, {})

require("todoage").setup()
