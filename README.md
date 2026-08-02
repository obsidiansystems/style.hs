# style.hs

### Obsidian-style Haskell

shared formatter configs · `nix run` anywhere · consistent formatting across projects

![Haskell](https://img.shields.io/badge/Haskell-5e5086?logo=haskell&logoColor=white) [![Built with Nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://nixos.org) [![Obsidian](https://img.shields.io/badge/Obsidian-Systems-white)](https://obsidian.systems) [![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](./LICENSE)

```console
$ nix run github:obsidiansystems/style.hs -- --mode inplace src/   # format your Haskell, Obsidian-style
$ nix run github:obsidiansystems/style.hs -- --mode check   src/   # or just check it, e.g. in CI

$ nix run github:obsidiansystems/style.hs#stylish-haskell -- -i -r src/   # the low-diff alternative
```

A [Nix](https://nixos.org/) flake that wraps two formatters,
[`fourmolu`](https://github.com/fourmolu/fourmolu) and
[`stylish-haskell`](https://github.com/haskell/stylish-haskell), with common configs:
[`fourmolu.yaml`](./fourmolu.yaml) and [`stylish-haskell.yaml`](./stylish-haskell.yaml).
Point any of your Haskell projects at this flake and they all format the same way,
without each repo having to vendor and maintain its own copy of the config. Both configs
implement our [Haskell Style Guide](./STYLE.md).

## Why style.hs?

- **One config, every repo.** Reference the flake and your projects format identically.
- **Drop in however you like.** Run it directly with `nix run`, add it to a dev shell so
  the plain command just works, vendor it as a git submodule, or run the config file
  itself as an executable.

## Which formatter?

They're alternatives, not a pipeline. Pick one per project and stick with it: running
both over the same file means each will undo part of the other's work.

| | [fourmolu](./fourmolu.yaml) | [stylish-haskell](./stylish-haskell.yaml) |
| --- | --- | --- |
| What it rewrites | Everything, expression layout included | Imports, `LANGUAGE` pragmas, the module header, `data`/`newtype` declarations, whitespace |
| Function bodies | Reformatted | Left exactly as written |
| Cost to adopt | A full reformat of the repo | A small, mostly-imports diff |
| Style coverage | All of [STYLE.md](./STYLE.md)'s mechanical rules | The subset in [What stylish-haskell covers](#what-stylish-haskell-covers) |
| Flake output | `fourmolu`, and the `default` | `stylish-haskell` |

fourmolu is the default and the more complete of the two. Reach for stylish-haskell when
a codebase can't absorb an all-at-once reformat, or when you want the formatter to stay
out of the way of hand-tuned expression layout.

## Usage

### Run it directly

```sh
# Format in place, using the bundled Obsidian Systems config.
nix run github:obsidiansystems/style.hs -- --mode inplace src/

# Check formatting without writing (e.g. in CI).
nix run github:obsidiansystems/style.hs -- --mode check src/
```

Everything after `--` is forwarded straight to `fourmolu`, so any flag fourmolu
accepts works here too.

stylish-haskell lives at the `#stylish-haskell` attribute, and takes its own flags
(`-i` to write in place, `-r` to recurse into a directory):

```sh
nix run github:obsidiansystems/style.hs#stylish-haskell -- -i -r src/
```

It has no equivalent of fourmolu's `--mode check`, so to check without writing, format
and let git tell you whether anything moved:

```sh
nix run github:obsidiansystems/style.hs#stylish-haskell -- -i -r src/
git diff --exit-code
```

### Add it to a project

Reference the flake as an input and use the `fourmolu` package as your formatter,
for example in a dev shell:

```nix
{
  inputs.style.url = "github:obsidiansystems/style.hs";

  outputs = { self, nixpkgs, style, ... }:
    let system = "x86_64-linux";
    in {
      devShells.${system}.default =
        nixpkgs.legacyPackages.${system}.mkShell {
          packages = [ style.packages.${system}.fourmolu ];
        };
    };
}
```

Inside that shell, plain `fourmolu` already uses the Obsidian Systems style, with
no `--config` needed. Swap in `style.packages.${system}.stylish-haskell` to get a
`stylish-haskell` that behaves the same way.

### Vendor it as a git submodule

Add this repo as a submodule and symlink your project's config to the vendored one.
Both formatters discover their config from the project root automatically, so editors,
formatters, and CI all pick up the style with no flags:

```sh
git submodule add https://github.com/obsidiansystems/style.hs style.hs

ln -s style.hs/fourmolu.yaml fourmolu.yaml                    # fourmolu
ln -s style.hs/stylish-haskell.yaml .stylish-haskell.yaml     # stylish-haskell
```

Note the leading dot on the stylish-haskell symlink: it searches for
`.stylish-haskell.yaml` in the current directory and its ancestors, then
`$XDG_CONFIG_HOME/stylish-haskell/config.yaml`, then `$HOME/.stylish-haskell.yaml`.

Pull in later changes to the shared style by updating the submodule:

```sh
git submodule update --remote style.hs
```

### Use the config file as an executable

[`fourmolu.yaml`](./fourmolu.yaml) and [`stylish-haskell.yaml`](./stylish-haskell.yaml)
are each both the config *and* a runnable
[Nix shebang](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix.html?highlight=shebang#shebang-interpreter)
script. Copy one into a project and run it directly to format files using itself as
the config:

```sh
./fourmolu.yaml --mode inplace src/
./stylish-haskell.yaml -i -r src/
```

This needs `nix` on `PATH` with flakes enabled.

## Choosing a config

Each wrapper resolves which config to use as follows:

- **No config flag**: the bundled `fourmolu.yaml` / `stylish-haskell.yaml` (the default).
- **`--config <path>`** / **`--config=<path>`**: your own config file. Repeated config
  flags collapse to the last one, since both tools reject duplicates themselves.
- **`--config -`**: read the config from stdin.

The stylish-haskell wrapper additionally accepts that tool's short form, `-c <path>` or
`-c<path>`, including at the end of a bundled cluster such as `-ic <path>`.

## What stylish-haskell covers

stylish-haskell is a fixed pipeline of nine steps, and that set is the hard limit on what
it can do: `imports`, `module_header`, `records`, `language_pragmas`, `simple_align`,
`squash`, `tabs`, `trailing_whitespace`, `unicode_syntax`. Only the first three rewrite
declarations at all. Nothing in the set looks at an expression, a function body, a type
signature, a `where` clause, a `do` block, or the blank lines between declarations.

So these [STYLE.md](./STYLE.md) rules are enforced:

| Rule | How |
| --- | --- |
| Post-qualified imports, `import Data.Text qualified as T` | `imports.post_qualify` |
| Imports sorted within each group | `imports` |
| Leading commas and aligned parens in import and export lists | `imports`, `module_header` |
| Leading commas and aligned braces in `data`/`newtype` declarations | `records` |
| Sorted `deriving` lists | `records.sort_deriving` |
| One `LANGUAGE` pragma per line, sorted, redundant ones dropped | `language_pragmas` |
| No column alignment anywhere the tool could introduce it | `simple_align` (all `never`), `imports.align: none`, `language_pragmas.align: false` |
| Two spaces, never tabs | `tabs` |
| No trailing whitespace | `trailing_whitespace` |
| Unix line endings | `newline: lf` |
| A space before `where` in the export list | `module_header.break_where` |

And these are out of reach. Use fourmolu, or your own discipline, for them:

- Leading `::` and `->` in a broken type signature, and a broken `forall`'s dot.
- Unparenthesized single-constraint contexts: `Show a => a -> a`.
- `where` on its own line, and the two-space step for its body.
- A `do` block's first statement on the line after `do`.
- Operator spacing (`x + y`) and section hugging (`(+ 1)`).
- Leading commas in *expression* lists, records and tuples. Only declarations and
  import/export lists get them here.
- `let`/`in` layout, haddock style, and the space inside record braces.
- "One blank line, never two."
- No newline before the `=` of a function definition.
- Import *grouping*. The Obsidian External/Common/Frontend/Backend/Local ordering isn't
  expressible: stylish-haskell emits groups in rule order with unmatched modules last,
  and has no notion of which modules are local to your package. The config therefore
  leaves your blank-line groups alone and only sorts within them.

## Where the two tools differ

On imports the two agree exactly: sorting, deduplication, post-qualification and list
layout all produce byte-identical output. The same holds for any declaration or export
list already written in the multi-line form, which is the form both tools converge on.

Three differences remain. None of them breaks a STYLE.md rule, but they do mean a file
formatted by one tool is not always stable under the other:

- **`newtype` declarations break before the `=`.** fourmolu keeps them on one line.
  Avoiding this needs `records.equals: same_line`, which then aligns a multi-constructor
  type's `|` under its `=`, and column alignment is the one thing STYLE.md is emphatic
  about avoiding. `break_single_constructors` covers only `data`, so no combination
  avoids both.
- **A sum type written on one line gets expanded**, one constructor per line. fourmolu is
  `respectful` and leaves your line breaks as they are. Enums and nullary constructors
  (`data Colour = C_Red | C_Green`, `data Proxy = Proxy`) stay inline under both.
- **No blank line after the `LANGUAGE` pragma block.** fourmolu inserts one before
  `module`.

One hazard worth knowing: `post_qualify` rewrites `import qualified Data.Text as T` into
the post-qualified form *unconditionally*, even in a module where `ImportQualifiedPost`
isn't enabled, leaving code that needs the extension to parse. fourmolu only rewrites
when the extension is already in scope. The extension is on by default from GHC 9.6; on
anything older, put it in your cabal file's `default-extensions`.

## What's in the repo

| File                                             | Purpose                                                                     |
| ---                                              | ---                                                                         |
| [`STYLE.md`](./STYLE.md)                         | The Obsidian Haskell Style Guide: the reasoning behind the rules.           |
| [`fourmolu.yaml`](./fourmolu.yaml)               | The shared style config for fourmolu: also a runnable Nix shebang script.   |
| [`fourmolu.nix`](./fourmolu.nix)                 | Builds the `fourmolu` wrapper that bundles the config and handles `--config`. |
| [`stylish-haskell.yaml`](./stylish-haskell.yaml) | The same style for stylish-haskell: also a runnable Nix shebang script.     |
| [`stylish-haskell.nix`](./stylish-haskell.nix)   | Builds the `stylish-haskell` wrapper, likewise.                             |
| [`flake.nix`](./flake.nix)                       | Exposes the `fourmolu` (and `default`) and `stylish-haskell` packages for every supported system. |
| [`inputs.nix`](./inputs.nix)                     | `flake-compat` shim so non-flake Nix can consume the inputs.                |

## About Obsidian Systems

style.hs is built and maintained by **[Obsidian Systems](https://obsidian.systems)**. We
provide frontier engineering for high-assurance systems, and we're long-time stewards of
open-source Nix, Haskell, and daml tooling, including [Obelisk](https://github.com/obsidiansystems/obelisk),
[Reflex](https://reflex-frp.org/), [nix-daml-sdk](https://github.com/obsidiansystems/nix-daml-sdk), and [nix-thunk](https://github.com/obsidiansystems/nix-thunk).

If you're building with Haskell or Nix and want a partner to help design, build, or ship
it, we'd love to hear from you.

- Website — <https://obsidian.systems>
- Blog — <https://blog.obsidian.systems>
- GitHub — <https://github.com/obsidiansystems>

## License

style.hs is released under the [BSD-3-Clause License](./LICENSE), © 2026 Obsidian Systems
LLC. fourmolu and the other tools it wraps are distributed under their own upstream
licenses.
