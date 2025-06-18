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
        ${ergogen-footprints}/backlog/virginia2244/seeed_xiao.js \
        ${ergogen-footprints}/battery_connector_jst_ph_2.js \
        ${ergogen-footprints}/mounting_hole_npth.js \
        ${ergogen-footprints}/power_switch_smd_side.js \
        ${ergogen-footprints}/switch_choc_v1_v2.js \
        ${ergogen-footprints}/utility_filled_zone.js \
        ${ergogen-footprints}/utility_text.js \
        $out/
    '';
  };

in

stdenvNoCC.mkDerivation {
  pname = "seventeeen";
  version = "0.1";

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
