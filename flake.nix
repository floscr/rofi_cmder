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
        ];
      in
      rec {
        packages.frece = pkgs.callPackage ./packages/frece.nix { };
        packages.default = pkgs.stdenv.mkDerivation {
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
                --out:$TMPDIR/${name} \
                ./src/${name}.nim
          '';
          installPhase = ''
            install -Dt \
            $out/bin \
            $TMPDIR/${name}
          '';
        };

        devShell = import ./shell.nix {
          inherit pkgs;
          inherit nimpkgs;
          inherit buildInputs;
        };

        defaultApp = {
          program = "${packages.default}/bin/${name}";
          type = "app";
        };

        defaultPackage = packages.default;

      });
}
