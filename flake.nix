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
    version = "4.6.4";
  in {
    packages.${system}.default = pkgs.mastodon.override {
      pname = "glitch-soc";
      inherit version;

      srcOverride = pkgs.fetchFromGitHub {
        owner = "glitch-soc";
        repo  = "mastodon";
        rev   = "v${version}";
        hash  = "sha256-Bs/HuoN0bM+rrW4W1JqKQXgEoB9DTe3S0ZUeckCnqAQ=";
      };

      gemset = ./gemset.nix;
      yarnHash = "sha256-+9AcWNxu+gJjNYR1PCRDg3Z6ByHYTIDo6ZcqaLRu9d4=";
      yarnMissingHashes = ./yarn-missing-hashes.json;
    };
  };
}
