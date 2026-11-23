# glitch-soc-nix

A Nix flake packaging [glitch-soc](https://glitch-soc.github.io/docs/), a friendly fork of Mastodon, for NixOS.

## Usage

Add this flake as an input in your NixOS `flake.nix`:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
  glitch-soc = {
    url = "git+https://git.walros.dev/tutter/glitch-soc-nix.git";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Then pass `inputs` through `specialArgs` and use the package in your mastodon config:

```nix
{ inputs, pkgs, ... }:
{
  services.mastodon = {
    enable  = true;
    package = inputs.glitch-soc.packages.${pkgs.system}.default;
    # ... rest of your mastodon configuration
  };
}
```

## Configuration

glitch-soc exposes additional instance settings via environment variables in `extraConfig`:

```nix
services.mastodon.extraConfig = {
  MAX_TOOT_CHARS        = "5000";  # default: 500
  MAX_BIO_CHARS         = "5000";  # default: 500
  MAX_POLL_OPTIONS      = "12";    # default: 5
  MAX_POLL_OPTION_CHARS = "200";   # default: 100
};
```

## Updating

```bash
make update    # follow the latest upstream tag
make refresh   # regenerate for the version currently set in flake.nix
make build     # verify the package builds
```

A Woodpecker pipeline (`.woodpecker/update.yaml`) does the same on a cron
trigger and opens a pull request. See [UPDATE.md](UPDATE.md).