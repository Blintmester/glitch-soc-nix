# 1. Check out the new version

```shell
git clone --depth 1 https://github.com/glitch-soc/mastodon glitch-soc-src
cd glitch-soc-src && git fetch --depth 1 origin <tag> && git checkout <tag> && cd ..
```

# 2. Regenerate gemset.nix

```shell
cd glitch-soc-src && nix run nixpkgs#bundix -- -l && cp gemset.nix .. && cd ..
```

# 3. Regenerate yarn-missing-hashes.json

```shell
nix run nixpkgs#yarn-berry_4.yarn-berry-fetcher -- missing-hashes glitch-soc-src/yarn.lock > yarn-missing-hashes.json
```

# 4. Update flake.nix: set rev = "<tag>", hash = lib.fakeHash, yarnHash = lib.fakeHash
# Then bootstrap the hashes one by one:

```shell
nix build 2>&1 | grep "got:"   # replace source hash in flake.nix
nix build 2>&1 | grep "got:"   # replace yarnHash in flake.nix
```

# 5. Final build and commit

```shell
nix build
git add flake.nix flake.lock gemset.nix yarn-missing-hashes.json
git commit -m "glitch-soc <version>"
```