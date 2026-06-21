{ inputs ? (import ./inputs.nix)
, system ? builtins.currentSystem
, pkgs ? (import inputs.nixpkgs { inherit system; })
}:

pkgs.writeShellScriptBin "fourmolu" ''
  baseConfig=${./fourmolu.yaml}

  # Forward all arguments to fourmolu, but intercept `--config -`: when it is
  # given, the config read from stdin is appended to our base config and the
  # combined result is passed to fourmolu instead.
  args=()
  useStdinConfig=
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--config" ] && [ "$2" = "-" ]; then
      useStdinConfig=1
      shift 2
    else
      args+=("$1")
      shift
    fi
  done

  if [ -n "$useStdinConfig" ]; then
    config=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$config"' EXIT
    ${pkgs.coreutils}/bin/cat "$baseConfig" - > "$config"
    ${pkgs.lib.getExe pkgs.fourmolu} --config "$config" "''${args[@]}"
  else
    exec ${pkgs.lib.getExe pkgs.fourmolu} --config "$baseConfig" "''${args[@]}"
  fi
''
