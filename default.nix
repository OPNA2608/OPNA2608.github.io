{
  nixpkgs ? <nixpkgs>,
}:

let
  pkgs = import nixpkgs { };
  out = pkgs.callPackage ./package.nix { };
in
if builtins.pathExists ./date then
  out.overrideAttrs (oa: {
    passthru = oa.passthru // {
      date = pkgs.lib.strings.trim (builtins.readFile ./date);
    };
  })
else
  out
