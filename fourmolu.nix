{ inputs ? (import ./inputs.nix)
, system ? builtins.currentSystem
, pkgs ? (import inputs.nixpkgs { inherit system; })
}:

pkgs.writeShellScriptBin "fourmolu" ''
  exec ${pkgs.lib.getExe pkgs.fourmolu} --config ${./fourmolu.yaml} "$@"
''
