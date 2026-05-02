{
  description = "glitch-soc Mastodon fork packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.callPackage
      (pkgs.path + "/pkgs/servers/mastodon")
      {
        pname   = "glitch-soc";
        version = "4.5.9";
        srcOverride = pkgs.fetchFromGitHub {
          owner = "glitch-soc";
          repo  = "mastodon";
          rev   = "v4.5.9";
          hash  = "sha256-/ecgcT9g/i2mCaYZRv+C1nF1bFNDz6fSmkIU9qldOxI=";
        };
        gemset = ./gemset.nix;
        yarnHash = "sha256-k/byerDphE9ZII5Y0v30MXiDGZlqk+rnD/+bDqKraVY=";
        yarnMissingHashes = ./yarn-missing-hashes.json;
        ruby = pkgs.ruby.override {
          defaultGemConfig = pkgs.defaultGemConfig // {
            hiredis-client = attrs: {
              buildInputs = [ pkgs.openssl pkgs.hiredis ];
            };
          };
        };
      };
  };
}