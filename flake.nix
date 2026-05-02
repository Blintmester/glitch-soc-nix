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
    packages.${system}.default = pkgs.mastodon.overrideAttrs (old: {
      pname   = "glitch-soc";
      version = "4.5.9";
      src = pkgs.fetchFromGitHub {
        owner = "glitch-soc";
        repo  = "mastodon";
        rev   = "869ac32b035f7dcd8f141659a840d1d1a9f48e9d";
        hash  = "sha256-/ecgcT9g/i2mCaYZRv+C1nF1bFNDz6fSmkIU9qldOxI=";
      };
    });
  };
}
