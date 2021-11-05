{ lib, pkgs }:

with pkgs;

rustPlatform.buildRustPackage rec {
  pname = "frece";
  version = "1.0.6";

  src = fetchFromGitHub {
    owner = "YodaEmbedding";
    repo = pname;
    rev = "41d11ec6512c9d8831535096436859222b4da085";
    sha256 = "sha256-CAiIqT5KuzrqbV9FVK3nZUe8MDs2KDdsKplJMI7rN9w=";
  };

  checkPhase = null;
  cargoSha256 = "sha256-eLN917L6l0vUWlAn3ROKrRdtyqaaMKjBQD2tEGWECUU=";

  meta = with lib; {
    description =
      "Maintain a database sorted by frecency (frequency + recency)";
    homepage = "https://github.com/YodaEmbedding/frece";
    license = licenses.mit;
    maintainers = with maintainers; [ "YodaEmbedding" ];
  };
}
