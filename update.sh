#!/usr/bin/env bash
# Regenerate everything that is tied to a glitch-soc release: gemset.nix,
# yarn-missing-hashes.json and the two hashes in flake.nix. The version itself
# lives in flake.nix and is the single knob.
#
# Usage (normally via the Makefile):
#   ./update.sh              # follow the latest upstream tag
#   ./update.sh v4.6.4       # pin a specific tag
#   ./update.sh --refresh    # keep the version already set in flake.nix
#   ./update.sh --build      # additionally build the package to verify
#
# Hash computation works on any system. --build needs a builder for the
# system the flake targets (x86_64-linux).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM="https://github.com/glitch-soc/mastodon"
SRC_DIR="$REPO_DIR/glitch-soc-src"
BUILD=0
REFRESH=0
TAG=""

for arg in "$@"; do
  case "$arg" in
    --build)   BUILD=1 ;;
    --refresh) REFRESH=1 ;;
    v*)        TAG="$arg" ;;
    "")        ;;
    *) echo "unknown argument: $arg" >&2; exit 1 ;;
  esac
done

cd "$REPO_DIR"

log() { printf '\n==> %s\n' "$*"; }

flake_version() { sed -n 's/^ *version = "\(.*\)";.*/\1/p' flake.nix | head -1; }

# ---------------------------------------------------------------- resolve tag

CURRENT="v$(flake_version)"

if [ "$REFRESH" = 1 ] && [ -z "$TAG" ]; then
  TAG="$CURRENT"
elif [ -z "$TAG" ]; then
  TAG=$(git ls-remote --tags --refs "$UPSTREAM" 'v*' \
        | awk '{print $2}' | sed 's|refs/tags/||' \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | sort -V | tail -1)
  [ -n "$TAG" ] || { echo "could not resolve the latest upstream tag" >&2; exit 1; }
  if [ "$CURRENT" = "$TAG" ]; then
    log "already on $CURRENT, nothing to do"
    exit 0
  fi
fi

REV=$(git ls-remote "$UPSTREAM" "refs/tags/$TAG" | cut -f1)
[ -n "$REV" ] || { echo "tag $TAG not found upstream" >&2; exit 1; }
VERSION="${TAG#v}"

log "packaged: $CURRENT   target: $TAG ($REV)"

# --------------------------------------------------------------- fetch source

log "fetching $TAG"
attempt=1
while : ; do
  rm -rf "$SRC_DIR"
  git clone --quiet --depth 1 --branch "$TAG" "$UPSTREAM" "$SRC_DIR" && break
  if [ "$attempt" -ge 3 ]; then
    echo "could not clone $UPSTREAM after $attempt attempts" >&2
    exit 1
  fi
  echo "clone failed, retrying ($attempt)" >&2
  attempt=$((attempt + 1))
  sleep 5
done

log "regenerating gemset.nix"
(cd "$SRC_DIR" && nix run nixpkgs#bundix -- -l >/dev/null)
cp "$SRC_DIR/gemset.nix" "$REPO_DIR/gemset.nix"

log "regenerating yarn-missing-hashes.json"
nix run nixpkgs#yarn-berry_4.yarn-berry-fetcher -- \
  missing-hashes "$SRC_DIR/yarn.lock" > "$REPO_DIR/yarn-missing-hashes.json"

# ---------------------------------------------------------------- source hash

log "computing source hash"
SRC_HASH=$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack --type sha256 "$UPSTREAM/archive/$REV.tar.gz" 2>/dev/null | tail -1)")

sed -i.bak \
  -e "s|^\( *\)version = \".*\";|\1version = \"$VERSION\";|" \
  -e "s|^\( *\)hash  = \".*\";|\1hash  = \"$SRC_HASH\";|" \
  flake.nix
rm -f flake.nix.bak

# ------------------------------------------------------------------ yarn hash
# Built as a fixed-output derivation against the nixpkgs the flake pins, but
# for the *host* system: the offline cache content is platform independent, so
# this also works on darwin, where the package itself cannot be built.

log "computing yarn hash"
NIXPKGS_REV=$(nix eval --raw --impure --expr \
  '(builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked.rev')

YARN_EXPR=$(mktemp -t yarnhash.XXXXXX.nix)
trap 'rm -f "$YARN_EXPR"' EXIT
cat > "$YARN_EXPR" <<EOF
let
  pkgs = (builtins.getFlake "github:nixos/nixpkgs/$NIXPKGS_REV").legacyPackages.\${builtins.currentSystem};
  src = pkgs.fetchFromGitHub {
    owner = "glitch-soc";
    repo = "mastodon";
    rev = "$TAG";
    hash = "$SRC_HASH";
  };
  yarn-berry = pkgs.yarn-berry_4.override { nodejs = pkgs.nodejs-slim; };
in yarn-berry.fetchYarnBerryDeps {
  inherit src;
  hash = pkgs.lib.fakeHash;
  missingHashes = $REPO_DIR/yarn-missing-hashes.json;
}
EOF

# The build is expected to fail: fakeHash makes nix report the real hash. Its
# output is teed rather than captured, so a run that is killed here (this step
# downloads the whole yarn cache) still shows where it got to.
YARN_LOG=$(mktemp -t yarnhash.XXXXXX.log)
trap 'rm -f "$YARN_EXPR" "$YARN_LOG"' EXIT
{ nix build --impure --no-link -f "$YARN_EXPR" 2>&1 || true; } | tee "$YARN_LOG"
YARN_HASH=$(sed -n 's|.*got: *\(sha256-[A-Za-z0-9+/=_-]*\).*|\1|p' "$YARN_LOG" | head -1)
if [ -z "$YARN_HASH" ]; then
  echo "failed to determine the yarn hash from the output above" >&2
  exit 1
fi

sed -i.bak "s|yarnHash = \".*\";|yarnHash = \"$YARN_HASH\";|" flake.nix
rm -f flake.nix.bak

rm -rf "$SRC_DIR"

log "flake.nix now describes $TAG"
echo "  src:  $SRC_HASH"
echo "  yarn: $YARN_HASH"

# --------------------------------------------------------------- verification

if [ "$BUILD" = 1 ]; then
  log "building the package"
  nix build --no-link .#packages.x86_64-linux.default
  echo "build ok"
fi
