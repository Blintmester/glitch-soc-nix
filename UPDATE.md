# Updating glitch-soc

Follow these steps when a new glitch-soc version is released.

## Steps

### 1. Check out the new version

```bash
git clone --depth 1 https://github.com/glitch-soc/mastodon glitch-soc-src
cd glitch-soc-src
git fetch --depth 1 origin <tag>   # e.g. v4.5.9
git checkout <tag>
cd ..
```

### 2. Regenerate gemset.nix

```bash
cd glitch-soc-src
nix run nixpkgs#bundix -- -l
cp gemset.nix ../
cd ..
```

### 3. Regenerate yarn-missing-hashes.json

```bash
nix run nixpkgs#yarn-berry_4.yarn-berry-fetcher -- missing-hashes glitch-soc-src/yarn.lock > yarn-missing-hashes.json
```

### 4. Update flake.nix

Set the new `rev` and reset both hashes to `pkgs.lib.fakeHash`:

```nix
srcOverride = pkgs.fetchFromGitHub {
  owner = "glitch-soc";
  repo  = "mastodon";
  rev   = "<new-tag>";
  hash  = pkgs.lib.fakeHash;  # reset this
};
yarnHash = pkgs.lib.fakeHash;  # reset this
```

### 5. Bootstrap the source hash

```bash
nix build 2>&1 | grep "got:"
# Paste the reported hash into flake.nix as `hash`
```

### 6. Bootstrap the yarn hash

```bash
nix build 2>&1 | grep "got:"
# Paste the reported hash into flake.nix as `yarnHash`
```

### 7. Final build and commit

```bash
nix build
git add flake.nix flake.lock gemset.nix yarn-missing-hashes.json
git commit -m "glitch-soc <version>"
```

> The `glitch-soc-src/` directory is only needed for steps 1-3 and should not be committed.