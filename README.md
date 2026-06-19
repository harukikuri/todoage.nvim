# todoage.nvim ⏳

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
| `format`   | Receives `(age_days, info)`, returns the label string. `info` = `{ author, sha, time }` from git blame. A throw or non-string warns once and skips. |

The second `format` argument carries the blame data for the line, so you can show more than just the age:

```lua
format = function(age_days, info)
  return string.format("(%d days, %s)", age_days, info.author)
end
```

## Customizing colors

```lua
vim.api.nvim_set_hl(0, "TodoageAge",         { fg = "#d7af5f" })
vim.api.nvim_set_hl(0, "TodoageUncommitted", { fg = "#5f5f5f", italic = true })
```

## Coexistence with other TODO plugins

Designed to complement `todo-comments.nvim` and similar plugins.

## Star history

<a href="https://star-history.com/#harukikuri/todoage.nvim&Date">
  <img src="https://api.star-history.com/svg?repos=harukikuri/todoage.nvim&type=Date" alt="Star History Chart" width="700">
</a>
