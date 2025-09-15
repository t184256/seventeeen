{
  description = "A split ortho 102x102 keyboard with 17mm spacing & XIAO Seeed";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    ergogen.url = "github:t184256/ergogen-nix";
    ergogen.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, ergogen, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system;
          overlays = [ ergogen.overlays.default ];
        };
        ergogen-footprints = pkgs.stdenvNoCC.mkDerivation {
          name = "ergogen-footprints";
          version = "2025-02-19";
          src = pkgs.fetchFromGitHub {
            owner = "ceoloide";
            repo = "ergogen-footprints";
            rev = "87654b4654b134e4ce3f1f9887e90a5d917d53a3";
            hash = "sha256-pwcj1DQDdTMpZqEhcdDYZBNS8X6sLwKpxzKlmgvkBO8=";
          };
          phases = [ "unpackPhase" "patchPhase" "installPhase" ];
          patches = [
            ./footprints/choc.patch
            ./footprints/diode.patch
            ./footprints/mounting_hole_plated.patch
            ./footprints/seeed_xiao.patch
          ];
          installPhase = "cp -r . $out";
        };

        ergogen-select-footprints = pkgs.stdenvNoCC.mkDerivation {
          name = "ergogen-select-footprints";
          inherit (ergogen-footprints) version;
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out
            cp -v \
              ${ergogen-footprints}/backlog/virginia2244/seeed_xiao.js \
              ${ergogen-footprints}/battery_connector_jst_ph_2.js \
              ${ergogen-footprints}/diode_tht_sod123.js \
              ${ergogen-footprints}/mounting_hole_npth.js \
              ${ergogen-footprints}/mounting_hole_plated.js \
              ${ergogen-footprints}/power_switch_smd_side.js \
              ${ergogen-footprints}/switch_choc_v1_v2.js \
              ${ergogen-footprints}/utility_filled_zone.js \
              ${ergogen-footprints}/utility_router.js \
              ${ergogen-footprints}/utility_text.js \
              $out/
          '';
        };

        seventeeen = pkgs.stdenvNoCC.mkDerivation {
          pname = "seventeeen";
          version = "0.1";
          src = ./.;
          makeFlags = [
            "ERGOGEN_FOOTPRINTS=${ergogen-select-footprints}"
            "ERGOGEN=${pkgs.ergogen}/bin/ergogen"
            "KICAD_CLI=${pkgs.kicad}/bin/kicad-cli"
            "DIFF=${pkgs.diffutils}/bin/diff"
            "SED=${pkgs.gnused}/bin/sed"
            "P7ZIP=${pkgs.p7zip}/bin/7z"
            "STRIP_NONDETERMINISM=${pkgs.strip-nondeterminism}/bin/strip-nondeterminism"
            "TMPDIR=tmp"
            "DESTDIR=${placeholder "out"}"
          ];
          enableParallelBuilding = true;
        };

      in
      {
        packages = { inherit seventeeen; };
        packages.default = seventeeen;

        devShells.default = pkgs.mkShell {
          buildInputs = [];
          nativeBuildInputs = with pkgs; [ gnumake kicad pkgs.ergogen ];
          shellHook = ''
            export ERGOGEN_FOOTPRINTS=${ergogen-select-footprints}
            export ERGOGEN=${pkgs.ergogen}/bin/ergogen
            export KICAD=${pkgs.kicad}/bin/kicad
            export KICAD_CLI=${pkgs.kicad}/bin/kicad-cli
            export P7ZIP=${pkgs.p7zip}/bin/7z
            export STRIP_NONDETERMINISM=${pkgs.strip-nondeterminism}/bin/strip-nondeterminism
          '';
        };
      }
    );
}
