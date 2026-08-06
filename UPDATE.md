# Updating glitch-soc

The packaged release is the `version` string in `flake.nix`. Everything else —
`gemset.nix`, `yarn-missing-hashes.json`, the source hash and the yarn hash —
is generated from it by `./update.sh`, which the `Makefile` wraps.

## Automatically

`.woodpecker/update.yaml` runs on a cron trigger, follows the newest upstream
tag, builds the package for real and opens a pull request. The one-time setup —
a `forgejo_token` secret and the cron entry — is described in the pipeline
header. Pods bring their own nix, so the store is cold on every run;
[ci/nix-store.yaml](ci/nix-store.yaml) describes the faster variant that
borrows the node's store instead.

## By bumping the version

Change one line in `flake.nix`:

```nix
version = "4.6.4";
```

Then either push the branch — CI regenerates the sources and hashes, builds,
and commits the result back onto the same branch — or do it locally:

```bash
make refresh
```

## Following the latest tag locally

```bash
make update              # newest upstream tag
make update TAG=v4.6.4   # a specific tag
```

Both leave the working tree ready to commit:

```bash
make build               # verify (needs a builder for x86_64-linux)
git add flake.nix gemset.nix yarn-missing-hashes.json
git commit -m "update to glitch-soc v4.6.4"
```

`make help` lists the remaining targets (`current`, `latest`, `outdated`,
`check`, `clean`).

## What the script does

1. Resolves the target tag and shallow-clones it into `glitch-soc-src/`
   (removed afterwards, never committed).
2. `bundix -l` in that checkout regenerates `gemset.nix`.
3. `yarn-berry-fetcher missing-hashes` regenerates `yarn-missing-hashes.json`.
4. Prefetches the source tarball for the `hash` in `flake.nix`.
5. Builds the yarn offline cache as a fixed-output derivation with
   `lib.fakeHash` and takes the reported hash as `yarnHash`.

Steps 4 and 5 use the host's own system, not the `x86_64-linux` the flake
targets: both hashes are content addressed and platform independent, so the
update works on darwin too. Only `make build` needs a real Linux builder.
