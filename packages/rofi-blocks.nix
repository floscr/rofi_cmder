{ lib, pkgs, fetchFromGitHub, rofi-unwrapped, pkg-config, autoreconfHook, json-glib, cairo }:

pkgs.stdenv.mkDerivation rec {
  pname = "rofi-blocks";
  version = "2020-07-09";

  src = fetchFromGitHub {
    owner = "OmarCastro";
    repo = pname;
    rev = "c84577749f71f6c0836fc7ca7ec0097d2fe66492";
    sha256 = "3Jf88YsZiaVSPuzVp7+pbEfrKQ69CRWEsCNzf4Mh7+w=";
  };

  nativeBuildInputs = [ pkg-config autoreconfHook json-glib cairo ];

  buildInputs = [ rofi-unwrapped ];

  enableParallelBuilding = true;

  patches = [
    ./0001-Patch-plugindir-to-output.patch
    ./0002-Patch-return-index.patch
  ];

  meta = with lib; {
    description = "Rofi modi that allows controlling rofi content throug communication with an external program.";
    homepage = "https://github.com/OmarCastro/rofi-blocks";
    license = licenses.gpl3;
    maintainers = with maintainers; [ oro ];
  };
}
