{
  description = "glitch-soc Mastodon fork packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # The packaged glitch-soc release. Bump this and run `make refresh` to
    # regenerate gemset.nix, yarn-missing-hashes.json and both hashes below.
    version = "4.7.1";
  in {
    packages.${system}.default = pkgs.mastodon.override {
      pname = "glitch-soc";
      inherit version;

      srcOverride = pkgs.fetchFromGitHub {
        owner = "glitch-soc";
        repo  = "mastodon";
        rev   = "v${version}";
        hash  = "sha256-jv7GwYhVU+WuHlgQ/Ot77ciNCz6VG6+uCwhEg7IgsPw=";
      };

      gemset = ./gemset.nix;
      yarnHash = "sha256-Wo5a8ESc0VTVMpWU12APvDLd4qG592rsA+m1HdjmGqI=";
      yarnMissingHashes = ./yarn-missing-hashes.json;

      # nixpkgs' yarn is too old for this release; see yarn-berry.nix.
      yarn-berry_4 = import ./yarn-berry.nix { inherit pkgs; };
    };
  };
}
