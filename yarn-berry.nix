# glitch-soc 4.7.0 pins yarn 4.18.0 and points the `typescript` dependency at
# the TypeScript 6 and 7 packages. nixpkgs still ships yarn-berry 4.14.1, whose
# builtin compat patch for typescript ends in an open-ended `>=5.7.1-rc` version
# gate, so it tries to patch TypeScript 7 as well and dies on the lib/_tsc.js
# that no longer exists there. 4.18.0 caps that gate at `<7.0.0-0`.
#
# makeOverridable keeps the bump in place through the `.override { nodejs = ... }`
# that the mastodon derivation does, which would otherwise re-run the original
# nixpkgs expression and drop it. Both flake.nix and update.sh use this file, so
# the offline cache and the hash computed for it always come from the same yarn.
{ pkgs }:

pkgs.lib.makeOverridable (
  args:
  (pkgs.yarn-berry_4.override args).overrideAttrs {
    version = "4.18.0";
    src = pkgs.fetchFromGitHub {
      owner = "yarnpkg";
      repo = "berry";
      tag = "@yarnpkg/cli/4.18.0";
      hash = "sha256-pO89wh17cW9/RGKjo70yiefr+9nlJAQs4ZEdUnzdgQM=";
    };
  }
) { }
