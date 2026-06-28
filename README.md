# todoage.nvim

Neovim plugin that displays the age of TODO comments as inline virtual text.

<!-- panvimdoc-ignore-start -->

![demo](assets/demo.png)

<!-- panvimdoc-ignore-end -->

The age is resolved via `git blame` against the file on disk, so you can see at a
glance how long a comment has been sitting there. A line like:

```text
// TODO: handle refunds
```

renders as (virtual text, not written to disk):

```text
// TODO: handle refunds                              (847 days)
```

# Requirements

- Git
- A tree-sitter parser for the languages you want annotated (`:TSInstall <lang>`).
  Files without a parser are silently skipped.

# Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim) or any plugin manager:

```lua
{
  "harukikuri/todoage.nvim",
}
```

# Commands

- `:Todoage` refreshes annotations on the current buffer.
- `:TodoageToggle` toggles annotations and auto-refresh on or off. When
  disabling, it clears all annotations and pauses auto-refresh; when enabling,
  it re-annotates all loaded buffers.

# Configuration

Pass options through `opts` (lazy.nvim) or `require("todoage").setup({ ... })`.
With no arguments, the defaults apply.

```lua
opts = {
  -- keywords = { "TODO", "FIXME", "HACK" },
  -- format = function(age_days)
  --   return string.format("(%d days)", age_days)
  -- end,
}
```

## keywords

List of strings to recognize as TODO-style markers. Matched as standalone words,
so `myTODOList` and `TODO_KEY` are skipped. Each keyword must contain only
letters, digits, and underscores; `setup()` raises an error otherwise.

Replaces the default list wholesale (it does not merge) — to extend the defaults,
list them all.

Default: `{ "TODO", "FIXME", "HACK" }`

## format

Function taking the age in days and an `info` table, returning the string to
render. The `TodoageAge` highlight is applied to whatever string you return.

`info` carries the git-blame data for the line:

| Field           | Description                                |
| --------------- | ------------------------------------------ |
| `info.age_days` | Age in days (same as the first argument).  |
| `info.author`   | Author name.                               |
| `info.sha`      | Full commit SHA.                           |
| `info.time`     | Author timestamp (epoch seconds).          |

If your format function throws or returns a non-string, todoage warns once (via
`vim.notify`) and skips those annotations rather than erroring. Fix the function
and they reappear.

Example showing the author:

```lua
format = function(age_days, info)
  return string.format("(%d days, %s)", age_days, info.author)
end
```

Default:

```lua
function(age_days)
  return string.format("(%d days)", age_days)
end
```

# Highlights

Two highlight groups, both linked to `Comment` by default:

| Group                | Applies to                          |
| -------------------- | ----------------------------------- |
| `TodoageAge`         | Age of a committed comment.         |
| `TodoageUncommitted` | Lines not yet committed to git.     |

The age number itself carries the signal; override `TodoageAge` to make
annotations visually louder. There is no `colors` setup option.

```lua
vim.api.nvim_set_hl(0, "TodoageAge",         { fg = "#d7af5f" })
vim.api.nvim_set_hl(0, "TodoageUncommitted", { fg = "#5f5f5f", italic = true })
```

# Behavior

Annotations refresh automatically on:

- `BufReadPost` — opening a file.
- `BufWritePost` — saving a file.
- `BufEnter` — entering a buffer (catches git state that changed while it sat in
  the background, e.g. a commit, checkout, or rebase).
- `FocusGained` — re-focusing Neovim (catches an external `git pull`).

Refreshes are debounced ~150ms per buffer.

Modified-but-unsaved buffers skip rendering entirely. Line numbers in the buffer
diverge from line numbers in the on-disk blame, so annotations would be
misleading. They reappear on save.

Files outside a git repository, or not yet tracked, render no annotations.
Uncommitted lines render as `(uncommitted)`.

# API

todoage exposes the markers it finds so other plugins can build on top of it (a
Telescope picker, a lualine "oldest TODO" segment, project-wide listing) without
todoage taking on those features itself.

## get

`require("todoage").get(bufnr)` returns the markers found in `bufnr` (default:
the current buffer) as of its last render, in ascending line order:

```lua
local todos = require("todoage").get()
-- {
--   { lnum = 12, keyword = "TODO", age_days = 847, author = "Ada", sha = "<40-char sha>" },
--   { lnum = 40, keyword = "FIXME" }, -- uncommitted: nil age_days/author/sha
-- }
```

`lnum` is 1-based. Uncommitted lines have nil `age_days`, `author`, and `sha`. A
buffer that has not rendered yet (or while todoage is disabled) returns an empty
table. The result is a fresh copy you may keep or modify.

## TodoageRefreshed

After each render todoage fires a `User` autocommand with pattern
`TodoageRefreshed`, carrying the buffer in the event data, so you can refresh
whatever you built on top of `get()`:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "TodoageRefreshed",
  callback = function(args)
    local todos = require("todoage").get(args.data.bufnr)
    -- update your statusline / picker / sign column
  end,
})
```

# Coexistence

todoage deliberately does only one thing: show comment age. It doesn't highlight
keywords, build a quickfix list, or affect search — so it composes cleanly with
[todo-comments.nvim](https://github.com/folke/todo-comments.nvim) and similar
plugins.

<!-- panvimdoc-ignore-start -->

## Star history

<a href="https://star-history.com/#harukikuri/todoage.nvim&Date">
  <img src="https://api.star-history.com/svg?repos=harukikuri/todoage.nvim&type=Date" alt="Star History Chart" width="700">
</a>

<!-- panvimdoc-ignore-end -->
