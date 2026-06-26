# style.hs

### Obsidian-style Haskell

one shared `fourmolu.yaml` · `nix run` anywhere · consistent formatting across projects

![Haskell](https://img.shields.io/badge/Haskell-5e5086?logo=haskell&logoColor=white) [![Built with Nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://nixos.org) [![Obsidian](https://img.shields.io/badge/Obsidian-Systems-white)](https://obsidian.systems)

```console
$ nix run github:obsidiansystems/style.hs -- --mode inplace src/   # format your Haskell, Obsidian-style
$ nix run github:obsidiansystems/style.hs -- --mode check   src/   # or just check it, e.g. in CI
```

A [Nix](https://nixos.org/) flake that wraps [`fourmolu`](https://github.com/fourmolu/fourmolu)
with a common [`fourmolu.yaml`](./fourmolu.yaml). Point any of your Haskell projects at
this flake and they all format the same way, without each repo having to vendor and
maintain its own copy of the config. The config implements our [Haskell Style
Guide](./STYLE.md).

## Why style.hs?

- **One config, every repo.** Reference the flake and your projects format identically.
- **Drop in however you like.** Run it directly with `nix run`, add it to a dev shell so
  plain `fourmolu` just works, vendor it as a git submodule, or run the config file
  itself as an executable.

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
no `--config` needed.

### Vendor it as a git submodule

Add this repo as a submodule and symlink your project's `fourmolu.yaml` to the
vendored one. fourmolu discovers `fourmolu.yaml` from the project root
automatically, so editors, formatters, and CI all pick up the style with no
flags:

```sh
git submodule add https://github.com/obsidiansystems/style.hs style.hs
ln -s style.hs/fourmolu.yaml fourmolu.yaml
```

Pull in later changes to the shared style by updating the submodule:

```sh
git submodule update --remote style.hs
```

### Use `fourmolu.yaml` as an executable

[`fourmolu.yaml`](./fourmolu.yaml) is both the config *and* a runnable
[Nix shebang](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix.html?highlight=shebang#shebang-interpreter)
script. Copy it into a project and run it directly to format files using itself as
the config:

```sh
./fourmolu.yaml --mode inplace src/
```

This needs `nix` on `PATH` with flakes enabled.

## Choosing a config

The wrapper resolves which config to use as follows:

- **No `--config`**: the bundled `fourmolu.yaml` (the default).
- **`--config <path>`** / **`--config=<path>`**: your own config file. Repeated
  `--config` flags collapse to the last one, since fourmolu itself rejects
  duplicates.
- **`--config -`**: read the config from stdin.

## What's in the repo

| File                               | Purpose                                                                                        |
| ---                                | ---                                                                                            |
| [`STYLE.md`](./STYLE.md)           | The Obsidian Haskell Style Guide: the reasoning behind the rules.                              |
| [`fourmolu.yaml`](./fourmolu.yaml) | The shared style config: also a runnable Nix shebang script.                                                                |
| [`fourmolu.nix`](./fourmolu.nix)   | Builds `fourmolu` wrapper that bundles the config and handles `--config`.                                                  |
| [`flake.nix`](./flake.nix)         | Exposes the `fourmolu` (and `default`) package for every supported system.                     |
| [`inputs.nix`](./inputs.nix)       | `flake-compat` shim so non-flake Nix can consume the inputs.                                   |

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
