{ pkgs, packages, nimpkgs, buildInputs }:

pkgs.mkShell {
  shellHook = ''
    export NIMBLE_DIR="$PWD/.nimble"
    export NIMBLE_BIN_DIR="$NIMBLE_DIR/bin"
    export PATH="$NIMBLE_BIN_DIR:$PATH"
    # Mutable install of inim
    [[ ! -f "$NIMBLE_BIN_DIR/inim" ]] && nimble --accept install inim
  '';
  buildInputs = with pkgs; buildInputs ++ [
    nim
    nimlsp
    bc
    translate-shell
    units
    (rofi.override {
      plugins = [
        packages.rofi-blocks
      ];
    })
  ];
}
