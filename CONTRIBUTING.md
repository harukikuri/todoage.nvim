# Contributing to todoage.nvim

Thanks for your interest in improving todoage.nvim! Bug reports, fixes, docs, and focused features are all welcome.

## Scope

todoage.nvim is intentionally small: it adds end-of-line age annotations to TODO-style comments and nothing else. It deliberately does **not** highlight keywords, build a quickfix list, or affect search — that keeps it composable with plugins like `todo-comments.nvim`. Features that preserve this focus (or that compose with other plugins rather than absorbing them) are the easiest to accept. If you're unsure whether an idea fits, open a [discussion](https://github.com/harukikuri/todoage.nvim/discussions) before writing code.

## Prerequisites

- **Neovim 0.10+** (the plugin uses `vim.system`)
- **git** on your `PATH`
- **[StyLua](https://github.com/JohnnyMorganz/StyLua)** for formatting
- A tree-sitter parser for any language you test against (`:TSInstall <lang>`)

Test dependencies (plenary.nvim) are fetched automatically the first time you run the tests.

## Development workflow

1. Fork and clone the repository.
2. Create a topic branch: `git switch -c fix/short-description`.
3. Make your change, with tests and formatting (see below).
4. Push and open a pull request against `main`.

`main` is protected — all changes land through a pull request, and CI must be green before merge.

## Running tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) and live in `tests/`. The Makefile clones plenary into `.tests/` on first run:

```sh
make test
```

CI runs the suite on both `stable` and `nightly` Neovim, so please make sure tests pass locally before pushing.

When adding behavior, add or extend a spec under `tests/`. Pure helpers are exported through the `M._test` table in `lua/todoage/init.lua` specifically so they can be unit-tested without a running editor — `parse_blame`, `line_matches`, and `rebuild_patterns` are tested this way.

## Formatting

Formatting is enforced by StyLua in CI (config in `.stylua.toml`: tabs, 120-column width, double quotes). Format before committing:

```sh
make fmt        # format in place
make fmt-check  # verify formatting (what CI runs)
```

## Project layout

| Path | Purpose |
| --- | --- |
| `plugin/` | Command definitions and `setup()` bootstrap, loaded by Neovim on startup |
| `lua/todoage/init.lua` | Core logic: blame parsing, comment scanning, rendering |
| `lua/todoage/health.lua` | `:checkhealth todoage` diagnostics |
| `tests/` | plenary specs and the minimal init used to run them |
| `doc/` | `:help todoage` manual |

## Commit messages

Use clear, conventional-style prefixes (`fix:`, `feat:`, `perf:`, `docs:`, `chore:`, `refactor:`, `style:`, `ci:`). Keep the subject in the imperative mood and explain the *why* in the body when it isn't obvious.

## Reporting bugs and requesting features

Please use the [issue templates](https://github.com/harukikuri/todoage.nvim/issues/new/choose). For usage questions and general help, open a [discussion](https://github.com/harukikuri/todoage.nvim/discussions) instead. The `:checkhealth todoage` output is the fastest way to diagnose a setup problem — include it with bug reports.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE) that covers this project.
