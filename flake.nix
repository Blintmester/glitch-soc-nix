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
      version = "4.5.11";

      srcOverride =
        let base = pkgs.fetchFromGitHub {
              owner = "glitch-soc";
              repo  = "mastodon";
              rev   = "v4.5.11";
              hash  = "sha256-Wv9LM+WEc5yjgypaUbwShloFydK8yopdixxl6DM2VIg=";
            };
        in pkgs.runCommand "glitch-soc-src-4.5.11" { } ''
          cp -r ${base} $out
          chmod -R u+w $out
          sed -i 's/^  version: 8$/  version: 9/' $out/yarn.lock
        '';

      gemset = ./gemset.nix;
      yarnHash = "sha256-1GghgBh2AO8ScL7rHQi+ZgoUvMBhJ+A+c6+1A9X/4dA=";
      yarnMissingHashes = ./yarn-missing-hashes.json;
    };
  };
}