# Makes the host's nix usable from a plain pipeline container. Source it, do
# not execute it: it exports PATH.
#
#   . ci/nix-env.sh
#
# The container ships no nix of its own; it borrows the store mounted from the
# node at /nix, so this only has to find the binary and pick the right store
# access mode.

if [ ! -d /nix/store ]; then
  echo "/nix is not mounted in this pod." >&2
  echo "  * is the repo marked trusted in Woodpecker? untrusted repos have" >&2
  echo "    their backend_options (and so the volume) silently dropped" >&2
  echo "  * does the PVC nix-store exist in the agent's namespace?" >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  for candidate in \
    /nix/var/nix/profiles/system/sw/bin/nix \
    /nix/var/nix/profiles/default/bin/nix \
    /nix/var/nix/profiles/per-user/root/profile/bin/nix
  do
    if [ -x "$candidate" ]; then
      PATH="$(dirname "$candidate"):$PATH"
      break
    fi
  done
fi

# Last resort: take the newest nix in the store directly.
if ! command -v nix >/dev/null 2>&1; then
  candidate="$(ls -d /nix/store/*-nix-[0-9]*/bin/nix 2>/dev/null | tail -1)"
  if [ -n "$candidate" ]; then
    PATH="$(dirname "$candidate"):$PATH"
  fi
fi

export PATH

if ! command -v nix >/dev/null 2>&1; then
  echo "/nix is mounted but no nix binary was found in it." >&2
  echo "checked the system, default and per-user profiles:" >&2
  ls -l /nix/var/nix/profiles/ >&2 || true
  exit 1
fi

# Prefer the host daemon; fall back to direct store access when its socket is
# not exposed (the container runs as root, so that still works).
if [ -S /nix/var/nix/daemon-socket/socket ]; then
  export NIX_REMOTE=daemon
else
  echo "note: no nix-daemon socket under /nix, using the store directly" >&2
  unset NIX_REMOTE
fi

export NIX_CONFIG="experimental-features = nix-command flakes
${NIX_CONFIG:-}"

echo "nix: $(command -v nix) ($(nix --version)), NIX_REMOTE=${NIX_REMOTE:-<direct>}"
