# todoage.nvim ⏳

[![GitHub release](https://img.shields.io/github/v/release/harukikuri/todoage.nvim)](https://github.com/harukikuri/todoage.nvim/releases/latest)

Neovim plugin that displays the age of TODO comments as inline virtual text.

![demo](assets/demo.png)

## Requirements

- Git
- A tree-sitter parser installed for the languages you want annotated (`:TSInstall <lang>`)

## Installation

```lua
{
  "harukikuri/todoage.nvim",
}
```

## Usage

- `:Todoage` - refresh the current buffer
- `:TodoageToggle` - toggle annotations and auto-refresh on/off

## Configuration

```lua
opts = {
  -- keywords = { "TODO", "FIXME", "HACK" },
  -- format = function(age_days)
  --   return string.format("(%d days)", age_days)
  -- end,
}
```

`keywords` replaces the default list wholesale, not merges. If you want the defaults plus extras, list them all. Each keyword must contain only letters, digits, and underscores — `setup()` raises an error otherwise.

`format` receives the age in days and must return a string. It controls only the text; the highlight color is applied separately. Errors in your `format` function are not caught — fix the function if annotations stop appearing.

## Customizing colors

Two highlight groups, both linked to `Comment` by default:

| Group                | Applies to               | Default highlight |
| -------------------- | ------------------------ | ----------------- |
| `TodoageAge`         | committed age annotation | `Comment`         |
| `TodoageUncommitted` | not yet in git           | `Comment`         |

By default annotations render muted — the age number itself carries the signal. Colors are not exposed through `setup({})`; set the highlight groups directly so colorschemes can ship `Todoage*` definitions that just work.

```lua
vim.api.nvim_set_hl(0, "TodoageAge",         { fg = "#d7af5f" })
vim.api.nvim_set_hl(0, "TodoageUncommitted", { fg = "#5f5f5f", italic = true })
```

`:colorscheme` wipes all highlight groups. To have overrides survive theme switches, wrap them in a `ColorScheme` autocmd:

```lua
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "TodoageAge", { fg = "#d7af5f", bold = true })
    -- ...other overrides
  end,
})
```

## Coexistence with other TODO plugins

Designed to complement `todo-comments.nvim` and similar plugins. `todoage.nvim` only adds end-of-line age annotations — it does not highlight the keyword itself, provide a quickfix list, or affect search.

## License

MIT
