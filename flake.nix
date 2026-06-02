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
        version = "4.5.10";
        srcOverride = pkgs.fetchFromGitHub {
          owner = "glitch-soc";
          repo  = "mastodon";
          rev   = "v4.5.10";
          hash  = "sha256-D0mPXLCP0nDgJKI/fxuPCX91/vIgutr23wXuDCLrEaI=";
        };
        gemset = ./gemset.nix;
        yarnHash = "sha256-lFQWGPd3ojlZzCWYrtnpSYKCGZ5trxH5vvFUh1/YJ2M=";
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