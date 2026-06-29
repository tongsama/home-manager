# Managed by Home Manager — plenv
# plenv は nixpkgs に無く、plenv.nix の activation が ~/.plenv へ clone する。
# clone 前/失敗時でも壊れないよう存在ガードする。
export PLENV_ROOT="$HOME/.plenv"
if [ -d "$PLENV_ROOT/bin" ]; then
  path_prepend "$PLENV_ROOT/bin"
  if command -v plenv >/dev/null 2>&1; then
    eval "$(plenv init -)"
  fi
fi
