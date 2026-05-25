# todoage.nvim ⏳

Neovim plugin that displays the age of TODO comments as inline virtual text.

![demo](assets/demo.png)

## Requirements

- Neovim 0.10+ (for `vim.system`)
- `git` on `PATH`
- A tree-sitter parser installed for the languages you want annotated (`:TSInstall <lang>`)

## Installation

```lua
{
  "kuri-sun/todoage.nvim",
}
```

## Usage

- `:Todoage` - refresh the current buffer
- `:TodoageEnable` - resume auto-refresh and re-annotate the current buffer
- `:TodoageDisable` - clear all annotations and pause auto-refresh
- `:TodoageToggle` - enable/disable

## Configuration

```lua
opts = {
  -- keywords = { "TODO", "FIXME", "HACK" },
  -- tiers = {
  --   aging  = 7,
  --   stale  = 30,
  --   fossil = 180,
  -- },
  -- format = function(age_days)
  --   return string.format("(%d days)", age_days)
  -- end,
}
```

`keywords` replaces the default list wholesale, not merges. If you want the defaults plus extras, list them all. Each keyword must contain only letters, digits, and underscores — `setup()` raises an error otherwise. `tiers` is merged key-by-key, so you can override just one threshold.

Each `tiers` value is the day count at which the next tier begins. `aging = 14` reads as "Fresh tops out at 14 days; day 14 and beyond is Aging."

`format` receives the age in days and must return a string. It controls only the text; the tier highlight color is applied separately. Errors in your `format` function are not caught — fix the function if annotations stop appearing.

## Age tiers

| Tier        | Range          | Default highlight |
| ----------- | -------------- | ----------------- |
| Fresh       | < 7 days       | `Comment`         |
| Aging       | < 30 days      | `Comment`         |
| Stale       | < 180 days     | `Comment`         |
| Fossil      | ≥ 180 days     | `Comment`         |
| Uncommitted | not yet in git | `Comment`         |

By default every tier renders muted — the age number itself carries the signal. Override `TodoageStale`, `TodoageFossil`, etc. to make older comments visually louder. See [Customizing colors](#customizing-colors).

## Customizing colors

Colors are not exposed through `setup({})` — set the highlight groups directly. This way colorschemes can ship `Todoage*` definitions that just work.

```lua
vim.api.nvim_set_hl(0, "TodoageFresh",       { fg = "#888888" })
vim.api.nvim_set_hl(0, "TodoageAging",       { fg = "#d7af5f" })
vim.api.nvim_set_hl(0, "TodoageStale",       { fg = "#d75f5f", bold = true })
vim.api.nvim_set_hl(0, "TodoageFossil",      { fg = "#ff0000", bold = true, underline = true })
vim.api.nvim_set_hl(0, "TodoageUncommitted", { fg = "#5f5f5f", italic = true })
```

`:colorscheme` wipes all highlight groups. To have overrides survive theme switches, wrap them in a `ColorScheme` autocmd:

```lua
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "TodoageFossil", { fg = "#ff0000", bold = true })
    -- ...other overrides
  end,
})
```

## Coexistence with other TODO plugins

Designed to complement `todo-comments.nvim` and similar plugins. `todoage.nvim` only adds end-of-line age annotations — it does not highlight the keyword itself, provide a quickfix list, or affect search.

## License

MIT
