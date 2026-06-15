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

| Option     | Notes                                                                  |
| ---------- | ---------------------------------------------------------------------- |
| `keywords` | Replaces defaults wholesale; list everything you want. Letters, digits, and underscores only. |
| `format`   | Gets age in days, returns the label string. A throw or non-string warns once and skips. |

## Customizing colors

Two groups, both linked to `Comment` by default: `TodoageAge` (committed) and `TodoageUncommitted` (not yet in git). There's no `setup({})` color option — set them directly:

```lua
vim.api.nvim_set_hl(0, "TodoageAge",         { fg = "#d7af5f" })
vim.api.nvim_set_hl(0, "TodoageUncommitted", { fg = "#5f5f5f", italic = true })
```

## Coexistence with other TODO plugins

Designed to complement `todo-comments.nvim` and similar plugins.

## License

MIT
