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

## Documentation

`doc/todoage.txt` is **generated from `README.md`** by [panvimdoc](https://github.com/kdheepak/panvimdoc) — edit the README, never the help file by hand. When a pull request changes `README.md`, the `panvimdoc` workflow regenerates the vimdoc and commits it back onto the PR branch, so the two can't drift.

Markdown conventions for good vimdoc output:

- Keep the README conventional: a single `#` title, `##` sections, `###` subsections. The workflow passes `shiftheadinglevelby: -1`, which makes the `#` title the doc title and lifts `##` sections to top level, so they get clean `*todoage-<section>*` tags.
- Wrap README-only content (demo image, star-history chart) in `<!-- panvimdoc-ignore-start -->` / `<!-- panvimdoc-ignore-end -->`, with blank lines around the markers.

To preview the generated doc locally (optional — CI does this for you), you need `pandoc`, then:

```sh
git clone https://github.com/kdheepak/panvimdoc /tmp/panvimdoc
/tmp/panvimdoc/panvimdoc.sh \
  --project-name todoage --input-file README.md \
  --vim-version "Neovim >= 0.10" --toc true \
  --description "Display TODO comment age as inline virtual text" \
  --demojify true --treesitter true --dedup-subheadings true \
  --shift-heading-level-by -1
```

## Project layout

| Path | Purpose |
| --- | --- |
| `plugin/` | Command definitions and `setup()` bootstrap, loaded by Neovim on startup |
| `lua/todoage/init.lua` | Core logic: blame parsing, comment scanning, rendering |
| `lua/todoage/health.lua` | `:checkhealth todoage` diagnostics |
| `tests/` | plenary specs and the minimal init used to run them |
| `doc/todoage.txt` | `:help todoage` manual — **generated from `README.md`**, do not edit by hand |

## Commit messages

Use clear, conventional-style prefixes (`fix:`, `feat:`, `perf:`, `docs:`, `chore:`, `refactor:`, `style:`, `ci:`). Keep the subject in the imperative mood and explain the *why* in the body when it isn't obvious.

## Reporting bugs and requesting features

Please use the [issue templates](https://github.com/harukikuri/todoage.nvim/issues/new/choose). For usage questions and general help, open a [discussion](https://github.com/harukikuri/todoage.nvim/discussions) instead. The `:checkhealth todoage` output is the fastest way to diagnose a setup problem — include it with bug reports.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE) that covers this project.
