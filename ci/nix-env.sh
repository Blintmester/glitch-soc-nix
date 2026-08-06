# Prepares a pipeline container to run `make`. Source it, do not execute it:
# it exports PATH.
#
#   . ci/nix-env.sh
#
# Works in both shapes this repo's CI can take:
#
#   * an image that ships its own nix (nixos/nix) — the default
#   * a bare image with the node's /nix mounted in, borrowing the host store
#     and daemon (faster, but needs a trusted repo and a bound PVC)

if ! command -v nix >/dev/null 2>&1; then
  if [ ! -d /nix/store ]; then
    echo "no nix in this container and no /nix mounted into it." >&2
    echo "use an image that ships nix (nixos/nix), or mount the node's /nix." >&2
    exit 1
  fi
  for candidate in \
    /nix/var/nix/profiles/default/bin/nix \
    /nix/var/nix/profiles/system/sw/bin/nix \
    /nix/var/nix/profiles/per-user/root/profile/bin/nix
  do
    if [ -x "$candidate" ]; then
      PATH="$(dirname "$candidate"):$PATH"
      break
    fi
  done
  if ! command -v nix >/dev/null 2>&1; then
    candidate="$(ls -d /nix/store/*-nix-[0-9]*/bin/nix 2>/dev/null | tail -1)"
    [ -n "$candidate" ] && PATH="$(dirname "$candidate"):$PATH"
  fi
  export PATH
fi

command -v nix >/dev/null 2>&1 || {
  echo "/nix is present but holds no usable nix binary." >&2
  ls -l /nix/var/nix/profiles/ >&2 || true
  exit 1
}

export NIX_CONFIG="experimental-features = nix-command flakes
sandbox = false
${NIX_CONFIG:-}"

# Talk to the host daemon when its socket was mounted along with the store;
# otherwise this container owns its store and writes to it directly as root.
if [ -S /nix/var/nix/daemon-socket/socket ]; then
  export NIX_REMOTE=daemon
else
  unset NIX_REMOTE
fi

# The nix images are deliberately bare: bring in what the Makefile calls, one
# by one so an already present tool never turns into a profile conflict.
for tool in make git curl sed awk grep; do
  command -v "$tool" >/dev/null 2>&1 && continue
  case "$tool" in
    make) attr=gnumake ;;
    sed)  attr=gnused ;;
    awk)  attr=gawk ;;
    grep) attr=gnugrep ;;
    *)    attr="$tool" ;;
  esac
  echo "installing $tool"
  nix profile install --priority 4 "nixpkgs#$attr" >/dev/null || {
    echo "failed to install $tool from nixpkgs#$attr" >&2
    exit 1
  }
  PATH="$HOME/.nix-profile/bin:$PATH"
  export PATH
done

echo "nix: $(command -v nix) ($(nix --version)), store=${NIX_REMOTE:-local}"
