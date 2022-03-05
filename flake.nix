{
  description = "rofi_cmder";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nimble.url = "github:floscr/flake-nimble";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, nimble, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        name = "rofi_cmder";
        pkgs = nixpkgs.legacyPackages.${system};
        nimpkgs = nimble.packages.${system};
        buildInputs = with pkgs; [
          units
        ];
      in
      rec {

        packages = flake-utils.lib.flattenTree {
          rofi-blocks = pkgs.callPackage ./packages/rofi-blocks.nix { };

          rofi_cmder =
            let
              name = "rofi_cmder";
              rofiWithBlocks =
                (pkgs.rofi.override {
                  plugins = [
                    packages.rofi-blocks
                  ];
                });
            in
            pkgs.stdenv.mkDerivation {
              name = name;
              src = ./.;

              nativeBuildInputs = with pkgs; [
                nim
                pkgconfig
                packages.rofi-blocks
              ];

              buildInputs = buildInputs;

              buildPhase = with pkgs; let
                fusion = pkgs.fetchFromGitHub
                  ({
                    owner = "nim-lang";
                    repo = "fusion";
                    rev = "v1.1";
                    sha256 = "9tn0NTXHhlpoefmlsSkoNZlCjGE8JB3eXtYcm/9Mr0I=";
                  });
                nimfp = pkgs.fetchFromGitHub
                  ({
                    owner = "floscr";
                    repo = "nimfp";
                    rev = "527d06ded4f95e0392c1035ad4816af22d2b7edd";
                    sha256 = "sha256-4EzwK8FPbDxeSjw0x8iYTgF6YJvOXZ69zPc19fkTX7s=";
                  });
              in
              ''
                HOME=$TMPDIR
                # Pass paths of needed buildInputs
                # and nim packages fetched from nix
                nim compile \
                    --threads \
                    -d:release \
                    --verbosity:0 \
                    --hint[Processing]:off \
                    --excessiveStackTrace:on \
                    -d:UNITS_BIN_PATH="${pkgs.units}/bin/units" \
                    -d:GOOGLER_BIN_PATH="${pkgs.googler}/bin/googler" \
                    -d:DDGR_BIN_PATH="${pkgs.ddgr}/bin/ddgr" \
                    -p:${fusion}/src \
                    -p:${nimfp}/src \
                    -p:${nimpkgs.cascade}/src \
                    -p:${nimpkgs.classy}/src \
                    -p:${nimpkgs.cligen}/src \
                    -p:${nimpkgs.nimboost}/src \
                    -p:${nimpkgs.print}/src \
                    -p:${nimpkgs.regex}/src \
                    -p:${nimpkgs.unicodedb}/src \
                    -p:${nimpkgs.unpack}/src \
                    -p:${nimpkgs.zero_functional}/src \
                    --out:$TMPDIR/${name} \
                    ./src/rofi_cmder.nim
              '';
              installPhase = with pkgs; ''
                mkdir -p $out/bin $out/lib

                install -Dt $out/lib $TMPDIR/${name}

                echo "#! ${stdenv.shell}" >> "$out/bin/${name}"
                echo "${rofiWithBlocks}/bin/rofi -modi blocks -show blocks -blocks-wrap $out/lib/${name} \"@\"" >> "$out/bin/${name}"
                chmod +x "$out/bin/${name}"
              '';
            };

        };

        apps.rofi_cmder = flake-utils.lib.mkApp { drv = packages.rofi_cmder; };

        devShell = import ./shell.nix {
          inherit pkgs;
          inherit nimpkgs;
          inherit buildInputs;
          inherit packages;
        };

        defaultApp = {
          program = "${packages.rofi_cmder}/bin/${name}";
          type = "app";
        };

        defaultPackage = packages.rofi_cmder;
      });
}
