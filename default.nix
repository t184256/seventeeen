{ lib, stdenvNoCC, ergogen, kicad, fetchFromGitHub }:

let
  ergogen-footprints = stdenvNoCC.mkDerivation {
    name = "ergogen-footprints";
    version = "2025-02-19";
    src = fetchFromGitHub {
      owner = "ceoloide";
      repo = "ergogen-footprints";
      rev = "87654b4654b134e4ce3f1f9887e90a5d917d53a3";
      hash = "sha256-pwcj1DQDdTMpZqEhcdDYZBNS8X6sLwKpxzKlmgvkBO8=";
    };
    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
    patches = [
      ./footprints/seeed_xiao.patch
    ];
    installPhase = "cp -r . $out";
  };

  ergogen-select-footprints = stdenvNoCC.mkDerivation {
    name = "ergogen-select-footprints";
    inherit (ergogen-footprints) version;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp -v \
        ${ergogen-footprints}/reset_switch_tht_top.js \
        ${ergogen-footprints}/switch_choc_v1_v2.js \
        ${ergogen-footprints}/trrs_pj320a.js \
        ${ergogen-footprints}/utility_ergogen_logo.js \
        ${ergogen-footprints}/utility_text.js \
        ${ergogen-footprints}/backlog/virginia2244/seeed_xiao.js \
        $out/
    '';
  };

in

stdenvNoCC.mkDerivation {
  pname = "seventeeen";
  version = "0.0.0";

  src = ./.;

  buildPhase = ''
    mkdir -p ergogen/footprints
    cp -rv ${ergogen-select-footprints} ergogen/footprints/ceoloide
    ${ergogen}/bin/ergogen ergogen/ -o $out
    mkdir $out/previews tmp
    find $out
    HOME=$(realpath tmp) \
      ${kicad}/bin/kicad-cli pcb export svg \
        --output $out/previews/seventeeen.svg \
        $out/pcbs/seventeeen.kicad_pcb \
        --exclude-drawing-sheet \
        --fit-page-to-board \
        -l F.Cu,B.Cu,F.Paste,B.Paste,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts
  '';

  meta = {
    description = "Ergonomic keyboard layout generator";
    homepage = "https://ergogen.xyz";
    license = lib.licenses.mit;
  };
}
