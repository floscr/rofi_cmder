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
          frece = pkgs.callPackage ./packages/frece.nix { };

          rofi_cmder_2 =
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
                packages.frece
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
                    rev = "master";
                    sha256 = "+w9OPgKA1HzFLAiMeD64xlIxqyC6hz5mEaPHYVhSm1I=";
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
                    ./src/rofi_blocks.nim
              '';
              installPhase = with pkgs; ''
                mkdir -p $out/bin $out/lib

                install -Dt $out/lib $TMPDIR/${name}

                echo "#! ${stdenv.shell}" >> "$out/bin/${name}"
                echo "${rofiWithBlocks}/bin/rofi -modi blocks -show blocks -blocks-wrap $out/lib/${name} \"@\"" >> "$out/bin/${name}"
                chmod +x "$out/bin/${name}"
              '';
            };

          default = pkgs.stdenv.mkDerivation {
            name = name;
            src = ./.;

            nativeBuildInputs = with pkgs; [
              nim
              pkgconfig
              packages.frece
            ];

            buildInputs = buildInputs;

            buildPhase = with pkgs; ''
              HOME=$TMPDIR
              # Pass paths of needed buildInputs
              # and nim packages fetched from nix
              nim compile \
                  -d:release \
                  --verbosity:0 \
                  --hint[Processing]:off \
                  --excessiveStackTrace:on \
                  -p:${nimpkgs.cligen}/src \
                  -p:${nimpkgs.nimboost}/src \
                  -p:${nimpkgs.classy}/src \
                  -p:${nimpkgs.nimfp}/src \
                  -p:${nimpkgs.unicodedb}/src \
                  -p:${nimpkgs.regex}/src \
                  -p:${nimpkgs.redux}/src \
                  --out:$TMPDIR/${name} \
                  ./src/${name}.nim
            '';
            installPhase = ''
              install -Dt \
              $out/bin \
              $TMPDIR/${name}
            '';
          };

        };

        apps.rofi_cmder_2 = flake-utils.lib.mkApp { drv = packages.rofi_cmder_2; };

        devShell = import ./shell.nix {
          inherit pkgs;
          inherit nimpkgs;
          inherit buildInputs;
          inherit packages;
        };

        defaultApp = {
          program = "${packages.default}/bin/${name}";
          type = "app";
        };

        defaultPackage = packages.default;
      });
}
