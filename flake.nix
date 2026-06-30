{
  description = "glitch-soc Mastodon fork packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.mastodon.override {
      pname   = "glitch-soc";
      version = "4.6.2";

      srcOverride = pkgs.fetchFromGitHub {
        owner = "glitch-soc";
        repo  = "mastodon";
        rev   = "v4.6.2";
        hash  = "sha256-ze8qrYwQhmj1cMEsSiytZOF8lhyJ425buU20Jwh5Tl4=";
      };

      gemset = ./gemset.nix;
      yarnHash = "sha256-dAzr/REG0mxGtj6R9arZCpbXAWYh08f6H7vEuv8tuVc=";
      yarnMissingHashes = ./yarn-missing-hashes.json;
    };
  };
}