# Managed by Home Manager — goenv
# goenv は nixpkgs に無く、goenv.nix の activation が ~/.goenv へ clone する。
# clone 前/失敗時でも壊れないよう存在ガードする。
export GOENV_ROOT="$HOME/.goenv"
if [ -d "$GOENV_ROOT/bin" ]; then
  path_prepend "$GOENV_ROOT/bin"
  if command -v goenv >/dev/null 2>&1; then
    eval "$(goenv init -)"
  fi
fi
