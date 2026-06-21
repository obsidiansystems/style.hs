# style.hs

Obsidian Systems' shared Haskell code style, packaged as a [Nix](https://nixos.org/)
flake that wraps [`fourmolu`](https://github.com/fourmolu/fourmolu) with a common
[`fourmolu.yaml`](./fourmolu.yaml).

Point any of our Haskell projects at this flake and they all format the same way,
without each repo having to vendor and maintain its own copy of the config.

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

### Use `fourmolu.yaml` as an executable

[`fourmolu.yaml`](./fourmolu.yaml) is both the config *and* a runnable
[Nix shebang](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-shell#shebang)
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

| File | Purpose |
| --- | --- |
| [`fourmolu.yaml`](./fourmolu.yaml) | The shared style config; also a runnable Nix shebang script. |
| [`fourmolu.nix`](./fourmolu.nix) | Builds the `fourmolu` wrapper that bundles the config and handles `--config`. |
| [`flake.nix`](./flake.nix) | Exposes the `fourmolu` (and `default`) package for every supported system. |
| [`inputs.nix`](./inputs.nix) | `flake-compat` shim so non-flake Nix can consume the inputs. |
