{
  description = "A split ortho 100x100 keyboard with 17mm spacing & XIAO Seeed";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    ergogen.url = "github:t184256/ergogen-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ergogen, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system;
          overlays = [ ergogen.overlays.default ];
        };
        seventeeen = pkgs.callPackage ./default.nix { };
      in
      {
        packages = { inherit seventeeen; };
        defaultPackage = seventeeen;
      });
}
